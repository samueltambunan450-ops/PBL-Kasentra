import 'package:flutter/material.dart';

import '../models/kategori.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';

class ManageKategoriPage extends StatefulWidget {
  const ManageKategoriPage({super.key});

  @override
  State<ManageKategoriPage> createState() => _ManageKategoriPageState();
}

class _ManageKategoriPageState extends State<ManageKategoriPage> {
  final namaC = TextEditingController();
  KategoriType tipe = KategoriType.pengeluaran;
  Kategori? _editing;

  List<Kategori> _kategoris = [];

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
    _loadKategoris();
  }

  Future<void> _loadKategoris() async {
    final data = await DomainApiService.fetchKategoris();
    if (!mounted) return;
    setState(() => _kategoris = data);
  }

  Future<void> _save() async {
    if (namaC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori wajib diisi')),
      );
      return;
    }
    final nama = namaC.text.trim();
    if (_editing == null) {
      await ApiService.post('/kategoris', token: AuthService.token, body: {
        'nama': nama,
        'tipe': tipe == KategoriType.pemasukan ? 'pemasukan' : 'pengeluaran',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil ditambahkan')),
      );
    } else {
      await ApiService.put('/kategoris/${_editing!.id}', token: AuthService.token, body: {
        'nama': nama,
        'tipe': tipe == KategoriType.pemasukan ? 'pemasukan' : 'pengeluaran',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil diperbarui')),
      );
      _editing = null;
    }
    setState(() {
      namaC.clear();
    });
    await _loadKategoris();
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

    final cats = _kategoris;
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing == null ? 'Tambah Kategori' : 'Edit Kategori',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: namaC,
                    decoration: const InputDecoration(
                      labelText: 'Nama kategori',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<KategoriType>(
                  value: tipe,
                  items: const [
                    DropdownMenuItem(
                        value: KategoriType.pemasukan, child: Text('Pemasukan')),
                    DropdownMenuItem(
                        value: KategoriType.pengeluaran,
                        child: Text('Pengeluaran')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => tipe = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_editing == null ? 'Simpan' : 'Perbarui'),
              ),
            ),
            if (_editing != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _editing = null;
                      namaC.clear();
                    });
                  },
                  child: const Text('Batal'),
                ),
              ),
            const Divider(height: 32),
            const Text(
              'Daftar kategori',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: cats.isEmpty
                  ? const Center(child: Text('Belum ada kategori'))
                  : ListView.builder(
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        final k = cats[index];
                        return ListTile(
                          title: Text(k.nama),
                          subtitle: Text(k.tipe == KategoriType.pemasukan
                              ? 'Pemasukan'
                              : 'Pengeluaran'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _editing = k;
                                    namaC.text = k.nama;
                                    tipe = k.tipe;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                            title: const Text('Hapus kategori'),
                                            content: Text(
                                                'Yakin ingin menghapus kategori "${k.nama}"?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, false),
                                                  child: const Text('Batal')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, true),
                                                  child: const Text('Hapus')),
                                            ],
                                          ));
                                  if (confirmed == true) {
                                    await ApiService.delete('/kategoris/${k.id}', token: AuthService.token);
                                    if (_editing?.id == k.id) {
                                      _editing = null;
                                      namaC.clear();
                                    }
                                    await _loadKategoris();
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
