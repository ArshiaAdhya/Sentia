import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Wraps OpenRouter's chat API with Pip's penguin personality.
/// One instance per chat session — maintains conversation history.
/// Falls back through multiple free models if one is rate-limited.
class AiService {
  late String _apiKey;
  late String _systemPrompt;

  final List<Map<String, String>> _history = [];
  bool _initialized = false;

  // Free models tried in order — exact IDs verified from OpenRouter API.
  // 403 (moderation block) and 400 (no system-prompt support) fall through gracefully.
  static const _models = [
    'google/gemma-4-31b-it:free',            // Google Gemma 4 31B
    'openai/gpt-oss-120b:free',              // OpenAI gpt-oss 120B
    'google/gemma-3-27b-it:free',            // Google Gemma 3 27B
    'openai/gpt-oss-20b:free',               // OpenAI gpt-oss 20B
    'google/gemma-3-12b-it:free',            // Google Gemma 3 12B — last resort
  ];
  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> init({
    required String apiKey,
    String instructionsPath = 'instructions.txt',
    String? userContext,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('OPENROUTER_API_KEY is empty. Check your .env file.');
    }

    final file = File(instructionsPath);
    if (!file.existsSync()) {
      throw StateError(
        'instructions.txt not found at "$instructionsPath". '
        'Make sure the file exists in the backend root.',
      );
    }

    _systemPrompt = await file.readAsString();

    if (userContext != null && userContext.isNotEmpty) {
      _systemPrompt +=
          '\n\n## User Context (from personality quiz)\n$userContext';
    }

    _apiKey = apiKey;
    _initialized = true;
  }

  // ── Seed history ──────────────────────────────────────────────────────────

  void seedHistory(List<Map<String, String>> priorMessages) {
    if (!_initialized) throw StateError('Call init() before seedHistory().');
    _history.clear();
    for (final m in priorMessages) {
      final role = m['role'] == 'assistant' ? 'assistant' : 'user';
      _history.add({'role': role, 'content': m['content'] ?? ''});
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────

  Future<String> sendMessage(String userMessage) async {
    if (!_initialized) throw StateError('Call init() before sendMessage().');
    if (userMessage.trim().isEmpty) {
      return "I'm right here 🐧 Whenever you're ready, I'm all ears!";
    }

    _history.add({'role': 'user', 'content': userMessage.trim()});

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._history,
    ];

    Exception? lastError;

    for (final model in _models) {
      try {
        final response = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://sentia.app',
            'X-Title': 'Sentia AI',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.85,
            'max_tokens': 512,
          }),
        );

        // Skip to next model on: rate limit, not found, moderation block, bad request
        if (response.statusCode == 429 || response.statusCode == 404 ||
            response.statusCode == 403 || response.statusCode == 400) {
          stdout.writeln(
            '[Pip] ⚠️  $model blocked/unavailable (${response.statusCode}), trying next...',
          );
          lastError = Exception('${response.statusCode}: ${response.body}');
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception(
            'OpenRouter error ${response.statusCode}: ${response.body}',
          );
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            (data['choices'] as List).first['message']['content'] as String? ??
            '';

        if (text.isEmpty) {
          return 'Hmm, I got a little confused 🐧 Could you say that again?';
        }

        stdout.writeln('[Pip] ✅ Reply via $model');
        _history.add({'role': 'assistant', 'content': text});
        return text;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('429') ||
            msg.contains('404') ||
            msg.contains('403') ||
            msg.contains('rate')) {
          stdout.writeln('[Pip] ⚠️  $model unavailable/blocked, trying next...');
          lastError = e is Exception ? e : Exception(msg);
          continue;
        }
        throw Exception('OpenRouter API error: $e');
      }
    }

    throw lastError ??
        Exception(
          'All OpenRouter free models are currently unavailable. Try again shortly.',
        );
  }
}