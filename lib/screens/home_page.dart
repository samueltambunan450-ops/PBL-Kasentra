import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/user.dart';

enum PeriodeFilter { hariIni, mingguIni, bulanIni }

class HomePage extends StatefulWidget {
  final List<Transaksi> transaksi;
  final UserRole role;
  final void Function(String id) onDelete;

  const HomePage({
    super.key,
    required this.transaksi,
    required this.role,
    required this.onDelete,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
          return !t.tanggal.isBefore(monday) &&
              !t.tanggal.isAfter(sunday);
        case PeriodeFilter.bulanIni:
          return t.tanggal.year == now.year &&
              t.tanggal.month == now.month;
      }
    }).toList();
  }

  int get totalMasuk =>
      _filtered
          .where((t) => t.jenis == TransaksiJenis.pemasukan)
          .fold(0, (sum, t) => sum + t.nominal);

  int get totalKeluar =>
      _filtered
          .where((t) => t.jenis == TransaksiJenis.pengeluaran)
          .fold(0, (sum, t) => sum + t.nominal);

  int get labaRugi => totalMasuk - totalKeluar;

  /// Data untuk grafik: pemasukan dan pengeluaran per hari dalam periode
  Map<String, Map<String, int>> get _chartData {
    final Map<String, Map<String, int>> data = {};
    
    for (final t in _filtered) {
      final key = "${t.tanggal.day}/${t.tanggal.month}";
      data.putIfAbsent(key, () => {'masuk': 0, 'keluar': 0});
      
      if (t.jenis == TransaksiJenis.pemasukan) {
        data[key]!['masuk'] = data[key]!['masuk']! + t.nominal;
      } else {
        data[key]!['keluar'] = data[key]!['keluar']! + t.nominal;
      }
    }
    
    return data;
  }

  /// List tanggal unik yang sudah diurutkan untuk sumbu X
  List<String> get _chartDates {
    final dates = _chartData.keys.toList();
    dates.sort((a, b) {
      final aParts = a.split('/');
      final bParts = b.split('/');
      final aDay = int.parse(aParts[0]);
      final bDay = int.parse(bParts[0]);
      if (aDay != bDay) return aDay.compareTo(bDay);
      return int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
    });
    return dates;
  }

  /// Nilai pemasukan untuk grafik
  List<int> get _chartPemasukan {
    return _chartDates.map((date) => _chartData[date]!['masuk'] ?? 0).toList();
  }

  /// Nilai pengeluaran untuk grafik
  List<int> get _chartPengeluaran {
    return _chartDates.map((date) => _chartData[date]!['keluar'] ?? 0).toList();
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
    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HALLO",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.role == UserRole.owner
                            ? "Pemilik Usaha"
                            : "Karyawan",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kartu saldo + ringkasan laba/rugi
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                  24, 24, 24, 18),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(40),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "TOTAL SALDO SAAT INI",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Rp $labaRugi",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    labaRugi >= 0
                                        ? "Laba periode ini"
                                        : "Rugi periode ini",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "PEMASUKAN PERIODE",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Rp $totalMasuk",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "PENGELUARAN PERIODE",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Rp $totalKeluar",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter periode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Periode Laporan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          DropdownButton<PeriodeFilter>(
                            value: filter,
                            items: const [
                              DropdownMenuItem(
                                value: PeriodeFilter.hariIni,
                                child: Text("Hari ini"),
                              ),
                              DropdownMenuItem(
                                value: PeriodeFilter.mingguIni,
                                child: Text("Minggu ini"),
                              ),
                              DropdownMenuItem(
                                value: PeriodeFilter.bulanIni,
                                child: Text("Bulan ini"),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => filter = v);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "GRAFIK KEUANGAN",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: _chartDates.isEmpty
                            ? Center(
                                child: Text(
                                  "Belum ada data",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : CustomPaint(
                                painter: _DualLineChartPainter(
                                  dates: _chartDates,
                                  pemasukan: _chartPemasukan,
                                  pengeluaran: _chartPengeluaran,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Pemasukan",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Pengeluaran",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Riwayat Transaksi",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              "Belum ada transaksi",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            // Urutkan transaksi berdasarkan tanggal untuk perhitungan saldo
                            final sorted = [..._filtered]
                              ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
                            
                            return Column(
                              children: sorted.asMap().entries.map((entry) {
                                final index = entry.key;
                                final t = entry.value;
                                
                                // Hitung saldo kumulatif sampai transaksi ini
                                int saldoKumulatif = 0;
                                for (int i = 0; i <= index; i++) {
                                  final trans = sorted[i];
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: t.warna.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                          child: GestureDetector(
                                            onTap: () => widget.onDelete(t.id),
                                            child: const Icon(Icons.delete,
                                                size: 16, color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                              }).toList(),
                            );
                          },
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

    // Cari nilai min dan max untuk skala Y
    final allValues = [...pemasukan, ...pengeluaran];
    int minV = allValues.isEmpty
        ? 0
        : allValues.reduce((a, b) => a < b ? a : b);
    int maxV = allValues.isEmpty
        ? 1000
        : allValues.reduce((a, b) => a > b ? a : b);

    if (minV == maxV) {
      maxV = minV + 1000;
      minV = 0;
    }

    // Bulatkan ke atas untuk interval yang rapi
    final range = maxV - minV;
    final interval = (range / 5).ceil();
    final maxY = ((maxV / interval).ceil() * interval);
    final minY = 0;

    // Padding
    const double leftPadding = 40;
    const double bottomPadding = 30;
    const double topPadding = 20;
    final chartWidth = size.width - leftPadding - 8;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Gambar sumbu Y dan grid horizontal
    final yStart = topPadding;
    final yEnd = size.height - bottomPadding;
    canvas.drawLine(
      Offset(leftPadding, yStart),
      Offset(leftPadding, yEnd),
      paintAxis,
    );

    // Grid dan label Y (0, interval, 2*interval, ...)
    for (int i = 0; i <= 5; i++) {
      final value = minY + (i * interval);
      final y = yEnd - (i / 5) * chartHeight;
      
      // Grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        paintGrid,
      );

      // Label Y
      final tp = TextPainter(
        text: TextSpan(
          text: value.toString(),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 4, y - tp.height / 2));
    }

    // Gambar sumbu X
    canvas.drawLine(
      Offset(leftPadding, yEnd),
      Offset(size.width, yEnd),
      paintAxis,
    );

    // Fungsi untuk konversi nilai ke koordinat Y
    double valueToY(int value) {
      if (maxY == minY) return yEnd;
      final frac = (value - minY) / (maxY - minY);
      return yEnd - (frac * chartHeight);
    }

    // Fungsi untuk konversi index ke koordinat X
    double indexToX(int index) {
      if (dates.length == 1) return leftPadding + chartWidth / 2;
      return leftPadding + (index / (dates.length - 1)) * chartWidth;
    }

    // Gambar garis pemasukan (hijau)
    if (pemasukan.isNotEmpty) {
      final pointsMasuk = <Offset>[];
      for (int i = 0; i < dates.length; i++) {
        pointsMasuk.add(Offset(indexToX(i), valueToY(pemasukan[i])));
      }

      final linePaintMasuk = Paint()
        ..color = Colors.green
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final pathMasuk = Path()..moveTo(pointsMasuk.first.dx, pointsMasuk.first.dy);
      for (int i = 1; i < pointsMasuk.length; i++) {
        pathMasuk.lineTo(pointsMasuk[i].dx, pointsMasuk[i].dy);
      }
      canvas.drawPath(pathMasuk, linePaintMasuk);

      // Titik pada garis pemasukan
      final dotPaintMasuk = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      for (final p in pointsMasuk) {
        canvas.drawCircle(p, 4, dotPaintMasuk);
      }
    }

    // Gambar garis pengeluaran (merah)
    if (pengeluaran.isNotEmpty) {
      final pointsKeluar = <Offset>[];
      for (int i = 0; i < dates.length; i++) {
        pointsKeluar.add(Offset(indexToX(i), valueToY(pengeluaran[i])));
      }

      final linePaintKeluar = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final pathKeluar = Path()..moveTo(pointsKeluar.first.dx, pointsKeluar.first.dy);
      for (int i = 1; i < pointsKeluar.length; i++) {
        pathKeluar.lineTo(pointsKeluar[i].dx, pointsKeluar[i].dy);
      }
      canvas.drawPath(pathKeluar, linePaintKeluar);

      // Titik pada garis pengeluaran
      final dotPaintKeluar = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      for (final p in pointsKeluar) {
        canvas.drawCircle(p, 4, dotPaintKeluar);
      }
    }

    // Label tanggal di sumbu X
    for (int i = 0; i < dates.length; i++) {
      final x = indexToX(i);
      final dateParts = dates[i].split('/');
      final label = dateParts[0]; // Hanya tampilkan hari
      
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, yEnd + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


