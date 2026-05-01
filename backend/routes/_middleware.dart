import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

// Use the project URL provided by the user
final supabaseUrl =
    Platform.environment['SUPABASE_URL'] ??
    'https://jnvxhpjxktynvkqrjrfa.supabase.co';
final supabaseKey =
    Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? 'YOUR_SECRET_KEY_HERE_BUT_DONT_COMMIT_IT';

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
