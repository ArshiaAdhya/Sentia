import 'dart:convert';

import 'package:backend/services/ai/ai_service.dart';
import 'package:backend/services/pii_sanitizer.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';


Handler get onRequest {
  return webSocketHandler((channel, protocol) {
    // Listen for incoming messages from the Flutter app
    channel.stream.listen((incomingMessage) async {
      try {
        // 1. Parse the payload from Flutter
        final body = jsonDecode(incomingMessage as String);
        final rawUserMessage = body['message'] as String;
        final incomingDictionary =
            Map<String, String>.from((body['dictionary'] as Map?) ?? {});

        // 2. Sanitize the input
        final sanitizedPayload = await PiiSanitizer.sanitize(
          input: rawUserMessage,
          currentDictionary: incomingDictionary,
        );

        // 3. Send the new dictionary back to Flutter immediately
        channel.sink.add(jsonEncode({
          'type': 'dictionary_update',
          'dictionary': sanitizedPayload.updatedDictionary,
        }),);

        // 4. Get the AI Stream
        // *Note: Dart Frog websockets don't have access
        // to standard middleware context
        // in the same way HTTP routes do, so we
        // instantiate it here or pass it globally.
        final aiService = AiService();
        final aiStream =
            aiService.sendStreamingMessage(sanitizedPayload.cleanText);

        // 5. Listen to Gemini and pipe it to Flutter
        await for (final chunk in aiStream) {
          channel.sink.add(jsonEncode({
            'type': 'ai_chunk',
            'text': chunk,
          }),);
        }
      } catch (e) {
        print('WebSocket Error: $e');
        channel.sink.add(jsonEncode({
          'type': 'ai_chunk',
          'text': '\n\n(Connection error. Please try again.)',
        }),);
      }
    });
  });
}
