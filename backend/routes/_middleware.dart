import 'dart:io';

import 'package:backend/env/envied.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

final _cachedSystemPrompt = File('instructions.txt').readAsStringSync();
final _supabaseUrl = (Platform.environment['SUPABASE_URL'] ?? '').trim().isEmpty
    ? Env.supabaseUrl
    : (Platform.environment['SUPABASE_URL'] ?? '').trim();
final _supabaseKey =
    (Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim().isEmpty
        ? Env.supabaseServiceRoleKey
        : (Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim();

final _supabaseClient = SupabaseClient(
  _supabaseUrl,
  _supabaseKey,
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
        return Response(
          statusCode: 204,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers':
                'Origin, Content-Type, Authorization',
          },
        );
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
