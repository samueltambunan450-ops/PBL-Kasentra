enum UserRole { owner, karyawan }

class AppUser {
  final String id;
  final String nama;
  final String email;
  final String password;
  final UserRole role;
  final String? cabangId; // ID cabang tempat karyawan bekerja (null untuk owner)

  AppUser({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
    this.cabangId,
  });

  // Factory untuk membuat AppUser dari Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
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
      'password': password,
      'role': role.index,
      'cabangId': cabangId,
    };
  }

  // CopyWith untuk update
  AppUser copyWith({
    String? id,
    String? nama,
    String? email,
    String? password,
    UserRole? role,
    String? cabangId,
  }) {
    return AppUser(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      cabangId: cabangId ?? this.cabangId,
    );
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
      email: 'owner@.com',
      password: 'owner123',
      role: UserRole.owner,
      cabangId: null, // Owner tidak terikat cabang
    ),
    AppUser(
      id: '2',
      nama: 'Karyawan Demo',
      email: 'staff.com',
      password: 'staff123',
      role: UserRole.karyawan,
      cabangId: '1', // Contoh cabang ID
    ),
  ];

  List<AppUser> get users => List.unmodifiable(_users);

  List<AppUser> get karyawans =>
      _users.where((u) => u.role == UserRole.karyawan).toList();

  void addKaryawan({
    required String nama,
    required String email,
    required String password,
    required String cabangId,
  }) {
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      email: email,
      password: password,
      role: UserRole.karyawan,
      cabangId: cabangId,
    );
    _users.add(newUser);
  }

  /// memperbarui data karyawan yang sudah ada
  void updateKaryawan(String id, {
    required String nama,
    required String email,
    required String password,
    required String cabangId,
  }) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return;

    _users[index] = AppUser(
      id: id,
      nama: nama,
      email: email,
      password: password,
      role: UserRole.karyawan,
      cabangId: cabangId,
    );
  }

  /// menghapus karyawan berdasarkan id
  void deleteKaryawan(String id) {
    _users.removeWhere((u) => u.id == id);
  }
}


