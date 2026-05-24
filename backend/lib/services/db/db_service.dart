/// DATABASE SERVICE
/// Handles all database operations:
/// - save chat
/// - get chat
/// - save seeds
/// - get seeds
/// - save streak
/// - get streak
/// - save garden
/// - fetch garden
/// - user data
///
/// Initializes the global Supabase client (supabaseClient) from env vars
/// SUPABASE_URL and SUPABASE_KEY. Call initSupabase() once at server startup.
/// All repositories import and use supabaseClient directly.
library;

import 'dart:io';
import 'package:supabase/supabase.dart';

late final SupabaseClient supabaseClient;

void initSupabase() {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_KEY'] ?? '';

  if (url.isEmpty || key.isEmpty) {
    throw Exception('SUPABASE_URL and SUPABASE_KEY environment variables must be set.');
  }

  supabaseClient = SupabaseClient(url, key);
}