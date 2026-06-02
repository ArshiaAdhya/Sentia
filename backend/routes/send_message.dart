import 'dart:convert';
import 'dart:io';
import 'package:backend/env/envied.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

import 'package:backend/services/ai/ai_service.dart';
import 'package:backend/services/journal/journal_service.dart';
import 'package:backend/services/pii_sanitizer.dart'; // Ensure this is imported
import 'package:backend/services/seeds/seed_service.dart';
import 'package:backend/services/streak/streak_service.dart';

const _rewardMarkerPrefix = '[[reward_marker]]';

String _detectEmotion(String text) {
  final input = text.toLowerCase();

  const happyKeywords = [
    'happy',
    'joy',
    'grateful',
    'excited',
    'great',
    'good',
    'better',
    'relieved',
  ];

  const sadKeywords = [
    'sad',
    'down',
    'lonely',
    'hurt',
    'cry',
    'upset',
    'tired',
    'hopeless',
  ];

  const anxiousKeywords = [
    'stress',
    'stressed',
    'anxious',
    'anxiety',
    'overwhelmed',
    'panic',
    'worried',
    'pressure',
    'angry',
    'mad',
    'furious',
    'annoyed',
    'frustrated',
    'irritated',
  ];

  const reflectiveKeywords = [
    'reflect',
    'thinking',
    'thought',
    'wonder',
    'realized',
    'confused',
    'unsure',
    'maybe',
  ];

  bool containsAny(List<String> words) => words.any(input.contains);

  if (containsAny(anxiousKeywords)) return 'anxious';
  if (containsAny(sadKeywords)) return 'sad';
  if (containsAny(happyKeywords)) return 'happy';
  if (containsAny(reflectiveKeywords)) return 'reflective';
  return 'neutral';
}

bool _containsAny(String input, List<String> phrases) {
  return phrases.any(input.contains);
}

bool _isRewardMarkerMessage(Map<String, dynamic> message) {
  final content = message['content']?.toString() ?? '';
  return content.startsWith(_rewardMarkerPrefix);
}

bool _isVisibleChatMessage(Map<String, dynamic> message) {
  final role = message['role']?.toString();
  return (role == 'user' || role == 'assistant') &&
      !_isRewardMarkerMessage(message);
}

int _userTurnsSinceLastReward(List<Map<String, dynamic>> previousMessages) {
  final lastRewardIndex =
      previousMessages.lastIndexWhere(_isRewardMarkerMessage);
  final messagesSinceReward = lastRewardIndex == -1
      ? previousMessages
      : previousMessages.sublist(lastRewardIndex + 1);

  return messagesSinceReward
      .where((message) => message['role'] == 'user')
      .length;
}

Future<void> _insertRewardMarker(
  SupabaseClient supabase,
  String sessionId, {
  required String mood,
  required int earnedSeeds,
}) async {
  await supabase.from('chat_messages').insert({
    'session_id': sessionId,
    'role': 'assistant',
    'content': '$_rewardMarkerPrefix mood=$mood earned=$earnedSeeds',
    'created_at': DateTime.now().toUtc().toIso8601String(),
  });
}

bool _isConversationConclusion({
  required List<Map<String, dynamic>> previousMessages,
  required String userMessage,
  required String aiReply,
  required String emotion,
}) {
  final priorUserTurns = previousMessages.where((message) {
    return message['role'] == 'user';
  }).length;
  final userTurns = priorUserTurns + 1;
  final combinedUserText = [
    ...previousMessages
        .where((message) => message['role'] == 'user')
        .map((message) => message['content']?.toString() ?? ''),
    userMessage,
  ].join(' ');
  final wordCount = combinedUserText
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;

  final meaningful = userTurns >= 2 && (wordCount >= 8 || emotion != 'neutral');
  if (!meaningful) return false;

  final userLower = userMessage.toLowerCase();
  final aiLower = aiReply.toLowerCase();
  final explicitClosing = _containsAny(userLower, const [
    'bye',
    'goodbye',
    'thanks',
    'thank you',
    'that helps',
    'that is all',
    "that's all",
    'done',
    'good night',
    'talk later',
  ]);
  final supportiveWrapUp = _containsAny(aiLower, const [
    'take care',
    'one small step',
    'whenever you want to talk',
    'whenever you need',
    'i am here',
    "i'm here",
  ]);

  return explicitClosing || supportiveWrapUp || userTurns >= 3;
}

