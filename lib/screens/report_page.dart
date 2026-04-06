import 'package:flutter/material.dart';

import '../models/cabang.dart';
import '../models/transaksi.dart';
import '../services/auth_service.dart';

class ReportPage extends StatefulWidget {
  final List<Transaksi> transaksi;

  const ReportPage({
    super.key,
    required this.transaksi,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _displayMonth = DateTime.now();
  String _selectedCabangId = '';

  List<Cabang> get _cabangs => CabangRepository.instance.cabangs;

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
  }

  List<Transaksi> get _monthTx {
    return widget.transaksi.where((t) {
      final sameMonth = t.tanggal.year == _displayMonth.year &&
          t.tanggal.month == _displayMonth.month;
      final sameCabang = _selectedCabangId.isEmpty || t.cabangId == _selectedCabangId;
      return sameMonth && sameCabang;
    }).toList();
  }

  int get _totalMasuk =>
      _monthTx
          .where((t) => t.jenis == TransaksiJenis.pemasukan)
          .fold(0, (sum, t) => sum + t.nominal);

  int get _totalKeluar =>
      _monthTx
          .where((t) => t.jenis == TransaksiJenis.pengeluaran)
          .fold(0, (sum, t) => sum + t.nominal);

  Map<String, int> get _byCategory {
    final map = <String, int>{};
    for (var t in _monthTx) {
      final key = t.kategori != null && t.kategori!.isNotEmpty ? t.kategori! : t.keterangan;
      map[key] = (map[key] ?? 0) + t.nominal;
    }
    return map;
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

    final categories = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String monthLabel() {
      const names = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      final m = _displayMonth.month.clamp(1, 12);
      return '${names[m]} ${_displayMonth.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Bulanan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        final prev = DateTime(
                            _displayMonth.year, _displayMonth.month - 1, 1);
                        _displayMonth = prev;
                      });
                    },
                  ),
                  Text(
                    monthLabel(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        final next = DateTime(
                            _displayMonth.year, _displayMonth.month + 1, 1);
                        _displayMonth = next;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Pilih Cabang', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCabangId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Semua Cabang')),
                      ..._cabangs.map((cab) => DropdownMenuItem(
                            value: cab.id,
                            child: Text(cab.nama),
                          ))
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCabangId = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL SALDO SAAT INI",
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rp ${_totalMasuk - _totalKeluar}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("PEMASUKAN",
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Rp $_totalMasuk",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("PENGELUARAN",
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Rp $_totalKeluar",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Kategori",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton(
                  onPressed: () {},
                  child: const Text("See all"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada transaksi bulan ini",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final entry = categories[index];
                        final name = entry.key;
                        final amount = entry.value;
                        return ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(name),
                          trailing: Text("Rp $amount"),
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


