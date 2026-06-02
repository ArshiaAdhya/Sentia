import 'dart:io';

import 'package:backend/env/envied.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

final supabaseUrl = (Platform.environment['SUPABASE_URL'] ?? '').trim().isEmpty
    ? Env.supabaseUrl
    : (Platform.environment['SUPABASE_URL'] ?? '').trim();
final supabaseKey =
    (Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim().isEmpty
        ? Env.supabaseServiceRoleKey
        : (Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim();

final _supabase = SupabaseClient(
  supabaseUrl,
  supabaseKey,
  authOptions: const AuthClientOptions(
    authFlowType: AuthFlowType.implicit,
  ),
);

Handler middleware(Handler handler) {
  return handler.use(provider<SupabaseClient>((_) => _supabase));
}
