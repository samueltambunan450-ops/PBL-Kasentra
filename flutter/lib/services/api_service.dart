import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.1.2:8000/api';
  }

  static Future<Map<String, String>> authHeaders(String? token) async {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await authHeaders(token),
    );
    return _decode(response);
  }

  static Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await authHeaders(token),
      body: jsonEncode(body ?? {}),
    );
    return _decode(response);
  }

  static Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await authHeaders(token),
      body: jsonEncode(body ?? {}),
    );
    return _decode(response);
  }

  static Future<dynamic> delete(String path, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await authHeaders(token),
    );
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    dynamic body;
    if (response.body.isEmpty) {
      body = null;
    } else {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        // Jika server tidak mengembalikan JSON, tetap kembalikan string errornya.
        body = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map<String, dynamic> && body['message'] != null)
        ? body['message'].toString()
        : (body is String && body.isNotEmpty)
        ? body
        : 'Terjadi kesalahan pada server (${response.statusCode})';

    throw Exception(message);
  }
}
