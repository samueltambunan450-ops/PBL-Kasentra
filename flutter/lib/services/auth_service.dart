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
    try {
      String? googleId;
      String? email;
      String? name;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
        final user = userCredential.user;

        if (user == null) {
          return false;
        }

        UserInfo? googleProfile;
        if (user.providerData.isNotEmpty) {
          googleProfile = user.providerData.firstWhere(
            (p) => p.providerId == 'google.com',
            orElse: () => user.providerData.first,
          );
        }

        googleId = googleProfile?.uid ?? user.uid;
        email = user.email;
        name = user.displayName ?? '';
      } else {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        final account = await googleSignIn.signIn();
        if (account == null) {
          return false;
        }

        googleId = account.id;
        email = account.email;
        name = account.displayName ?? '';
      }

      if (googleId == null || googleId.isEmpty || email == null || email.isEmpty) {
        throw Exception('Google account information tidak lengkap');
      }

      final payload = await ApiService.post(
        '/auth/google',
        body: {
          'google_uid': googleId,
          'email': email,
          'name': name,
        },
      ) as Map<String, dynamic>;

      final token = payload['token']?.toString();
      final userMap = payload['user'] as Map<String, dynamic>?;
      if (token == null || userMap == null) {
        throw Exception('Response server tidak valid');
      }

      final user = AppUser.fromMap(userMap);
      await _setSession(token, user);
      return true;
    } catch (e) {
      throw Exception('Google Sign-In gagal: ${e.toString()}');
    }
  }

  static Future<void> _setSession(String token, AppUser user) async {
    _token = token;
    _currentUser = user;
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_tokenKey, token);
  }

  static Future<void> updateCurrentUser(AppUser user) async {
    _currentUser = user;
  }

  static Future<void> signOut() async {
    try {
      if (_token != null) {
        await ApiService.post('/auth/logout', token: _token);
      }
    } catch (_) {}
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
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
    return AppUser.fromMap(map);
  }
}