enum UserRole { owner, karyawan, pending }

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
      id: map['id'].toString(),
      nama: (map['name'] ?? map['nama'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      googleId: (map['google_uid'] ?? map['googleId'] ?? '').toString(),
      role: _parseRole(map['role']),
      cabangId: map['cabang_id']?.toString() ?? map['cabangId']?.toString(),
    );
  }

  static UserRole _parseRole(dynamic value) {
    final role = value?.toString().toLowerCase();
    if (role == 'owner') return UserRole.owner;
    if (role == 'karyawan') return UserRole.karyawan;
    return UserRole.pending;
  }

  // Method untuk mengubah AppUser ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'googleId': googleId,
      'role': role.name,
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




