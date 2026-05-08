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
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication;
    // Di web, Firebase sering butuh konfigurasi tambahan (firebase_options.dart / web config).
    // Agar tidak crash, untuk web kita gunakan idToken dari Google Sign-In langsung.
    if (kIsWeb) {
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('idToken Google tidak tersedia. Pastikan konfigurasi Google Sign-In di web.');
      }

      final payload =
          await ApiService.post('/auth/google', body: {'id_token': idToken})
              as Map<String, dynamic>;
      final token = payload['token'] as String?;
      final user = payload['user'] as Map<String, dynamic>?;
      if (token == null || user == null) return false;

      _token = token;
      _currentUser = _mapUser(user);
      final pref = await SharedPreferences.getInstance();
      await pref.setString(_tokenKey, token);
      return true;
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Gagal mendapatkan token Firebase');
    }

    final payload = await ApiService.post(
      '/auth/google',
      body: {'id_token': idToken},
    ) as Map<String, dynamic>;
    final token = payload['token'] as String?;
    final user = payload['user'] as Map<String, dynamic>?;
    if (token == null || user == null) return false;

    _token = token;
    _currentUser = _mapUser(user);
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_tokenKey, token);
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