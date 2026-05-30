import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/cabang.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';

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

  AppUser? _editing; // jika bukan null berarti sedang mengedit
  String? selectedCabangId;

  @override
  void initState() {
    super.initState();
    if (!AuthService.isOwner()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
        ).then((_) => Navigator.of(context).pop());
      });
    }
    _loadData();
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
          content: Text('Bagikan kode ini ke karyawan: $code'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat kode undangan: $e'),
          backgroundColor: Colors.red,
        ),
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
          const SnackBar(
            content: Text("Karyawan berhasil ditambahkan"),
            backgroundColor: Colors.green,
          ),
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
          const SnackBar(
            content: Text("Karyawan berhasil diperbarui"),
            backgroundColor: Colors.green,
          ),
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
        SnackBar(
          content: Text("Gagal menyimpan karyawan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(
        body: Center(child: Text('Anda tidak bisa mengakses halaman ini.')),
      );
    }

    final karyawans = _karyawans;

    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Karyawan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing == null ? "Tambah Karyawan" : "Edit Karyawan",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: namaC,
              decoration: const InputDecoration(
                labelText: "Nama",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailC,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCabangId,
              decoration: const InputDecoration(
                labelText: "Cabang",
                border: OutlineInputBorder(),
              ),
              items: _cabangs.map((cabang) {
                return DropdownMenuItem<String>(
                  value: cabang.id,
                  child: Text(cabang.nama),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCabangId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saveKaryawan,
                    child: Text(
                      _editing == null ? "Simpan Karyawan" : "Perbarui Karyawan",
                    ),
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
            ),
            if (_editing != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _editing = null;
                      namaC.clear();
                      emailC.clear();
                      selectedCabangId = null;
                    });
                  },
                  child: const Text("Batal"),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              "Daftar Karyawan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: karyawans.isEmpty
                  ? const Center(child: Text("Belum ada karyawan"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nama')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Cabang')),
                          DataColumn(label: Text('Aksi')),
                        ],
                        rows: karyawans.map((u) {
                          final cabang = _cabangs.firstWhere(
                            (c) => c.id == u.cabangId,
                            orElse: () => Cabang(
                              id: '',
                              nama: 'Tidak Ditemukan',
                              alamat: '',
                              modalAwal: 0,
                            ),
                          );
                          return DataRow(
                            cells: [
                              DataCell(Text(u.nama)),
                              DataCell(Text(u.email)),
                              DataCell(Text(cabang.nama)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _editing = u;
                                          namaC.text = u.nama;
                                          emailC.text = u.email;
                                          selectedCabangId = u.cabangId;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Hapus karyawan"),
                                            content: Text(
                                              "Yakin ingin menghapus ${u.nama}?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Batal"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text("Hapus"),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          try {
                                            await DomainApiService.deleteKaryawan(u.id);
                                            if (_editing?.id == u.id) {
                                              _editing = null;
                                              if (mounted) {
                                                namaC.clear();
                                                emailC.clear();
                                                selectedCabangId = null;
                                              }
                                            }
                                            await _loadData();
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Karyawan berhasil dihapus"),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Gagal menghapus karyawan: $e"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
