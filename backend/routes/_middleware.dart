import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

final _cachedSystemPrompt = File('instructions.txt').readAsStringSync();

final _supabaseClient = SupabaseClient(
  'https://jnvxhpjxktynvkqrjrfa.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpudnhocGp4a3R5bnZrcXJqcmZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNDM2NjYsImV4cCI6MjA4NTYxOTY2Nn0.BDovwiDWt4m3SwTx57GRz2isJaaoI0xtQH_E4E1qcsM',
  authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
);

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(_corsHeaders())
      .use(provider<SupabaseClient>((context) => _supabaseClient))
      .use(provider<String>((context) => _cachedSystemPrompt));
}

Middleware _corsHeaders() {
  return (handler) {
    return (context) async {
      // Handle preflight OPTIONS request
      if (context.request.method == HttpMethod.options) {
        return Response(statusCode: 204, headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        },);
      }

      // Process regular request
      final response = await handler(context);

      // Append CORS headers to the response
      return response.copyWith(
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        },
      );
    };
  };
}