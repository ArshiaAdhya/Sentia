import 'dart:convert';
import 'package:backend/env/envied.dart';
import 'package:backend/models/sanitized_payload.dart';
import 'package:http/http.dart' as http;

class PiiSanitizer {
  static final String _hfToken = Env.huggingFaceToken;
  static const String _hfEndpoint =
      'https://router.huggingface.co/hf-inference/models/dslim/bert-base-NER';

  static Future<SanitizedPayload> sanitize({
    required String input,
    required Map<String, String> currentDictionary,
  }) async {
    var workingText = input;
    final newDictionary =
        Map<String, String>.from(currentDictionary);

    // 1. REGEX PASS (Structured PII)
    final emailRegex =
        RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    workingText = workingText.replaceAll(emailRegex, '[EMAIL_REMOVED]');

    final phoneRegex =
        RegExp(r'(\+\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}');
    workingText = workingText.replaceAll(phoneRegex, '[PHONE_REMOVED]');

    if (workingText.contains('[EMAIL_REMOVED]')) print('🛡️ REGEX: Stripped an email address.');
    if (workingText.contains('[PHONE_REMOVED]')) print('🛡️ REGEX: Stripped a phone number.');

    // 2. THE PRE-FLIGHT SWEEP (Case-Insensitive Known Entities)
    // We sweep for names the user has already mentioned in past messages.
    currentDictionary.forEach((alias, realName) {
      // \b ensures whole-word matching. RegExp.escape prevents regex injection if a name has symbols.
      // caseSensitive: false is the magic bullet that catches "mark", "MARK", or "mArK".
      final knownEntityRegex =
          RegExp(r'\b' + RegExp.escape(realName) + r'\b', caseSensitive: false);
      workingText = workingText.replaceAll(knownEntityRegex, alias);
    });

    // 3. HUGGING FACE PASS (Unstructured PII - NEW Names & Orgs)
    try {
      final response = await http.post(
        Uri.parse(_hfEndpoint),
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
          'x-wait-for-model' : 'true',
        },
        // workingText now has known entities already masked!
        body: jsonEncode({
          'inputs': workingText,
          'parameters': {
            'aggregation_strategy': 'simple', 
          },
        }),
      );

      if (response.statusCode == 200) {
        final rawEntities = jsonDecode(response.body) as List<dynamic>;

        // We walk the string boundaries manually to capture the full word.
        final entities = <Map<String, dynamic>>[];
        
        for (final raw in rawEntities) {
          final e = Map<String, dynamic>.from(raw as Map);
          var start = e['start'] as int;
          var end = e['end'] as int;

          // Treat string as a char array. Walk the left pointer backward.
          while (start > 0 && RegExp('[a-zA-Z0-9]').hasMatch(workingText[start - 1])) {
            start--;
          }
          // Walk the right pointer forward.
          while (end < workingText.length && RegExp('[a-zA-Z0-9]').hasMatch(workingText[end])) {
            end++;
          }

          e['start'] = start;
          e['end'] = end;
          e['word'] = workingText.substring(start, end);

          // Deduplicate: If multiple sub-tokens expand into the same word, only keep one.
          if (!entities.any((existing) => existing['start'] == start && existing['end'] == end)) {
            entities.add(e);
          }
        }

        // Sort backwards so string replacement doesn't shift our index targets
        entities.sort((a, b) => (b['end'] as int).compareTo(a['start'] as int));

        // 2. THE BOUNDARY MAPPER (Replacing the sloppy Blast Radius)
        // Find the exact start and end indexes of every ALIAS token in the text.
        final aliasBounds = <List<int>>[];
        final aliasRegex = RegExp('ALIAS_[A-Z]+_[0-9]+');
        for (final match in aliasRegex.allMatches(workingText)) {
          aliasBounds.add([match.start, match.end]);
        }

        for (final entity in entities) {
          // Fallback safely in case HF returns 'entity' instead of 'entity_group'
          final rawType = entity['entity_group'] ?? entity['entity'] ?? '';
          final type = rawType.toString().replaceAll('B-', '').replaceAll('I-', ''); 
          
          final word = entity['word'] as String;
          final start = entity['start'] as int;
          final end = entity['end'] as int;

          // 3. EXACT BOUNDARY CHECK
          var isInsideAlias = false;
          for (final bound in aliasBounds) {
            // If the AI's token mathematically overlaps with our ALIAS bounds, it's a hallucination.
            if (start < bound[1] && end > bound[0]) {
              isInsideAlias = true;
              break;
            }
          }

          if (isInsideAlias) {
            print('🛡️ AI CONFUSION AVERTED: Token "$word" overlaps with an ALIAS tag.');
            continue; 
          }

          // We only care about People, Organizations, and Locations
          if (type == 'PER' || type == 'ORG' || type == 'LOC') {
            var tokenToUse = '';

            final existingEntry = newDictionary.entries.where((e) => e.value.toLowerCase() == word.toLowerCase()).toList();
            
            if (existingEntry.isNotEmpty) {
              tokenToUse = existingEntry.first.key;
            } else {
              final countType = newDictionary.keys.where((k) => k.contains(type)).length + 1;
              tokenToUse = 'ALIAS_${type}_$countType';
              newDictionary[tokenToUse] = word;
            }

            workingText = workingText.replaceRange(start, end, tokenToUse);
            print('🚨 NER CAUGHT: "$word" (Type: $type) -> Swapped to $tokenToUse');
          }
        }
      } else {
        print(
            'Hugging Face API Error: ${response.statusCode} - ${response.body}',);
        // If HF fails, we gracefully fallback to the Regex-only scrub so the app doesn't crash
      }
    } catch (e) {
      print('Sanitization Exception: $e');
    }

    print('\n--- ZERO TRUST PIPELINE RESULT ---');
    print('RAW: $input');
    print('CLEAN: $workingText');
    print('----------------------------------\n');

    return SanitizedPayload(
      cleanText: workingText,
      updatedDictionary: newDictionary,
    );
  }
}