import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/user.dart';
import '../widgets/common_page_scaffold.dart';

enum PeriodeFilter { hariIni, mingguIni, bulanIni }

extension PeriodeFilterLabel on PeriodeFilter {
  String get label {
    switch (this) {
      case PeriodeFilter.hariIni:
        return 'Hari ini';
      case PeriodeFilter.mingguIni:
        return 'Minggu ini';
      case PeriodeFilter.bulanIni:
        return 'Bulan ini';
    }
  }
}

class HistoryPage extends StatefulWidget {
  final List<Transaksi> transaksi;
  final UserRole role;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(Transaksi) onEdit;

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

  @override
  Widget build(BuildContext context) {
    return CommonPageScaffold(
      title: 'Riwayat Transaksi',
      subtitle: 'Semua transaksi terbaru',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                DropdownButton<PeriodeFilter>(
                  value: filter,
                  items: PeriodeFilter.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => filter = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada transaksi',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final t = _filtered[index];
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
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: t.warna.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      t.jenis == TransaksiJenis.pemasukan
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: t.warna,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.kategori != null && t.kategori!.isNotEmpty
                                            ? '${t.kategori} – ${t.keterangan}'
                                            : t.keterangan,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${t.tanggal.day} ${_namaBulan(t.tanggal.month)} ${t.tanggal.year}',
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
                                    'Rp ${t.nominal}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: t.warna,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUntung ? Icons.trending_up : Icons.trending_down,
                                        size: 14,
                                        color: warnaSaldo,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isUntung ? 'Untung' : 'Rugi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: warnaSaldo,
                                        ),
                                      ),
                                    ],
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
