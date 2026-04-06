import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/cabang.dart';

class ManageKaryawanPage extends StatefulWidget {
  const ManageKaryawanPage({super.key});

  @override
  State<ManageKaryawanPage> createState() => _ManageKaryawanPageState();
}

class _ManageKaryawanPageState extends State<ManageKaryawanPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passwordC = TextEditingController();

  final repo = UserRepository.instance;
  final cabangRepo = CabangRepository.instance;

  AppUser? _editing; // jika bukan null berarti sedang mengedit
  String? selectedCabangId;

  void _saveKaryawan() {
    if (namaC.text.isEmpty ||
        emailC.text.isEmpty ||
        passwordC.text.isEmpty ||
        selectedCabangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data karyawan"),
        ),
      );
      return;
    }

    if (_editing == null) {
      repo.addKaryawan(
        nama: namaC.text.trim(),
        email: emailC.text.trim(),
        password: passwordC.text.trim(),
        cabangId: selectedCabangId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Karyawan berhasil ditambahkan"),
        ),
      );
    } else {
      repo.updateKaryawan(
        _editing!.id,
        nama: namaC.text.trim(),
        email: emailC.text.trim(),
        password: passwordC.text.trim(),
        cabangId: selectedCabangId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Karyawan berhasil diperbarui"),
        ),
      );
      _editing = null;
    }

    setState(() {
      namaC.clear();
      emailC.clear();
      passwordC.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final karyawans = repo.karyawans;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Karyawan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing == null ? "Tambah Karyawan" : "Edit Karyawan",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
            TextField(
              controller: passwordC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
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
              items: cabangRepo.cabangs.map((cabang) {
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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveKaryawan,
                child: Text(_editing == null ? "Simpan Karyawan" : "Perbarui Karyawan"),
              ),
            ),
            if (_editing != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _editing = null;
                      namaC.clear();
                      emailC.clear();
                      passwordC.clear();
                      selectedCabangId = null;
                    });
                  },
                  child: const Text("Batal"),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              "Daftar Karyawan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: karyawans.isEmpty
                  ? const Center(
                      child: Text("Belum ada karyawan"),
                    )
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
                          final cabang = cabangRepo.cabangs.firstWhere(
                            (c) => c.id == u.cabangId,
                            orElse: () => Cabang(id: '', nama: 'Tidak Ditemukan', alamat: '', modalAwal: 0),
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
                                      icon: const Icon(Icons.edit, color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          _editing = u;
                                          namaC.text = u.nama;
                                          emailC.text = u.email;
                                          passwordC.text = u.password;
                                          selectedCabangId = u.cabangId;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Hapus karyawan"),
                                            content: Text("Yakin ingin menghapus ${u.nama}?"),
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
                                          repo.deleteKaryawan(u.id);
                                          if (_editing?.id == u.id) {
                                            _editing = null;
                                            namaC.clear();
                                            emailC.clear();
                                            passwordC.clear();
                                            selectedCabangId = null;
                                          }
                                          setState(() {});
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


