/// CHAT HISTORY API
/// Fetches previous chat messages for user
library;

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();

    final request = context.request;

    if (request.method != HttpMethod.get) {
      return Response.json(
        statusCode: 405,
        body: {
          'error': 'Method not allowed',
        },
      );
    }

    final sessionId = request.uri.queryParameters['session_id'];

    if (sessionId == null || sessionId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'session_id is required',
        },
      );
    }

    final messages = await supabaseClient
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return Response.json(
      body: {
        'messages': messages,
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