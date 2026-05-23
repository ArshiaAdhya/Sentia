import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

final _cachedSystemPrompt = File('instructions.txt').readAsStringSync();

final _supabaseClient = SupabaseClient(
  'https://jnvxhpjxktynvkqrjrfa.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpudnhocGp4a3R5bnZrcXJqcmZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNDM2NjYsImV4cCI6MjA4NTYxOTY2Nn0.BDovwiDWt4m3SwTx57GRz2isJaaoI0xtQH_E4E1qcsM',
);

Handler middleware(Handler handler) {
  return handler
      .use(provider<SupabaseClient>((context) => _supabaseClient))
      .use(provider<String>((context) => _cachedSystemPrompt));
}