String _trimForSummary(String text, {int maxLength = 140}) {
  final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.length <= maxLength) return cleaned;
  return '${cleaned.substring(0, maxLength - 3)}...';
}

String _focusForMood(String mood) {
  switch (mood) {
    case 'happy':
      return 'noticing positive moments and reinforcing what went well';
    case 'sad':
      return 'emotional support and taking small recovery steps';
    case 'anxious':
      return 'grounding, reassurance, and reducing pressure';
    case 'reflective':
      return 'reflection, clarity, and naming what matters';
    default:
      return 'checking in and caring for the user’s Mind Garden';
  }
}

String _topicFromConversation(String combinedUserText) {
  final text = combinedUserText.toLowerCase();
  final topicPatterns = <String, List<String>>{
    'exam performance': ['exam', 'test', 'grade', 'marks', 'failed', 'fail'],
    'school pressure': ['school', 'class', 'assignment', 'homework', 'study'],
    'work stress': ['work', 'job', 'boss', 'deadline', 'office'],
    'friendship or relationship strain': [
      'friend',
      'partner',
      'relationship',
      'breakup',
      'fight',
    ],
    'family stress': ['family', 'parent', 'mom', 'dad', 'sibling'],
    'loneliness': ['lonely', 'alone', 'isolated'],
    'sleep and exhaustion': ['sleep', 'tired', 'exhausted', 'drained'],
    'self-worth and confidence': [
      'worthless',
      'not good enough',
      'self doubt',
      'self-doubt',
      'confidence',
    ],
  };

  for (final entry in topicPatterns.entries) {
    if (entry.value.any(text.contains)) return entry.key;
  }

  return _trimForSummary(combinedUserText, maxLength: 120);
}

String _feelingsFromConversation(String combinedUserText, String emotion) {
  final text = combinedUserText.toLowerCase();
  final feelings = <String>[];

  if (_containsAny(
      text, const ['terrible', 'failed', 'fail', 'disappointed'])) {
    feelings.add('disappointment');
  }
  if (_containsAny(text, const [
    'self doubt',
    'self-doubt',
    'not good enough',
    'worthless',
  ])) {
    feelings.add('self-doubt');
  }
  if (_containsAny(text, const ['anxious', 'anxiety', 'worried', 'panic'])) {
    feelings.add('anxiety');
  }
  if (_containsAny(text, const ['overwhelmed', 'pressure', 'stress'])) {
    feelings.add('overwhelm');
  }
  if (_containsAny(text, const ['sad', 'lonely', 'hurt', 'cry', 'hopeless'])) {
    feelings.add('sadness');
  }
  if (_containsAny(text, const ['happy', 'grateful', 'excited', 'relieved'])) {
    feelings.add('relief or positivity');
  }

  if (feelings.isNotEmpty) return feelings.toSet().join(' and ');

  switch (emotion) {
    case 'happy':
      return 'positivity';
    case 'sad':
      return 'sadness';
    case 'anxious':
      return 'anxiety';
    case 'reflective':
      return 'reflection and uncertainty';
    default:
      return 'mixed emotions';
  }
}

String _supportFocusFromConversation({
  required String assistantText,
  required String emotion,
}) {
  final text = assistantText.toLowerCase();
  if (_containsAny(text, const ['small step', 'one step', 'gentle step'])) {
    return 'emotional support and taking small recovery steps';
  }
  if (_containsAny(text, const ['breathe', 'ground', 'slow down'])) {
    return 'grounding, reassurance, and reducing pressure';
  }
  if (_containsAny(text, const ['self-compassion', 'kind to yourself'])) {
    return 'self-compassion and responding gently to the moment';
  }
  if (_containsAny(text, const ['plan', 'next step', 'try'])) {
    return 'turning the situation into one manageable next step';
  }

  return _focusForMood(emotion);
}

