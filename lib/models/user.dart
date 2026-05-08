enum UserRole { owner, karyawan }

class AppUser {
  final String id;
  final String nama;
  final String email;
  final String googleId;
  final UserRole role;
  final String? cabangId; // ID cabang tempat karyawan bekerja (null untuk owner)

  AppUser({
    required this.id,
    required this.nama,
    required this.email,
    required this.googleId,
    required this.role,
    this.cabangId,
  });

  // Factory untuk membuat AppUser dari Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      nama: map['nama'],
      email: map['email'],
      googleId: map['googleId'],
      role: UserRole.values[map['role']],
      cabangId: map['cabangId'],
    );
  }

  // Method untuk mengubah AppUser ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'googleId': googleId,
      'role': role.index,
      'cabangId': cabangId,
    };
  }

  // CopyWith untuk update
  AppUser copyWith({
    String? id,
    String? nama,
    String? email,
    String? googleId,
    UserRole? role,
    String? cabangId,
  }) {
    return AppUser(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      googleId: googleId ?? this.googleId,
      role: role ?? this.role,
      cabangId: cabangId ?? this.cabangId,
    );
  }

  String get username {
    final beforeAt = email.split('@').first.trim();
    if (beforeAt.isNotEmpty) return beforeAt.toLowerCase();
    return nama.trim().toLowerCase().replaceAll(' ', '');
  }
}

/// Repository sederhana di memori untuk menyimpan akun pengguna.
/// Digunakan oleh halaman login dan halaman kelola karyawan.
class UserRepository {
  UserRepository._internal();

  static final UserRepository instance = UserRepository._internal();

  final List<AppUser> _users = [
    AppUser(
      id: '1',
      nama: 'Owner Utama',
      email: 'owner@kasentra.com',
      googleId: 'owner123',
      role: UserRole.owner,
      cabangId: null, // Owner tidak terikat cabang
    ),
    AppUser(
      id: '2',
      nama: 'Karyawan Demo',
      email: 'staff@kasentra.com',
      googleId: 'staff123',
      role: UserRole.karyawan,
      cabangId: '1', // Contoh cabang ID
    ),
  ];

  List<AppUser> get users => List.unmodifiable(_users);

  List<AppUser> get karyawans =>
      _users.where((u) => u.role == UserRole.karyawan).toList();

  void addUser({
    required String nama,
    required String email,
    required String googleId,
    required UserRole role,
    String? cabangId,
  }) {
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      email: email,
      googleId: googleId,
      role: role,
      cabangId: cabangId,
    );
    _users.add(newUser);
  }

  /// memperbarui data karyawan yang sudah ada
  void updateKaryawan(String id, {
    required String nama,
    required String email,
    required String googleId,
    required String cabangId,
  }) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return;

    _users[index] = AppUser(
      id: id,
      nama: nama,
      email: email,
      googleId: googleId,
      role: UserRole.karyawan,
      cabangId: cabangId,
    );
  }

  /// menghapus karyawan berdasarkan id
  void deleteKaryawan(String id) {
    _users.removeWhere((u) => u.id == id);
  }
}


