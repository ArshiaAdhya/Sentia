/// HOME DATA API
/// Returns:
/// - total seeds
/// - current streak
/// Used for top UI display
library;

import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();

    final request = context.request;

    // Only allow GET requests
    if (request.method != HttpMethod.get) {
      return Response.json(
        statusCode: 405,
        body: {
          'error': 'Method not allowed',
        },
      );
    }

    // Get user_id from query params
    final userId = request.uri.queryParameters['user_id'];

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'user_id is required',
        },
      );
    }

    // Fetch user data
    final userData = await supabaseClient
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (userData == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'error': 'User not found',
        },
      );
    }

    final joinedSource = userData['joined_at'] ?? userData['created_at'];
    var joinedYear = 2026;
    if (joinedSource != null) {
      joinedYear = DateTime.parse(joinedSource.toString()).year;
    }

    return Response.json(
      body: {
        'seeds': userData['seeds'] ?? 0,
        'streak': userData['streak'] ?? 0,
        'joined_year': joinedYear,
        'username': userData['username'] ??
            userData['name'] ??
            userData['display_name'],
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
