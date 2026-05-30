import 'package:flutter/material.dart';

import '../models/cabang.dart';
import '../models/periode_filter.dart';
import '../models/transaksi.dart';
import '../models/user.dart';

class HomeDashboardDesign extends StatelessWidget {
  final UserRole role;
  final List<Cabang> cabangs;
  final String? selectedCabangId;
  final PeriodeFilter filter;
  final ValueChanged<String?> onCabangChanged;
  final ValueChanged<PeriodeFilter> onFilterChanged;
  final double modalAwal;
  final int totalMasuk;
  final int totalKeluar;
  final double saldoSaatIni;
  final List<String> chartDates;
  final List<int> chartPemasukan;
  final List<int> chartPengeluaran;
  final List<Transaksi> transactions;
  final void Function(String id) onDelete;

  const HomeDashboardDesign({
    super.key,
    required this.role,
    required this.cabangs,
    required this.selectedCabangId,
    required this.filter,
    required this.onCabangChanged,
    required this.onFilterChanged,
    required this.modalAwal,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.saldoSaatIni,
    required this.chartDates,
    required this.chartPemasukan,
    required this.chartPengeluaran,
    required this.transactions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HALLO',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role == UserRole.owner ? 'Pemilik Usaha' : 'Karyawan',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Total Saldo Saat Ini',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Rp ${saldoSaatIni.toInt()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterRow(context),
                  const SizedBox(height: 24),
                  _buildSummaryCard(context),
                  const SizedBox(height: 20),
                  _buildChartSection(context),
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionList(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    if (role == UserRole.owner) {
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Cabang',
                border: OutlineInputBorder(),
              ),
              value: selectedCabangId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Semua Cabang'),
                ),
                ...cabangs.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nama),
                  ),
                ),
              ],
              onChanged: onCabangChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<PeriodeFilter>(
              decoration: const InputDecoration(
                labelText: 'Periode',
                border: OutlineInputBorder(),
              ),
              value: filter,
              items: PeriodeFilter.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onFilterChanged(value);
              },
            ),
          ),
        ],
      );
    }

    final cabangName = cabangs
        .firstWhere(
          (c) => c.id == selectedCabangId,
          orElse: () => Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
        )
        .nama;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
            ),
            child: Text(
              'Cabang: $cabangName',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<PeriodeFilter>(
            decoration: const InputDecoration(
              labelText: 'Periode',
              border: OutlineInputBorder(),
            ),
            value: filter,
            items: PeriodeFilter.values
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onFilterChanged(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Keuangan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                title: 'Modal Awal',
                value: 'Rp ${modalAwal.toInt()}',
                color: Colors.black87,
              ),
              _buildSummaryItem(
                title: 'Saldo Saat Ini',
                value: 'Rp ${saldoSaatIni.toInt()}',
                color: Colors.green,
                isStrong: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Pemasukan',
                  value: 'Rp $totalMasuk',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  title: 'Pengeluaran',
                  value: 'Rp $totalKeluar',
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required Color color,
    bool isStrong = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isStrong ? 18 : 14,
              fontWeight: isStrong ? FontWeight.bold : FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Keuangan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: chartDates.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : CustomPaint(
                    painter: _DualLineChartPainter(
                      dates: chartDates,
                      pemasukan: chartPemasukan,
                      pengeluaran: chartPengeluaran,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.green, 'Pemasukan'),
              const SizedBox(width: 18),
              _buildLegendDot(Colors.red, 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            'Belum ada transaksi',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final sorted = [...transactions]..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    return Column(
      children: sorted.asMap().entries.map((entry) {
        final index = entry.key;
        final t = entry.value;
        var saldoKumulatif = 0;
        for (int i = 0; i <= index; i++) {
          final trans = sorted[i];
          saldoKumulatif += trans.jenis == TransaksiJenis.pemasukan ? trans.nominal : -trans.nominal;
        }
        final isUntung = saldoKumulatif >= 0;
        final warnaSaldo = isUntung ? Colors.green : Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
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
                      color: t.warna.withOpacity(0.12),
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
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.kategori != null && t.kategori!.isNotEmpty
                            ? '${t.kategori} – ${t.keterangan}'
                            : t.keterangan,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.tanggal.day} ${_monthName(t.tanggal.month)} ${t.tanggal.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: t.warna),
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
                        isUntung
                            ? 'Untung Rp $saldoKumulatif'
                            : 'Rugi Rp ${saldoKumulatif.abs()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: warnaSaldo,
                        ),
                      ),
                    ],
                  ),
                  if (role == UserRole.owner)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => onDelete(t.id),
                        child: const Icon(Icons.delete, size: 18, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month];
  }
}

class _DualLineChartPainter extends CustomPainter {
  final List<String> dates;
  final List<int> pemasukan;
  final List<int> pengeluaran;

  _DualLineChartPainter({
    required this.dates,
    required this.pemasukan,
    required this.pengeluaran,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dates.isEmpty) return;

    final paintAxis = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final paintGrid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    final allValues = [...pemasukan, ...pengeluaran];
    int maxV = allValues.isEmpty ? 100 : allValues.reduce((a, b) => a > b ? a : b);
    if (maxV == 0) maxV = 100;
    final interval = ((maxV) / 4).ceil();
    final maxY = ((maxV / interval).ceil() * interval);
    final minY = 0;

    const double leftPadding = 38;
    const double bottomPadding = 32;
    const double topPadding = 16;
    final chartWidth = size.width - leftPadding - 12;
    final chartHeight = size.height - bottomPadding - topPadding;
    final yEnd = size.height - bottomPadding;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, yEnd),
      paintAxis,
    );
    canvas.drawLine(
      Offset(leftPadding, yEnd),
      Offset(size.width, yEnd),
      paintAxis,
    );

    for (int i = 0; i <= 4; i++) {
      final y = yEnd - (i / 4) * chartHeight;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        paintGrid,
      );
      final label = (minY + i * interval).toString();
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 6, y - tp.height / 2));
    }

    double valueToY(int value) {
      final frac = maxY == minY ? 0.0 : (value - minY) / (maxY - minY);
      return yEnd - frac * chartHeight;
    }

    double indexToX(int index) {
      if (dates.length == 1) return leftPadding + chartWidth / 2;
      return leftPadding + (index / (dates.length - 1)) * chartWidth;
    }

    void drawLine(List<int> values, Color color) {
      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final point = Offset(indexToX(i), valueToY(values[i]));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawCircle(point, 3.5, Paint()..color = color);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }

    drawLine(pemasukan, Colors.green);
    drawLine(pengeluaran, Colors.red);

    for (int i = 0; i < dates.length; i++) {
      final x = indexToX(i);
      final tp = TextPainter(
        text: TextSpan(
          text: dates[i].split('/')[0],
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, yEnd + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _DualLineChartPainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.pemasukan != pemasukan ||
        oldDelegate.pengeluaran != pengeluaran;
  }
}
