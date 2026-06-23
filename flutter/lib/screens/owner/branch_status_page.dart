import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/branch_status.dart';
import '../../models/cabang.dart';
import '../../models/user.dart';
import '../../services/domain_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'invite_branch_head_page.dart';

/// Menampilkan status kepala cabang per cabang milik sebuah bisnis.
/// Nama class SENGAJA tidak diubah untuk menghindari konflik import.
/// Title yang tampil ke user: "Kelola Kepala Cabang".
class BranchStatusPage extends StatefulWidget {
  final AppUser user;
  final String businessId;
  final String businessName;

  const BranchStatusPage({
    super.key,
    required this.user,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BranchStatusPage> createState() => _BranchStatusPageState();
}

class _BranchStatusPageState extends State<BranchStatusPage> {
  List<BranchStatus> _statuses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final statuses = await DomainApiService.fetchBranchStatus(widget.businessId);
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openInvitePage(BranchStatus status) async {
    final cabang = Cabang(
      id: status.id,
      nama: status.namaCabang,
      alamat: status.alamat,
      modalAwal: 0,
    );
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InviteBranchHeadPage(cabang: cabang),
      ),
    );
    // Refresh setelah kembali jika generate kode berhasil
    if (result == true && mounted) _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        // ↓ Teks yang tampil ke user diubah, nama class TETAP BranchStatusPage
        title: const Text('Kelola Kepala Cabang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadStatus,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadStatus, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_statuses.isEmpty) {
      return const Center(child: Text('Belum ada cabang.'));
    }

    return RefreshIndicator(
      onRefresh: _loadStatus,
      child: ListView.builder(
        padding: Responsive.pagePadding(context).copyWith(top: 8),
        itemCount: _statuses.length,
        itemBuilder: (context, index) => _BranchStatusCard(
          status: _statuses[index],
          onInvite: () => _openInvitePage(_statuses[index]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BranchStatusCard extends StatelessWidget {
  final BranchStatus status;
  final VoidCallback onInvite;

  const _BranchStatusCard({required this.status, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nama cabang + badge status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.namaCabang,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (status.alamat.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        status.alamat,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(headStatus: status.headStatus),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Konten sesuai status
          switch (status.headStatus) {
            HeadStatus.active => _ActiveHeadRow(
                info: status.activeBranchHead!,
                onReplace: onInvite,
              ),
            HeadStatus.pending => _PendingHeadRow(
                info: status.pendingBranchHead!,
                onResend: onInvite,
              ),
            HeadStatus.empty => _EmptyHeadRow(onInvite: onInvite),
          },
        ],
      ),
    );
  }
}

// ── Baris: kepala cabang aktif ───────────────────────────────────────────────
class _ActiveHeadRow extends StatelessWidget {
  final ActiveBranchHeadInfo info;
  final VoidCallback onReplace;

  const _ActiveHeadRow({required this.info, required this.onReplace});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.person, color: Colors.green, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                info.noHp,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onReplace,
          icon: const Icon(Icons.person_add_outlined, size: 16),
          label: const Text('Ganti', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ── Baris: undangan pending (belum diklaim) ──────────────────────────────────
class _PendingHeadRow extends StatelessWidget {
  final PendingBranchHeadInfo info;
  final VoidCallback onResend;

  const _PendingHeadRow({required this.info, required this.onResend});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFF8E1),
              child: Icon(Icons.hourglass_top_outlined, color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.nama,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Menunggu konfirmasi',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            // Tombol salin ulang kode
            if (info.invitationCode != null)
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.primary),
                tooltip: 'Salin kode undangan',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: info.invitationCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kode ${info.invitationCode} disalin'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
          ],
        ),
        if (info.invitationCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.vpn_key_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  info.invitationCode!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.primaryDark,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onResend,
            icon: const Icon(Icons.send_outlined, size: 15),
            label: const Text('Kirim Undangan Baru', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Baris: belum ada kepala cabang ───────────────────────────────────────────
class _EmptyHeadRow extends StatelessWidget {
  final VoidCallback onInvite;
  const _EmptyHeadRow({required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.person_off_outlined, color: Colors.orange, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Belum ada kepala cabang',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
          ),
        ),
        FilledButton.tonal(
          onPressed: onInvite,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Undang', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

// ── Badge status ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final HeadStatus headStatus;
  const _StatusBadge({required this.headStatus});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bgColor, textColor) = switch (headStatus) {
      HeadStatus.active  => ('Aktif',   Icons.check_circle,       const Color(0xFFE8F5E9), Colors.green.shade700),
      HeadStatus.pending => ('Pending', Icons.hourglass_top,      const Color(0xFFFFF8E1), Colors.orange.shade700),
      HeadStatus.empty   => ('Kosong',  Icons.radio_button_unchecked, const Color(0xFFFFF3E0), Colors.orange.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
