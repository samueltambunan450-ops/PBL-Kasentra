class BranchHead {
  final String id;
  final String branchId;
  final String? userId;
  final String nama;
  final String noHp;
  final bool isActive;
  final String? branchName;
  final String? userEmail;
  final InvitationInfo? invitation;

  BranchHead({
    required this.id,
    required this.branchId,
    this.userId,
    required this.nama,
    required this.noHp,
    required this.isActive,
    this.branchName,
    this.userEmail,
    this.invitation,
  });

  factory BranchHead.fromJson(Map<String, dynamic> json) {
    return BranchHead(
      id: json['id'].toString(),
      branchId: json['branch_id'].toString(),
      userId: json['user_id']?.toString(),
      nama: (json['nama'] ?? '').toString(),
      noHp: (json['no_hp'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      branchName: json['branch_name']?.toString(),
      userEmail: json['user_email']?.toString(),
      invitation: json['invitation'] != null
          ? InvitationInfo.fromJson(json['invitation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'user_id': userId,
      'nama': nama,
      'no_hp': noHp,
      'is_active': isActive,
    };
  }

  BranchHead copyWith({
    String? id,
    String? branchId,
    String? userId,
    String? nama,
    String? noHp,
    bool? isActive,
    String? branchName,
    String? userEmail,
    InvitationInfo? invitation,
  }) {
    return BranchHead(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      noHp: noHp ?? this.noHp,
      isActive: isActive ?? this.isActive,
      branchName: branchName ?? this.branchName,
      userEmail: userEmail ?? this.userEmail,
      invitation: invitation ?? this.invitation,
    );
  }
}

class InvitationInfo {
  final String code;
  final DateTime? expiresAt;
  final bool isUsed;
  final bool isExpired;

  InvitationInfo({
    required this.code,
    this.expiresAt,
    required this.isUsed,
    required this.isExpired,
  });

  factory InvitationInfo.fromJson(Map<String, dynamic> json) {
    return InvitationInfo(
      code: (json['code'] ?? '').toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      isUsed: json['is_used'] == true,
      isExpired: json['is_expired'] == true,
    );
  }

  bool get isValid => !isUsed && !isExpired;
}
