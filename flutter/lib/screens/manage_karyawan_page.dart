import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/cabang.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import 'owner/branch_status_page.dart';

class KelolKepalaCabangPage extends StatefulWidget {
  const KelolKepalaCabangPage({super.key});

  @override
  State<KelolKepalaCabangPage> createState() => _KelolKepalaCabangPageState();
}

class _KelolKepalaCabangPageState extends State<KelolKepalaCabangPage> {
  List<AppUser> _kepalaCabangs = [];
  List<Cabang> _cabangs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!AuthService.isOwner()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Akses Ditolak'),
            content: const Text('Anda tidak bisa mengakses halaman ini.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      });
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DomainApiService.fetchKepalaCabangs(),
        DomainApiService.fetchCabangs(),
      ]);
      if (!mounted) return;
      setState(() {
        _kepalaCabangs = results[0] as List<AppUser>;
        _cabangs = results[1] as List<Cabang>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  Future<void> _deleteKepalaCabang(AppUser u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kepala Cabang'),
        content: Text('Yakin ingin menghapus ${u.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: dangerColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DomainApiService.deleteKepalaCabang(u.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kepala cabang berhasil dihapus'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  String _cabangName(String? cabangId) {
    return _cabangs
        .firstWhere(
          (c) => c.id == cabangId,
          orElse: () => Cabang(id: '', nama: 'Tidak Ditemukan', alamat: '', modalAwal: 0),
        )
        .nama;
  }

  void _openKelolaBranchStatus() {
    // Ambil business_id dari cabang yang ada
    final bizId = _cabangs
        .firstWhere(
          (c) => c.businessId != null && c.businessId!.isNotEmpty,
          orElse: () => Cabang(id: '', nama: '', alamat: '', modalAwal: 0),
        )
        .businessId;

    if (bizId == null || bizId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cabang belum terhubung ke usaha. Pastikan sudah setup usaha terlebih dahulu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchStatusPage(
          user: AuthService.currentUser!,
          businessId: bizId,
          businessName: 'Usaha Saya',
        ),
      ),
    ).then((_) => _loadData()); // refresh list setelah kembali
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(
        body: Center(child: Text('Anda tidak bisa mengakses halaman ini.')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Kelola Kepala Cabang',
          style: TextStyle(color: surfaceWhite, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: surfaceWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: surfaceWhite),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: surfaceWhite),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tombol navigasi ke Kelola Kepala Cabang ──────────────
                    InkWell(
                      onTap: _openKelolaBranchStatus,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primaryGreenSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.supervisor_account_outlined,
                                color: primaryGreen,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kelola Kepala Cabang',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Undang, ganti, dan pantau status per cabang',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: textTertiary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Daftar Kepala Cabang ──────────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Daftar Kepala Cabang',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_kepalaCabangs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryGreenSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_kepalaCabangs.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Empty state
                    if (_kepalaCabangs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: backgroundGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.people_outline, size: 32, color: textTertiary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada kepala cabang aktif',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Undang kepala cabang lewat menu\n"Kelola Kepala Cabang" di atas',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: textTertiary),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh, size: 16, color: primaryGreen),
                              label: const Text('Muat Ulang', style: TextStyle(color: primaryGreen)),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kepalaCabangs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final u = _kepalaCabangs[index];
                          final inisial = u.nama.isNotEmpty ? u.nama[0].toUpperCase() : '?';
                          final cabangNama = _cabangName(u.cabangId);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: cardShadow,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primaryGreen,
                                  child: Text(
                                    inisial,
                                    style: const TextStyle(
                                      color: surfaceWhite,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.nama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.store_outlined, size: 12, color: textTertiary),
                                          const SizedBox(width: 4),
                                          Text(
                                            cabangNama,
                                            style: const TextStyle(fontSize: 12, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                      if (u.email.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 12, color: textTertiary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                u.email,
                                                style: const TextStyle(fontSize: 11, color: textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryGreenSoft,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Aktif',
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _deleteKepalaCabang(u),
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline, color: dangerColor, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
