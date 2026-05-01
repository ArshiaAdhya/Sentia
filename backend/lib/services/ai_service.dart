import 'dart:convert';
import 'package:backend/env/envied.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class AiService {
  final String _apiKey = Env.geminiApiKey;
  final String _model = 'gemini-2.5-flash';
  final logger = Logger();

  // Return a Stream<String> instead of a Future<String>
  Stream<String> sendStreamingMessage(String sanitizedMessage) async* {
    // The ?alt=sse query parameter tells to stream the response
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?alt=sse&key=$_apiKey');

    final payload = {
      'systemInstruction': {
        'parts': [
          {
            'text': 'You are Sentia, an empathetic CBT therapy companion. '
                'User messages will contain capitalized tokens (e.g., ALIAS_PER_1). '
                'You MUST treat these tokens as their actual names. '
                'Do not acknowledge that they are tokens.'
          }
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': sanitizedMessage}
          ]
        }
      ]
    };

    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(payload);

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      yield "I'm experiencing a momentary connection issue. Take a deep breath,"
          " I'll be right back.";
      client.close();
      return;
    }

    // Parse the incoming byte stream into lines of text
    final stream =
        response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      // Server-Sent Events (SSE) start with 'data: '
      if (line.startsWith('data: ')) {
        final dataString = line.substring(6);
        try {
          final jsonData = jsonDecode(dataString) as Map<String, dynamic>;
          final candidate = jsonData['candidates'][0] as Map<String, dynamic>;

          // 1. Yield the text chunk if it exists in this payload
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            final textChunk = candidate['content']['parts'][0]['text'] as String;
            if (textChunk != null && textChunk.isNotEmpty) {
              yield textChunk;
            }
          }

          if (candidate['finishReason'] == 'STOP') {
            break;
          }
        } catch (e, stackTrace) {
          // If a chunk fails to parse, silently ignore it so the stream doesn't crash
          logger.e('Chunk pares error', error:e, stackTrace: stackTrace);
        }
      }
    }
    client.close();
  }
}
