import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  // MINIMAL APP: We skip token validation and accept userId directly from the query
  final queryParams = context.request.uri.queryParameters;
  final userId = queryParams['userId'];
  
  if (userId == null) {
     return Response.json(statusCode: 400, body: {'error': 'userId parameter is required for testing (e.g. ?userId=123)'});
  }

  final supabase = context.read<SupabaseClient>();

  try {
    // Fetch user profile from database
    final profileResponse = await supabase
        .from('users')
        .select('streak, seeds')
        .eq('id', userId)
        .maybeSingle();

    final streak = profileResponse?['streak'] ?? 0;
    final seeds = profileResponse?['seeds'] ?? 0;

    return Response.json(
      body: {
        'userId': userId,
        'streak': streak,
        'seeds': seeds,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
