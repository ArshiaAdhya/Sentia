import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }

  static Future<void> saveAuthData(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('auth_token');
    final sessionKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('chat_session_'))
        .toList();
    for (final key in sessionKeys) {
      await prefs.remove(key);
    }
  }

  static Future<String> getOrCreateSessionId(String userId) async {
    if (userId.isEmpty) return '';

    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_session_$userId';
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newSessionId = const Uuid().v4();
    await prefs.setString(key, newSessionId);
    return newSessionId;
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return {};
    } else {
      if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData is Map<String, dynamic>) {
            return errorData; // Return error JSON so UI can display it ('error' key)
          }
        } catch (_) {}
      }
      throw Exception('Failed to request data: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return {};
    } else {
      if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData is Map<String, dynamic>) {
            return errorData;
          }
        } catch (_) {}
      }
      throw Exception('Failed to request data: ${response.statusCode}');
    }
  }
}
