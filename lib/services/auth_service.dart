import '../models/user.dart';

class AuthService {
  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;

  static void login(AppUser user) {
    _currentUser = user;
  }

  static void logout() {
    _currentUser = null;
  }

  static bool isOwner() {
    return _currentUser?.role == UserRole.owner;
  }

  static bool isKaryawan() {
    return _currentUser?.role == UserRole.karyawan;
  }
}