String _buildConversationSummary({
  required List<Map<String, dynamic>> previousMessages,
  required String userMessage,
  required String emotion,
  required String aiReply,
}) {
  final userMessages = previousMessages
      .where((message) => message['role'] == 'user')
      .map((message) => message['content']?.toString() ?? '')
      .where((message) => message.trim().isNotEmpty)
      .toList()
    ..add(userMessage);

  final start = userMessages.length > 4 ? userMessages.length - 4 : 0;
  final recentUserText =
      userMessages.sublist(start).map(_trimForSummary).join(' ');
  final assistantMessages = previousMessages
      .where((message) => message['role'] == 'assistant')
      .map((message) => message['content']?.toString() ?? '')
      .where((message) => message.trim().isNotEmpty)
      .toList()
    ..add(aiReply);
  final assistantStart =
      assistantMessages.length > 4 ? assistantMessages.length - 4 : 0;
  final assistantText =
      assistantMessages.sublist(assistantStart).map(_trimForSummary).join(' ');

  final topic = _topicFromConversation(recentUserText);
  final feelings = _feelingsFromConversation(recentUserText, emotion);
  final supportFocus = _supportFocusFromConversation(
    assistantText: assistantText,
    emotion: emotion,
  );

  return 'The user discussed $topic and feelings of $feelings. '
      'The conversation focused on $supportFocus.';
}

