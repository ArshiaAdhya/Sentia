import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final queryParams = context.request.uri.queryParameters;
  final dateParam = queryParams['date']; // Expected format: YYYY-MM-DD
  final userId = queryParams['userId']; // MINIMAL APP: Read userId from query
  
  if (dateParam == null || userId == null) {
     return Response.json(statusCode: 400, body: {'error': 'date and userId parameters are required (e.g. ?date=2023-10-25&userId=123)'});
  }

  final supabase = context.read<SupabaseClient>();

  try {
    // Parse date to define start and end of the day
    final date = DateTime.parse(dateParam);
    final nextDay = date.add(const Duration(days: 1));

    // Fetch journal summaries from database for that specific date
    final journalResponse = await supabase
        .from('journal_entries')
        .select('*, summary_text')
        .eq('user_id', userId)
        .gte('created_at', date.toIso8601String())
        .lt('created_at', nextDay.toIso8601String());

    return Response.json(
      body: {
        'date': dateParam,
        'journals': journalResponse,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
