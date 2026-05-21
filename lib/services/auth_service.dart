import '../models/user.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static AppUser? _currentUser;
  static String? _token;
  static const _tokenKey = 'kasentra_api_token';

  static AppUser? get currentUser => _currentUser;
  static String? get token => _token;

  static Future<void> hydrateSession() async {
    final pref = await SharedPreferences.getInstance();
    _token = pref.getString(_tokenKey);
    if (_token == null || _token!.isEmpty) return;
    try {
      final payload = await ApiService.get('/auth/me', token: _token) as Map<String, dynamic>;
      final map = payload['user'] as Map<String, dynamic>;
      _currentUser = _mapUser(map);
    } catch (_) {
      await signOut();
    }
  }

  static Future<bool> signInWithGoogle() async {
    // Bypass Google/Firebase login for development testing of CRUD.
    // Ini hanya sementara — akan dikembalikan ke implementasi asli nanti.
    final demoUser = AppUser(
      id: '1',
      nama: 'Owner Demo',
      email: 'owner@kasentra.test',
      googleId: 'bypass-owner',
      role: UserRole.owner,
      cabangId: null,
    );

    _currentUser = demoUser;
    _token = null;
    return true;
  }

  static Future<void> signOut() async {
    try {
      if (_token != null) {
        await ApiService.post('/auth/logout', token: _token);
      }
    } catch (_) {}
    await GoogleSignIn().signOut();
    if (!kIsWeb) {
      await FirebaseAuth.instance.signOut();
    }
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_tokenKey);
    _currentUser = null;
    _token = null;
  }

  static bool isOwner() {
    return _currentUser?.role == UserRole.owner;
  }

  static bool isKaryawan() {
    return _currentUser?.role == UserRole.karyawan;
  }

  static AppUser _mapUser(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'].toString(),
      nama: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      googleId: (map['google_uid'] ?? '').toString(),
      role: (map['role'] == 'owner') ? UserRole.owner : UserRole.karyawan,
      cabangId: map['cabang_id']?.toString(),
    );
  }
}