Future<void> _ensureUserRow(SupabaseClient supabase, String userId) async {
  final existing =
      await supabase.from('users').select('id').eq('id', userId).maybeSingle();

  if (existing != null) return;

  await supabase.from('users').insert({
    'id': userId,
    'seeds': 50,
    'streak': 0,
  });
}

Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();
    final systemPrompt = context.read<String>();
    final request = context.request;

    if (request.method != HttpMethod.post) {
      return Response.json(
          statusCode: 405, body: {'error': 'Method not allowed'});
    }

    final body = await request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['user_id'] as String?;
    final sessionId = data['session_id'] as String?;
    final rawMessage = data['message'] as String?;

    // 1. Grab the dictionary from the frontend
    final rawDictionary = data['dictionary'] as Map<String, dynamic>? ?? {};
    final currentDictionary =
        rawDictionary.map((k, v) => MapEntry(k, v.toString()));

    if (userId == null ||
        sessionId == null ||
        rawMessage == null ||
        rawMessage.trim().isEmpty) {
      return Response.json(
          statusCode: 400, body: {'error': 'Missing required fields'});
    }

    await _ensureUserRow(supabaseClient, userId);

    // 2. THE ZERO-TRUST SHIELD: Sanitize before doing anything else
    final sanitizedPayload = await PiiSanitizer.sanitize(
      input: rawMessage,
      currentDictionary: currentDictionary,
    );
    final cleanMessage = sanitizedPayload.cleanText;

    // Ensure chat session exists
    final existingSession = await supabaseClient
        .from('chat_sessions')
        .select('id')
        .eq('id', sessionId)
        .maybeSingle();

    if (existingSession == null) {
      await supabaseClient.from('chat_sessions').insert({
        'id': sessionId,
        'user_id': userId,
        'session_date': DateTime.now().toIso8601String().split('T')[0],
      });
    }

    // 3. THE MEMORY LIMIT: Fetch only the last 20 messages (descending, then reverse)
    final historyResponse = await supabaseClient
        .from('chat_messages')
        .select('role, content')
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(50);

    final previousSessionMessages =
        List<Map<String, dynamic>>.from(historyResponse.reversed);
    final previousMessages = previousSessionMessages
        .where(_isVisibleChatMessage)
        .toList(growable: false);

    // Initialize AI service (Check your env key name here!)
    final aiService = AiService();
    await aiService.init(
      apiKey: Env.openRouterApiKey,
      systemPrompt: systemPrompt,
    );

    // Seed history
    aiService.seedHistory(
      previousMessages
          .map<Map<String, String>>(
            (msg) => {
              'role': msg['role'] as String,
              'content': msg['content'] as String,
            },
          )
          .toList(),
    );

    // 4. Save the CLEAN message, not the raw one
    await supabaseClient.from('chat_messages').insert({
      'session_id': sessionId,
      'role': 'user',
      'content': cleanMessage,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Generate AI reply
    final aiReply = await aiService.sendMessage(cleanMessage);

    // Save assistant reply
    await supabaseClient.from('chat_messages').insert({
      'session_id': sessionId,
      'role': 'assistant',
      'content': aiReply,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    final userTurnsSinceLastReward =
        _userTurnsSinceLastReward(previousSessionMessages) + 1;
    final emotion = _detectEmotion(cleanMessage);
    final completionDetected = _isConversationConclusion(
      previousMessages: previousMessages,
      userMessage: cleanMessage,
      aiReply: aiReply,
      emotion: emotion,
    );
    final conversationCompleted =
        completionDetected && userTurnsSinceLastReward >= 2;
    int? streak;
    int? seeds;
    Map<String, dynamic>? seedReward;

    try {
      if (conversationCompleted) {
        final streakService = StreakService(supabaseClient);
        final seedService = SeedService(supabaseClient);
        final journalService = JournalService(supabaseClient);

        try {
          final updatedUser = await streakService.updateStreak(userId);
          streak = updatedUser.streak;
        } catch (e) {
          stdout.writeln(
            '[PIPELINE ERROR] route=/send_message stage=streak '
            'sessionId=$sessionId userId=$userId error=$e',
          );
        }

        try {
          final generatedSummary = _buildConversationSummary(
            previousMessages: previousMessages,
            userMessage: cleanMessage,
            emotion: emotion,
            aiReply: aiReply,
          );
          stdout.writeln('[AUTO SUMMARY] generatedSummary=$generatedSummary');
          await journalService.saveAutoSummary(
            userId: userId,
            summary: generatedSummary,
            mood: emotion,
          );
        } catch (e) {
          stdout.writeln(
            '[PIPELINE ERROR] route=/send_message stage=auto_journal '
            'sessionId=$sessionId userId=$userId error=$e',
          );
        }
        try {
          final reward = await seedService.rewardCompletedConversation(
            userId: userId,
            mood: emotion,
          );
          seeds = reward.totalSeeds;
          seedReward = reward.toJson();

          if (reward.awarded) {
            await _insertRewardMarker(
              supabaseClient,
              sessionId,
              mood: emotion,
              earnedSeeds: reward.earnedMoodSeeds,
            );
          }
        } catch (e) {
          stdout.writeln(
            '[PIPELINE ERROR] route=/send_message stage=reward '
            'sessionId=$sessionId userId=$userId error=$e',
          );
        }
      } else if (completionDetected) {
        stdout.writeln(
          '[REWARD] oldSeeds=unknown reward=0 newSeeds=unknown '
          'reason=insufficient_user_turns sessionId=$sessionId '
          'userTurnsSinceLastReward=$userTurnsSinceLastReward',
        );
      }
    } catch (e) {
      stdout.writeln(
        '[PIPELINE ERROR] route=/send_message sessionId=$sessionId '
        'userId=$userId error=$e',
      );
    }

    // 5. Return the updated dictionary to the frontend SecureVault
    return Response.json(
      body: {
        'reply': aiReply,
        'session_id': sessionId,
        'dictionary': sanitizedPayload.updatedDictionary,
        'emotion': emotion,
        'conversation_completed': conversationCompleted,
        'streak': streak,
        'seeds': seeds,
        'seed_reward': seedReward,
      },
    );
  } catch (e, stackTrace) {
    print('SEND_MESSAGE ERROR: $e');
    print(stackTrace);

    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
