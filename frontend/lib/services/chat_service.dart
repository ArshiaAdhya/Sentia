import 'api_service.dart';
import 'secure_vault.dart';

class ChatService {
  /// Sends a message via REST, syncs the vault, and returns the fully translated reply
  static Future<String> sendMessageToSentia({
    required String rawUserMessage,
    required String userId,
    required String sessionId,
  }) async {
    // 1. Load the secret cipher vault
    final currentDictionary = await SecureVault.loadDictionary();

    try {
      // 2. Send the HTTP POST request using your ApiService
      final response = await ApiService.post('/send_message', {
        'user_id': userId,
        'session_id': sessionId,
        'message': rawUserMessage,
        'dictionary': currentDictionary, // Send the Zero-Trust shield!
      });

      // 3. Update our SecureVault with any new proper nouns the AI learned
      if (response['dictionary'] != null) {
        await SecureVault.saveDictionary(Map<String, String>.from(response['dictionary']));
      }

      // 4. Grab the raw AI reply (still contains ALIAS_PER_1, etc.)
      final rawAiReply = response['reply'] as String;

      // 5. Load the freshest vault to ensure we have the new keys
      final latestVault = await SecureVault.loadDictionary();

      // 6. Translate the string locally on the device
      String translatedUIString = rawAiReply;
      latestVault.forEach((alias, realName) {
        translatedUIString = translatedUIString.replaceAll(alias, realName);
      });

      // 7. Return the final string to the Controller
      return translatedUIString;

    } catch (e) {
      print('ChatService Error: $e');
      throw Exception("Failed to connect to Sentia.");
    }
  }
}