import 'package:flutter/material.dart';

import '../models/cabang.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';

class ManageCabangPage extends StatefulWidget {
  const ManageCabangPage({super.key});

  @override
  State<ManageCabangPage> createState() => _ManageCabangPageState();
}

class _ManageCabangPageState extends State<ManageCabangPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController alamatC = TextEditingController();
  final TextEditingController modalC = TextEditingController();

  List<Cabang> _cabangs = [];
  Cabang? _editing;

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
    _loadCabangs();
  }

  Future<void> _loadCabangs() async {
    final data = await DomainApiService.fetchCabangs();
    if (!mounted) return;
    setState(() => _cabangs = data);
  }

  Future<void> _saveCabang() async {
    if (namaC.text.isEmpty || alamatC.text.isEmpty || modalC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data cabang"),
        ),
      );
      return;
    }

    final modal = double.tryParse(modalC.text.replaceAll(',', '.')) ?? 0;

    if (_editing == null) {
      await ApiService.post(
        '/cabangs',
        token: AuthService.token,
        body: {
          'nama': namaC.text.trim(),
          'alamat': alamatC.text.trim(),
          'modal_awal': modal,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cabang berhasil ditambahkan"),
        ),
      );
    } else {
      await ApiService.put(
        '/cabangs/${_editing!.id}',
        token: AuthService.token,
        body: {
          'nama': namaC.text.trim(),
          'alamat': alamatC.text.trim(),
          'modal_awal': modal,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cabang berhasil diperbarui"),
        ),
      );
      _editing = null;
    }

    setState(() {
      namaC.clear();
      alamatC.clear();
      modalC.clear();
    });
    await _loadCabangs();
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

    final cabangs = _cabangs;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Cabang"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing == null ? "Tambah Cabang" : "Edit Cabang",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: namaC,
              decoration: const InputDecoration(
                labelText: "Nama Cabang",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: alamatC,
              decoration: const InputDecoration(
                labelText: "Alamat",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modalC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Modal Awal",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveCabang,
                child: Text(_editing == null ? "Simpan Cabang" : "Perbarui Cabang"),
              ),
            ),
            if (_editing != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _editing = null;
                      namaC.clear();
                      alamatC.clear();
                      modalC.clear();
                    });
                  },
                  child: const Text("Batal"),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              "Daftar Cabang",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: cabangs.isEmpty
                  ? const Center(
                      child: Text("Belum ada cabang"),
                    )
                  : ListView.builder(
                      itemCount: cabangs.length,
                      itemBuilder: (context, index) {
                        final c = cabangs[index];
                        return ListTile(
                          leading: const Icon(Icons.store),
                          title: Text(c.nama),
                          subtitle: Text(c.alamat),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _editing = c;
                                    namaC.text = c.nama;
                                    alamatC.text = c.alamat;
                                    modalC.text = c.modalAwal.toString();
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Hapus cabang"),
                                      content: Text("Yakin ingin menghapus ${c.nama}?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("Batal"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Hapus"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await ApiService.delete('/cabangs/${c.id}', token: AuthService.token);
                                    if (_editing?.id == c.id) {
                                      _editing = null;
                                      namaC.clear();
                                      alamatC.clear();
                                      modalC.clear();
                                    }
                                    await _loadCabangs();
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
