import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/cabang.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/manage_page_layout.dart';

class ManageKaryawanPage extends StatefulWidget {
  const ManageKaryawanPage({super.key});

  @override
  State<ManageKaryawanPage> createState() => _ManageKaryawanPageState();
}

class _ManageKaryawanPageState extends State<ManageKaryawanPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController emailC = TextEditingController();

  List<AppUser> _karyawans = [];
  List<Cabang> _cabangs = [];
  AppUser? _editing;
  String? selectedCabangId;

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
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
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
    namaC.dispose();
    emailC.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await DomainApiService.fetchKaryawans();
    final cabang = await DomainApiService.fetchCabangs();
    if (!mounted) return;
    setState(() {
      _karyawans = data;
      _cabangs = cabang;
    });
  }

  Future<void> _generateInvitation() async {
    if (selectedCabangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih cabang sebelum membuat kode undangan.')),
      );
      return;
    }

    try {
      final code = await DomainApiService.generateInvitation(cabangId: selectedCabangId!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kode Undangan Dihasilkan'),
          content: SelectableText('Bagikan kode ini ke karyawan:\n\n$code'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat kode undangan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveKaryawan() async {
    if (namaC.text.isEmpty || emailC.text.isEmpty || selectedCabangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data karyawan")),
      );
      return;
    }

    try {
      if (_editing == null) {
        await DomainApiService.createKaryawan(
          nama: namaC.text.trim(),
          email: emailC.text.trim(),
          cabangId: selectedCabangId!,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Karyawan berhasil ditambahkan"), backgroundColor: Colors.green),
        );
      } else {
        await DomainApiService.updateKaryawan(
          _editing!.id,
          nama: namaC.text.trim(),
          email: emailC.text.trim(),
          cabangId: selectedCabangId!,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Karyawan berhasil diperbarui"), backgroundColor: Colors.green),
        );
        _editing = null;
      }

      if (mounted) {
        setState(() {
          namaC.clear();
          emailC.clear();
        });
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan karyawan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _startEdit(AppUser u) {
    setState(() {
      _editing = u;
      namaC.text = u.nama;
      emailC.text = u.email;
      selectedCabangId = u.cabangId;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      namaC.clear();
      emailC.clear();
      selectedCabangId = null;
    });
  }

  Future<void> _deleteKaryawan(AppUser u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus karyawan"),
        content: Text("Yakin ingin menghapus ${u.nama}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DomainApiService.deleteKaryawan(u.id);
      if (_editing?.id == u.id) _cancelEdit();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Karyawan berhasil dihapus"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus karyawan: $e"), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(body: Center(child: Text('Anda tidak bisa mengakses halaman ini.')));
    }

    final isWide = !Responsive.isMobile(context);

    return ManagePageLayout(
      title: 'Kelola Karyawan',
      listTitle: 'Daftar Karyawan',
      formSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing == null ? "Tambah Karyawan" : "Edit Karyawan",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              children: [
                Expanded(child: TextField(controller: namaC, decoration: const InputDecoration(labelText: "Nama"))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: emailC, decoration: const InputDecoration(labelText: "Email"))),
              ],
            )
          else ...[
            TextField(controller: namaC, decoration: const InputDecoration(labelText: "Nama")),
            const SizedBox(height: 12),
            TextField(controller: emailC, decoration: const InputDecoration(labelText: "Email")),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedCabangId,
            decoration: const InputDecoration(labelText: "Cabang"),
            items: _cabangs
                .map((cabang) => DropdownMenuItem(value: cabang.id, child: Text(cabang.nama)))
                .toList(),
            onChanged: (value) => setState(() => selectedCabangId = value),
          ),
          const SizedBox(height: 16),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveKaryawan,
                        child: Text(_editing == null ? "Simpan Karyawan" : "Perbarui Karyawan"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _generateInvitation,
                        child: const Text('Buat Kode Undangan'),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveKaryawan,
                        child: Text(_editing == null ? "Simpan Karyawan" : "Perbarui Karyawan"),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _generateInvitation,
                        child: const Text('Buat Kode Undangan'),
                      ),
                    ),
                  ],
                ),
          if (_editing != null) ...[
            const SizedBox(height: 8),
            Center(child: TextButton(onPressed: _cancelEdit, child: const Text("Batal"))),
          ],
        ],
      ),
      listSection: _karyawans.isEmpty
          ? const Center(child: Text("Belum ada karyawan"))
          : ListView.separated(
              itemCount: _karyawans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final u = _karyawans[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Responsive.isMobile(context)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(u.email, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Cabang: ${_cabangName(u.cabangId)}', style: const TextStyle(color: AppColors.primary)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(onPressed: () => _startEdit(u), icon: const Icon(Icons.edit_outlined)),
                                IconButton(
                                  onPressed: () => _deleteKaryawan(u),
                                  icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(u.nama.isNotEmpty ? u.nama[0].toUpperCase() : '?'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(u.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  Text('Cabang: ${_cabangName(u.cabangId)}', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => _startEdit(u), icon: const Icon(Icons.edit_outlined)),
                            IconButton(
                              onPressed: () => _deleteKaryawan(u),
                              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
