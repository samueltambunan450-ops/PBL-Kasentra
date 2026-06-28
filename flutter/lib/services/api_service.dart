import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  /// Base API URL.
  ///
  /// - `kIsWeb`: `http://127.0.0.1:8000/api`
  /// - Android emulator: `http://10.0.2.2:8000/api`
  /// - iOS simulator: `http://127.0.0.1:8000/api`
  /// - Physical devices: must override with Dart define
  ///   `--dart-define=API_BASE_URL=http://<IP-PC>:8000/api`
  ///
  /// If you run on a real phone and do not set API_BASE_URL, the app
  /// may still try to use emulator/local URLs and fail.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static String get storageBaseUrl {
    final uri = Uri.parse(baseUrl);
    final filteredSegments = uri.pathSegments.where((segment) => segment != 'api').toList();
    return uri.replace(pathSegments: filteredSegments).toString().replaceAll(RegExp(r'/+$'), '');
  }

  static String buildFotoUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;

    var cleanedPath = relativePath.trim();
    if (cleanedPath.startsWith('/')) {
      cleanedPath = cleanedPath.substring(1);
    }

    // Extract just the filename from paths like "bukti/xxx.jpg" or "storage/bukti/xxx.jpg"
    String filename;
    if (cleanedPath.contains('/')) {
      filename = cleanedPath.split('/').last;
    } else {
      filename = cleanedPath;
    }

    // Use API proxy endpoint instead of direct storage URL to fix CORS
    return '$baseUrl/foto/$filename';
  }

  static Future<Map<String, String>> authHeaders(String? token) async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json', // paksa Laravel selalu balas JSON
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

  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await authHeaders(token),
      body: jsonEncode(body ?? {}),
    );
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;

    if (response.body.isEmpty) {
      body = null;
    } else {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        // Response bukan JSON — kemungkinan HTML error page dari server
        body = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    // Jika body adalah JSON dengan field 'message', pakai itu
    if (body is Map<String, dynamic> && body['message'] != null) {
      throw Exception(body['message'].toString());
    }

    // Jika body adalah String tapi bukan HTML, tampilkan langsung
    if (body is String && body.isNotEmpty && !body.trimLeft().startsWith('<')) {
      throw Exception(body);
    }

    // Body adalah HTML atau tidak bisa dibaca — jangan expose ke user
    // Log ke console untuk debugging, tampilkan pesan generik ke UI
    if (body is String && body.isNotEmpty) {
      // ignore: avoid_print
      debugPrint('[ApiService] Server returned HTML/non-JSON ($statusCode): ${body.substring(0, body.length.clamp(0, 300))}');
    }

    throw Exception('Terjadi kesalahan pada server (${statusCode}), silakan coba lagi.');
  }
}
