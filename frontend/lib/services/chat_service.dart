import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'secure_vault.dart';

class ChatService {
  static const String _wsUrl = 'ws://10.0.2.2:8080/chat/message';

  /// Returns a stream of translated text that updates in real-time
  static Stream<String> streamMessageToSentia(String rawUserMessage) async* {
    // 1. Load the secret cipher vault
    final currentDictionary = await SecureVault.loadDictionary();

    // 2. Open the WebSocket connection to Dart Frog
    final channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

    // 3. Send the initial payload up the pipe
    channel.sink.add(jsonEncode({
      'message': rawUserMessage,
      'dictionary': currentDictionary,
    }));

    String accumulatedRawAiResponse = "";

    // 4. Listen to the stream coming back from the server
    await for (final incomingData in channel.stream) {
      final data = jsonDecode(incomingData as String);

      // Event A: The backend updated our dictionary with new proper nouns
      if (data['type'] == 'dictionary_update') {
        await SecureVault.saveDictionary(data['dictionary']);
      } 
      
      // Event B: The backend sent a chunk of AI text
      else if (data['type'] == 'ai_chunk') {
        // Accumulate the raw text (which still contains the ALIAS tokens)
        accumulatedRawAiResponse += data['text'];

        // Load the freshest dictionary (in case Event A just updated it)
        final latestVault = await SecureVault.loadDictionary();
        
        // Translate the entire string on-the-fly
        String translatedUIString = accumulatedRawAiResponse;
        latestVault.forEach((alias, realName) {
          translatedUIString = translatedUIString.replaceAll(alias, realName);
        });

        // Yield the clean, human-readable string to the Flutter UI
        yield translatedUIString; 
      }
    }
    
    // 5. Close the connection when the stream is done
    channel.sink.close();
  }
}