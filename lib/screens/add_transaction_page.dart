import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/kategori.dart';
import '../services/auth_service.dart';

class AddTransactionPage extends StatefulWidget {
  final void Function(Transaksi) onSaved;
  final Transaksi? transaksi; // jika tidak null berarti edit

  const AddTransactionPage({
    super.key,
    required this.onSaved,
    this.transaksi,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late bool _isEditing;
  TransaksiJenis jenis = TransaksiJenis.pemasukan;
  final TextEditingController nominalC = TextEditingController();
  final TextEditingController keteranganC = TextEditingController();
  String? kategori; // selected category for transaksi
  final kategoriRepo = KategoriRepository.instance;
  DateTime? tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaksi != null;
    if (_isEditing) {
      final t = widget.transaksi!;
      jenis = t.jenis;
      nominalC.text = t.nominal.toString();
      keteranganC.text = t.keterangan;
      kategori = t.kategori;
      tanggal = t.tanggal;
    }
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => tanggal = picked);
    }
  }

  void _simpan() {
    if (nominalC.text.isEmpty ||
        keteranganC.text.isEmpty ||
        tanggal == null ||
        (kategori == null || kategori!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data transaksi"),
        ),
      );
      return;
    }

    final nominal = int.tryParse(nominalC.text.replaceAll('.', '')) ?? 0;
    final transaksi = Transaksi(
      id: widget.transaksi?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tanggal: tanggal!,
      nominal: nominal,
      keterangan: keteranganC.text,
      kategori: kategori,
      jenis: jenis,
      cabangId: AuthService.currentUser?.cabangId ?? '1',
      userId: AuthService.currentUser?.id ?? '2',
    );

    widget.onSaved(transaksi);

    // jika layar dipush (edit), tutup rute
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      jenis = TransaksiJenis.pemasukan;
      nominalC.clear();
      keteranganC.clear();
      kategori = null;
      tanggal = null;
    });
  }

  String _formatTanggal(DateTime? t) {
    if (t == null) return "--------------";
    const bulan = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    return "${t.day} ${bulan[t.month]} ${t.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? "EDIT TRANSAKSI" : "TAMBAH TRANSAKSI",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _isEditing ? "EDIT TRANSAKSI" : "TAMBAH TRANSAKSI",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    jenis = TransaksiJenis.pemasukan;
                                    kategori = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: jenis == TransaksiJenis.pemasukan
                                        ? Colors.green
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Pemasukan",
                                      style: TextStyle(
                                        color: jenis ==
                                                TransaksiJenis.pemasukan
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    jenis = TransaksiJenis.pengeluaran;
                                    kategori = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: jenis ==
                                            TransaksiJenis.pengeluaran
                                        ? Colors.green
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Pengeluaran",
                                      style: TextStyle(
                                        color: jenis ==
                                                TransaksiJenis.pengeluaran
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Rp ${nominalC.text.isEmpty ? 'X.XXX.XXX' : nominalC.text}",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Nominal",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nominalC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Masukkan jumlah uang",
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Tanggal",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pilihTanggal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTanggal(tanggal),
                                style: TextStyle(
                                  color: tanggal == null
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined,
                                  size: 18, color: Colors.grey[700]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Always show category dropdown; options depend on jenis and the current user's cabang
                      const Text(
                        "Kategori",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: kategori,
                        items: kategoriRepo
                            .getKategoriByCabang(AuthService.currentUser?.cabangId)
                            .where((k) => k.tipe == (jenis == TransaksiJenis.pemasukan ? KategoriType.pemasukan : KategoriType.pengeluaran))
                            .map((k) => DropdownMenuItem(
                                  value: k.nama,
                                  child: Text(k.nama),
                                ))
                            .toList(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            kategori = v;
                          });
                        },
                        hint: const Text('Pilih kategori'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Catatan",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: keteranganC,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Contoh: Penjualan harian, listrik, dll.",
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _simpan,
                          child: Text(
                            _isEditing ? "Perbarui" : "Selesai",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(
                                color: Colors.grey.shade400),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              jenis = TransaksiJenis.pemasukan;
                              nominalC.clear();
                              keteranganC.clear();
                              kategori = null;
                              tanggal = null;
                            });
                          },
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


