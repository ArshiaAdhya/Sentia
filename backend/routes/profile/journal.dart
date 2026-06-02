import 'dart:io';

import 'package:backend/services/journal/journal_service.dart';
import 'package:backend/utils/helpers.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

DateTime _parseDateParam(String value) {
  final parts = value.split('-').map(int.parse).toList();
  if (parts.length != 3) {
    throw FormatException('Expected YYYY-MM-DD date', value);
  }
  return DateTime(parts[0], parts[1], parts[2]);
}

String _todayDateString() {
  final nowIst = toIst(DateTime.now().toUtc());
  return toDateString(DateTime(nowIst.year, nowIst.month, nowIst.day));
}

Future<Response> onRequest(RequestContext context) async {
  final supabase = context.read<SupabaseClient>();
  final service = JournalService(supabase);
  final request = context.request;

  if (request.method == HttpMethod.post) {
    try {
      final body = await request.json() as Map<String, dynamic>;
      final userId = body['userId'] as String? ?? body['user_id'] as String?;
      final entryText = body['text'] as String?;
      final dateString = body['date'] as String? ?? _todayDateString();

      if (userId == null || entryText == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'userId and text are required'},
        );
      }

      final result = await service.saveManualEntry(
        userId: userId,
        text: entryText,
        dateString: dateString,
      );

      return Response.json(
        body: {
          'status': 'success',
          'date': dateString,
          ...result.toJson(),
        },
      );
    } on JournalValidationException catch (e) {
      stderr.writeln(
        '[DIARY ERROR] route=/profile/journal method=POST error=$e',
      );
      return Response.json(statusCode: 400, body: {'error': e.toString()});
    } catch (e) {
      stderr.writeln(
        '[DIARY ERROR] route=/profile/journal method=POST error=$e',
      );
      return Response.json(statusCode: 500, body: {'error': e.toString()});
    }
  }

  if (request.method == HttpMethod.get) {
    final queryParams = request.uri.queryParameters;
    final userId = queryParams['userId'] ?? queryParams['user_id'];
    final dateParam = queryParams['date'];

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'userId parameter is required'},
      );
    }

    try {
      if (dateParam != null && dateParam.isNotEmpty) {
        final date = _parseDateParam(dateParam);
        final journals = await service.getEntriesForDate(
          userId: userId,
          date: date,
        );

        return Response.json(
          body: {
            'date': dateParam,
            'journals': journals,
          },
        );
      }

      final dates = await service.getJournalDates(userId);
      return Response.json(body: {'dates': dates});
    } on FormatException catch (e) {
      stderr.writeln(
        '[DIARY ERROR] route=/profile/journal method=GET error=$e',
      );
      return Response.json(statusCode: 400, body: {'error': e.toString()});
    } catch (e) {
      stderr.writeln(
        '[DIARY ERROR] route=/profile/journal method=GET error=$e',
      );
      return Response.json(statusCode: 500, body: {'error': e.toString()});
    }
  }

  return Response(statusCode: 405, body: 'Method not allowed');
}
