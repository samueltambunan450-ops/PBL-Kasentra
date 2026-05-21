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




