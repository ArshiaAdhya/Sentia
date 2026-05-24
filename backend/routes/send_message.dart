import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

import 'package:backend/services/ai/ai_service.dart';
import 'package:backend/services/pii_sanitizer.dart'; // Ensure this is imported

Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();
    final systemPrompt = context.read<String>();
    final request = context.request;

    if (request.method != HttpMethod.post) {
      return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
    }

    final body = await request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['user_id'] as String?;
    final sessionId = data['session_id'] as String?;
    final rawMessage = data['message'] as String?;
    
    // 1. Grab the dictionary from the frontend
    final rawDictionary = data['dictionary'] as Map<String, dynamic>? ?? {};
    final currentDictionary = rawDictionary.map((k, v) => MapEntry(k, v.toString()));

    if (userId == null || sessionId == null || rawMessage == null || rawMessage.trim().isEmpty) {
      return Response.json(statusCode: 400, body: {'error': 'Missing required fields'});
    }

    // 2. THE ZERO-TRUST SHIELD: Sanitize before doing anything else
    final sanitizedPayload = await PiiSanitizer.sanitize(
      input: rawMessage,
      currentDictionary: currentDictionary,
    );
    final cleanMessage = sanitizedPayload.cleanText;

    // 3. THE MEMORY LIMIT: Fetch only the last 20 messages (descending, then reverse)
    final historyResponse = await supabaseClient
        .from('chat_messages')
        .select('role, content')
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(20);
        
    final previousMessages = List<Map<String, dynamic>>.from(historyResponse.reversed);

    // Initialize AI service (Check your env key name here!)
    final aiService = AiService();
    await aiService.init(
      apiKey: Platform.environment['OPENROUTER_API_KEY'] ?? '', 
      systemPrompt: systemPrompt,
    );

    // Seed history
    aiService.seedHistory(
      previousMessages.map<Map<String, String>>(
        (msg) => {
          'role': msg['role'] as String,
          'content': msg['content'] as String,
        },
      ).toList(),
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

    // 5. Return the updated dictionary to the frontend SecureVault
    return Response.json(
      body: {
        'reply': aiReply,
        'session_id': sessionId,
        'dictionary': sanitizedPayload.updatedDictionary,
      },
    );
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}