import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureVault {
  static const _storage = FlutterSecureStorage();
  static const _dictionaryKey = 'sentia_token_dictionary';

  /// Loads the saved dictionary from hardware encryption
  static Future<Map<String, String>> loadDictionary() async {
    final String? jsonString = await _storage.read(key: _dictionaryKey);
    if (jsonString == null) return {};
    
    final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return decodedMap.map((key,value) => MapEntry(key, value.toString()));
  }

  /// Saves the updated dictionary returned by Dart Frog
  static Future<void> saveDictionary(Map<String, dynamic> newDictionary) async {
    final jsonString = jsonEncode(newDictionary);
    await _storage.write(key: _dictionaryKey, value: jsonString);
  }
}