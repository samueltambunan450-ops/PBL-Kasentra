/// Status kepala cabang per cabang.
/// - active  : ada kepala cabang dengan is_active = true
/// - pending : ada undangan valid tapi belum diklaim
/// - empty   : tidak ada sama sekali
enum HeadStatus { active, pending, empty }

class BranchStatus {
  final String id;
  final String namaCabang;
  final String alamat;
  final HeadStatus headStatus;
  final ActiveBranchHeadInfo? activeBranchHead;
  final PendingBranchHeadInfo? pendingBranchHead;
  final int totalBranchHeads;

  BranchStatus({
    required this.id,
    required this.namaCabang,
    required this.alamat,
    required this.headStatus,
    this.activeBranchHead,
    this.pendingBranchHead,
    required this.totalBranchHeads,
  });

  /// Shorthand untuk backward-compat di UI
  bool get hasActiveHead => headStatus == HeadStatus.active;
  bool get hasPendingHead => headStatus == HeadStatus.pending;
  bool get isEmpty => headStatus == HeadStatus.empty;

  factory BranchStatus.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['head_status'] ?? '').toString();
    final headStatus = switch (statusStr) {
      'active'  => HeadStatus.active,
      'pending' => HeadStatus.pending,
      _         => HeadStatus.empty,
    };

    return BranchStatus(
      id: json['id'].toString(),
      namaCabang: (json['nama_cabang'] ?? '').toString(),
      alamat: (json['alamat'] ?? '').toString(),
      headStatus: headStatus,
      activeBranchHead: json['active_branch_head'] != null
          ? ActiveBranchHeadInfo.fromJson(
              json['active_branch_head'] as Map<String, dynamic>)
          : null,
      pendingBranchHead: json['pending_branch_head'] != null
          ? PendingBranchHeadInfo.fromJson(
              json['pending_branch_head'] as Map<String, dynamic>)
          : null,
      totalBranchHeads:
          int.tryParse(json['total_branch_heads'].toString()) ?? 0,
    );
  }
}

class ActiveBranchHeadInfo {
  final String id;
  final String nama;
  final String noHp;
  final String? userId;

  ActiveBranchHeadInfo({
    required this.id,
    required this.nama,
    required this.noHp,
    this.userId,
  });

  factory ActiveBranchHeadInfo.fromJson(Map<String, dynamic> json) {
    return ActiveBranchHeadInfo(
      id: json['id'].toString(),
      nama: (json['nama'] ?? '').toString(),
      noHp: (json['no_hp'] ?? '').toString(),
      userId: json['user_id']?.toString(),
    );
  }
}

class PendingBranchHeadInfo {
  final String id;
  final String nama;
  final String noHp;
  final String? invitationCode;
  final String? expiresAt;

  PendingBranchHeadInfo({
    required this.id,
    required this.nama,
    required this.noHp,
    this.invitationCode,
    this.expiresAt,
  });

  factory PendingBranchHeadInfo.fromJson(Map<String, dynamic> json) {
    return PendingBranchHeadInfo(
      id: json['id'].toString(),
      nama: (json['nama'] ?? '').toString(),
      noHp: (json['no_hp'] ?? '').toString(),
      invitationCode: json['invitation_code']?.toString(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}
