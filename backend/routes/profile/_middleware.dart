import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? 'https://jnvxhpjxktynvkqrjrfa.supabase.co';
final supabaseKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? 'YOUR_SUPABASE_SERVICE_ROLE_KEY';

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

