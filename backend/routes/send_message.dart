/// MAIN CHAT API
/// Handles full backend flow:
/// 1. Receives user message
/// 2. Calls AI service (reply + emotion)
/// 3. Calls streak & mood service
/// 4. Calls seed service (calculate seeds)
/// 5. Calls DB service (store everything)
/// 6. Returns final response to frontend

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../lib/services/ai/ai_service.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();
    final systemPrompt = context.read<String>();
    final request = context.request;

    // Only allow POST requests
    if (request.method != HttpMethod.post) {
      return Response.json(
        statusCode: 405,
        body: {
          'error': 'Method not allowed',
        },
      );
    }

    // Parse request body
    final body = await request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['user_id'] as String?;
    final sessionId = data['session_id'] as String?;
    final message = data['message'] as String?;

    // Validation
    if (userId == null ||
        sessionId == null ||
        message == null ||
        message.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Missing required fields',
        },
      );
    }

    // Fetch previous chat history
    final previousMessages = await supabaseClient
        .from('chat_messages')
        .select('role, content')
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    // Initialize AI service
    final aiService = AiService();

    await aiService.init(
      apiKey: Platform.environment['OPENROUTER_API_KEY'] ?? '',
      systemPrompt: systemPrompt,
    );

    // Seed previous history into AI memory
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

    // Save user message
    await supabaseClient.from('chat_messages').insert({
      'session_id': sessionId,
      'role': 'user',
      'content': message,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Generate AI reply
    final aiReply = await aiService.sendMessage(message);

    // Save assistant reply
    await supabaseClient.from('chat_messages').insert({
      'session_id': sessionId,
      'role': 'assistant',
      'content': aiReply,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Return response
    return Response.json(
      body: {
        'reply': aiReply,
        'session_id': sessionId,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'error': e.toString(),
      },
    );
  }
}