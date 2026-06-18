import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../models/cabang.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';

class KelolKepalaCabangPage extends StatefulWidget {
  const KelolKepalaCabangPage({super.key});

  @override
  State<KelolKepalaCabangPage> createState() => _KelolKepalaCabangPageState();
}

class _KelolKepalaCabangPageState extends State<KelolKepalaCabangPage> {
  List<AppUser> _kepalaCabangs = [];
  List<Cabang> _cabangs = [];
  String? selectedCabangId;
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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final kepalaCabangs = await DomainApiService.fetchKepalaCabangs();
      final cabangs = await DomainApiService.fetchCabangs();
      if (!mounted) return;
      setState(() {
        _kepalaCabangs = kepalaCabangs;
        _cabangs = cabangs;
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

  Future<void> _generateInvitation() async {
    if (selectedCabangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih cabang sebelum membuat kode undangan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final code = await DomainApiService.generateInvitation(
        cabangId: selectedCabangId!,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: primaryGreenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                const Text(
                  'Kode Undangan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bagikan kode ini ke kepala cabang',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // Kode box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: primaryGreenSoft,
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Salin button
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kode berhasil disalin!'),
                        backgroundColor: successColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: primaryGreen),
                  label: const Text(
                    'Salin Kode',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tutup button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: surfaceWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat kode undangan: $e'),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  Future<void> _deleteKepalaCabang(AppUser u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
          orElse: () => Cabang(
            id: '',
            nama: 'Tidak Ditemukan',
            alamat: '',
            modalAwal: 0,
          ),
        )
        .nama;
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(
        body: Center(
          child: Text('Anda tidak bisa mengakses halaman ini.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Kelola Kepala Cabang',
          style: TextStyle(
            color: surfaceWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
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
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section Buat Kode Undangan ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryGreenSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: primaryGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Buat Kode Undangan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.only(left: 46),
                            child: Text(
                              'Kirim kode ke kepala cabang untuk bergabung',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dropdown cabang
                          DropdownButtonFormField<String>(
                            value: selectedCabangId,
                            decoration: InputDecoration(
                              labelText: 'Pilih Cabang',
                              prefixIcon: const Icon(
                                Icons.store_outlined,
                                color: primaryGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: backgroundGrey,
                            ),
                            items: _cabangs
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.nama),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedCabangId = v),
                          ),
                          const SizedBox(height: 12),
                          // Button buat kode
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _generateInvitation,
                              icon: const Icon(
                                  Icons.confirmation_number_outlined),
                              label: const Text('Buat Kode Undangan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: surfaceWhite,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section Daftar Kepala Cabang ──
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
                        // Badge jumlah
                        if (_kepalaCabangs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
                              decoration: BoxDecoration(
                                color: backgroundGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.people_outline,
                                size: 32,
                                color: textTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada kepala cabang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Buat kode undangan untuk menambahkan\nkepala cabang baru',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: textTertiary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: primaryGreen,
                              ),
                              label: const Text(
                                'Muat Ulang',
                                style: TextStyle(color: primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      )
                    // List kepala cabang
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kepalaCabangs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final u = _kepalaCabangs[index];
                          final inisial = u.nama.isNotEmpty
                              ? u.nama[0].toUpperCase()
                              : '?';
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
                                // Avatar inisial
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
                                // Info nama + cabang + email
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          const Icon(
                                            Icons.store_outlined,
                                            size: 12,
                                            color: textTertiary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            cabangNama,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (u.email != null &&
                                          u.email!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.email_outlined,
                                              size: 12,
                                              color: textTertiary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                u.email!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: textSecondary,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Badge + delete
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryGreenSoft,
                                        borderRadius:
                                            BorderRadius.circular(20),
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
                                      onTap: () =>
                                          _deleteKepalaCabang(u),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: dangerColor,
                                          size: 20,
                                        ),
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