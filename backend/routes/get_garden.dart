/// GARDEN API
/// Fetches planted flowers for user
/// Returns garden state

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

    final userId = request.uri.queryParameters['user_id'];

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'user_id is required',
        },
      );
    }

    final gardenItems = await supabaseClient
        .from('user_garden_items')
        .select()
        .eq('user_id', userId)
        .order('planted_at', ascending: false);

    return Response.json(
      body: {
        'garden': gardenItems,
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