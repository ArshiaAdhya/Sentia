import 'api_service.dart';
import 'secure_vault.dart';

class ChatResponse {
  final String reply;
  final int? seeds;
  final int? streak;
  final String? emotion;
  final Map<String, dynamic>? seedReward;
  final bool conversationCompleted;

  const ChatResponse({
    required this.reply,
    this.seeds,
    this.streak,
    this.emotion,
    this.seedReward,
    this.conversationCompleted = false,
  });
}

class ChatService {
  /// Sends a message via REST, syncs the vault, and returns the fully translated reply
  static Future<ChatResponse> sendMessageToSentia({
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
        await SecureVault.saveDictionary(
            Map<String, String>.from(response['dictionary']));
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

      // --- DEBUG PRINTS FOR CONSOLE ---
      print('\n=== CHAT LOG ===');
      print('1. User Input (Raw): $rawUserMessage');
      print('2. Sanitized Input (Sent to AI): ${response['sanitized_message'] ?? 'N/A'}');
      print('3. AI Response (Raw with Tokens): $rawAiReply');
      print('4. Final Output (Tokens Replaced): $translatedUIString');
      print('================\n');

      // 7. Return the final string to the Controller
      return ChatResponse(
        reply: translatedUIString,
        seeds: response['seeds'] as int?,
        streak: response['streak'] as int?,
        emotion: response['emotion'] as String?,
        seedReward: response['seed_reward'] is Map<String, dynamic>
            ? response['seed_reward'] as Map<String, dynamic>
            : null,
        conversationCompleted: response['conversation_completed'] == true,
      );
    } catch (e, stackTrace) {
      print('ChatService [sendMessageToSentia] Error: $e\nStackTrace: $stackTrace');
      throw Exception("Failed to connect to Sentia via /send_message: $e");
    }
  }
}
