import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/user.dart';
import 'add_transaction_page.dart';

enum PeriodeFilter { hariIni, mingguIni, bulanIni }

class HistoryPage extends StatefulWidget {
  final List<Transaksi> transaksi;
  final UserRole role;
  final void Function(String id) onDelete;
  final void Function(Transaksi) onEdit;

  const HistoryPage({
    super.key,
    required this.transaksi,
    required this.role,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  PeriodeFilter filter = PeriodeFilter.bulanIni;

  List<Transaksi> get _filtered {
    final now = DateTime.now();
    return widget.transaksi.where((t) {
      switch (filter) {
        case PeriodeFilter.hariIni:
          return t.tanggal.year == now.year &&
              t.tanggal.month == now.month &&
              t.tanggal.day == now.day;
        case PeriodeFilter.mingguIni:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          return !t.tanggal.isBefore(monday) && !t.tanggal.isAfter(sunday);
        case PeriodeFilter.bulanIni:
          return t.tanggal.year == now.year && t.tanggal.month == now.month;
      }
    }).toList();
  }

  String _namaBulan(int bulan) {
    const nama = [
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
      "Des",
    ];
    return nama[bulan];
  }

  void _editTransaksi(Transaksi t) async {
    final result = await Navigator.push<Transaksi>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(
          onSaved: (updated) => Navigator.pop(context, updated),
          transaksi: t,
        ),
      ),
    );

    if (result != null) {
      widget.onEdit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Filter: "),
                DropdownButton<PeriodeFilter>(
                  value: filter,
                  items: PeriodeFilter.values.map((f) {
                    final label = f == PeriodeFilter.hariIni
                        ? "Hari ini"
                        : f == PeriodeFilter.mingguIni
                            ? "Minggu ini"
                            : "Bulan ini";
                    return DropdownMenuItem(
                      value: f,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => filter = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada transaksi",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final t = _filtered[index];
                        // compute cumulative saldo if needed
                        int saldoKumulatif = 0;
                        for (int i = 0; i <= index; i++) {
                          final trans = _filtered[i];
                          if (trans.jenis == TransaksiJenis.pemasukan) {
                            saldoKumulatif += trans.nominal;
                          } else {
                            saldoKumulatif -= trans.nominal;
                          }
                        }
                        final isUntung = saldoKumulatif >= 0;
                        final warnaSaldo = isUntung ? Colors.green : Colors.red;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: t.warna.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      t.jenis ==
                                              TransaksiJenis.pemasukan
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: t.warna,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.kategori != null && t.kategori!.isNotEmpty
                                            ? '${t.kategori} – ${t.keterangan}'
                                            : t.keterangan,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${t.tanggal.day} ${_namaBulan(t.tanggal.month)} ${t.tanggal.year}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Rp ${t.nominal}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: t.warna,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUntung
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        size: 14,
                                        color: warnaSaldo,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isUntung
                                            ? "Untung Rp ${saldoKumulatif}"
                                            : "Rugi Rp ${saldoKumulatif.abs()}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: warnaSaldo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.role == UserRole.owner)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _editTransaksi(t),
                                            child: const Icon(Icons.edit,
                                                size: 16, color: Colors.blue),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => widget.onDelete(t.id),
                                            child: const Icon(Icons.delete,
                                                size: 16, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
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
