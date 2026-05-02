import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';
import 'package:backend/env/envied.dart';

// 1. Read the file synchronously into RAM. 
// This happens exactly ONCE during the entire lifecycle of the server.
final _cachedSystemPrompt = File('instructions.txt').readAsStringSync();

final _supabaseClient = SupabaseClient(
  Env.supabaseUrl,
  Env.supabaseServiceRoleKey,
);

Handler middleware(Handler handler) {
  return handler
    // Inject the Supabase Client
    .use(provider<SupabaseClient>((context) => _supabaseClient))
    // 2. Inject the cached prompt into the request pipeline
    .use(provider<String>((context) => _cachedSystemPrompt));
}