import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

import '../models/cabang.dart';
import '../models/periode_filter.dart';
import '../models/transaksi.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/stat_card.dart';

class HomePage extends StatefulWidget {
  final List<Transaksi> transaksi;
  final UserRole role;
  final Future<void> Function(String id) onDelete;

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
  String? _selectedCabangId;
  List<Cabang> _cabangs = [];

  @override
  void initState() {
    super.initState();
    if (widget.role == UserRole.karyawan &&
        AuthService.currentUser?.cabangId != null) {
      _selectedCabangId = AuthService.currentUser!.cabangId;
    }
    _loadCabangs();
  }

  Future<void> _loadCabangs() async {
    try {
      final list = await DomainApiService.fetchCabangs();
      if (!mounted) return;
      setState(() => _cabangs = list);
    } catch (_) {}
  }

  List<Transaksi> get _filtered {
    final now = DateTime.now();
    return widget.transaksi.where((t) {
      if (_selectedCabangId != null && t.cabangId != _selectedCabangId) {
        return false;
      }
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

  int get totalMasuk => _filtered
      .where((t) => t.jenis == TransaksiJenis.pemasukan)
      .fold(0, (sum, t) => sum + t.nominal);

  int get totalKeluar => _filtered
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .fold(0, (sum, t) => sum + t.nominal);

  double get modalAwal {
    if (_selectedCabangId == null) {
      return _cabangs.fold(0.0, (sum, c) => sum + c.modalAwal);
    }
    final cabang = _cabangs.firstWhere(
      (c) => c.id == _selectedCabangId,
      orElse: () => Cabang(id: '', nama: '', alamat: '', modalAwal: 0),
    );
    return cabang.modalAwal;
  }

  double get saldoSaatIni => modalAwal + totalMasuk - totalKeluar;

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

  List<String> get _chartDates {
    final dates = _chartData.keys.toList();
    dates.sort((a, b) {
      final aParts = a.split('/');
      final bParts = b.split('/');
      final aMonth = int.parse(aParts[1]);
      final bMonth = int.parse(bParts[1]);
      if (aMonth != bMonth) return aMonth.compareTo(bMonth);
      return int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
    });
    return dates;
  }

  List<int> get _chartPemasukan =>
      _chartDates.map((d) => _chartData[d]!['masuk'] ?? 0).toList();

  List<int> get _chartPengeluaran =>
      _chartDates.map((d) => _chartData[d]!['keluar'] ?? 0).toList();

  String _formatRupiah(num value) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(value);

  String _namaBulan(int bulan) {
    const nama = [
      "", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
    ];
    return nama[bulan];
  }

  String _periodeLabel(PeriodeFilter f) {
    switch (f) {
      case PeriodeFilter.hariIni:
        return "Hari ini";
      case PeriodeFilter.mingguIni:
        return "Minggu ini";
      case PeriodeFilter.bulanIni:
        return "Bulan ini";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);
    final columns = Responsive.gridColumns(context, mobile: 1, tablet: 2, desktop: 2);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: Responsive.pagePadding(context).copyWith(bottom: 12),
              child: ResponsiveContent(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Halo, ${AuthService.currentUser?.nama.split(' ').first ?? 'Pengguna'}",
                            style: TextStyle(
                              fontSize: Responsive.value(context, mobile: 22.0, tablet: 26.0, desktop: 28.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.role == UserRole.owner
                                ? "Pemilik Usaha"
                                : "Karyawan",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: Responsive.pagePadding(context),
                  child: ResponsiveContent(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(context, isWide),
                        const SizedBox(height: 20),
                        _buildSummarySection(context, columns),
                        const SizedBox(height: 20),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildChartSection()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildRecentTransactions()),
                            ],
                          )
                        else ...[
                          _buildChartSection(),
                          const SizedBox(height: 20),
                          _buildRecentTransactions(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isWide) {
    final periodeDropdown = DropdownButtonFormField<PeriodeFilter>(
      value: filter,
      decoration: const InputDecoration(labelText: "Periode"),
      items: PeriodeFilter.values
          .map((f) => DropdownMenuItem(value: f, child: Text(_periodeLabel(f))))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => filter = v);
      },
    );

    if (widget.role == UserRole.owner) {
      final cabangDropdown = DropdownButtonFormField<String?>(
        value: _selectedCabangId,
        decoration: const InputDecoration(labelText: "Cabang"),
        items: [
          const DropdownMenuItem(value: null, child: Text("Semua Cabang")),
          ..._cabangs.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama))),
        ],
        onChanged: (v) => setState(() => _selectedCabangId = v),
      );

      if (isWide) {
        return Row(
          children: [
            Expanded(child: cabangDropdown),
            const SizedBox(width: 12),
            Expanded(child: periodeDropdown),
          ],
        );
      }
      return Column(
        children: [
          cabangDropdown,
          const SizedBox(height: 12),
          periodeDropdown,
        ],
      );
    }

    final cabangName = _cabangs
        .firstWhere(
          (c) => c.id == _selectedCabangId,
          orElse: () => Cabang(id: '-', nama: 'Tidak diketahui', alamat: '-', modalAwal: 0),
        )
        .nama;

    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: InputDecorator(
              decoration: const InputDecoration(labelText: "Cabang"),
              child: Text(cabangName),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: periodeDropdown),
        ],
      );
    }

    return Column(
      children: [
        InputDecorator(
          decoration: const InputDecoration(labelText: "Cabang"),
          child: Text(cabangName),
        ),
        const SizedBox(height: 12),
        periodeDropdown,
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, int columns) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: Responsive.value(context, mobile: 2.8, tablet: 3.2, desktop: 3.5),
            children: [
              StatCard(label: "Modal Awal", value: _formatRupiah(modalAwal)),
              StatCard(label: "Total Pemasukan", value: _formatRupiah(totalMasuk), valueColor: AppColors.income),
              StatCard(label: "Total Pengeluaran", value: _formatRupiah(totalKeluar), valueColor: AppColors.expense),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text("Saldo Saat Ini", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(saldoSaatIni),
                  style: TextStyle(
                    fontSize: Responsive.value(context, mobile: 22.0, tablet: 26.0, desktop: 28.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  saldoSaatIni >= modalAwal ? "Keuntungan periode ini" : "Kerugian periode ini",
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Grafik Keuangan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Container(
          height: Responsive.value(context, mobile: 220.0, tablet: 260.0, desktop: 280.0),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _chartDates.isEmpty
              ? Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey.shade600)))
              : CustomPaint(
                  painter: _DualLineChartPainter(
                    dates: _chartDates,
                    pemasukan: _chartPemasukan,
                    pengeluaran: _chartPengeluaran,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(AppColors.income, "Pemasukan"),
            const SizedBox(width: 20),
            _legendItem(AppColors.expense, "Pengeluaran"),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final sorted = [..._filtered]..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (sorted.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey.shade600))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length > 8 ? 8 : sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final t = sorted[index];
              return _TransactionTile(
                transaksi: t,
                showDelete: widget.role == UserRole.owner,
                onDelete: () => widget.onDelete(t.id),
                formatDate: () => "${t.tanggal.day} ${_namaBulan(t.tanggal.month)} ${t.tanggal.year}",
                formatRupiah: _formatRupiah,
              );
            },
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaksi transaksi;
  final bool showDelete;
  final VoidCallback onDelete;
  final String Function() formatDate;
  final String Function(num) formatRupiah;

  const _TransactionTile({
    required this.transaksi,
    required this.showDelete,
    required this.onDelete,
    required this.formatDate,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeading(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildAmount(), if (showDelete) _buildDelete()],
                ),
              ],
            )
          : Row(
              children: [
                _buildLeading(),
                const Spacer(),
                _buildAmount(),
                if (showDelete) ...[const SizedBox(width: 8), _buildDelete()],
              ],
            ),
    );
  }

  Widget _buildLeading() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaksi.warna.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            transaksi.jenis == TransaksiJenis.pemasukan ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaksi.warna,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaksi.kategori != null && transaksi.kategori!.isNotEmpty
                    ? '${transaksi.kategori} – ${transaksi.keterangan}'
                    : transaksi.keterangan,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(formatDate(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmount() {
    return Text(
      formatRupiah(transaksi.nominal),
      style: TextStyle(fontWeight: FontWeight.bold, color: transaksi.warna),
    );
  }

  Widget _buildDelete() {
    return IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
      visualDensity: VisualDensity.compact,
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

    final paintAxis = Paint()..color = Colors.grey.shade400..strokeWidth = 1;
    final paintGrid = Paint()..color = Colors.grey.shade300..strokeWidth = 0.5;

    final allValues = [...pemasukan, ...pengeluaran];
    int maxV = allValues.isEmpty ? 1000 : allValues.reduce((a, b) => a > b ? a : b);
    if (maxV == 0) maxV = 1000;
    final interval = (maxV / 5).ceil();
    final maxY = ((maxV / interval).ceil() * interval);
    const minY = 0;

    const double leftPadding = 40;
    const double bottomPadding = 30;
    const double topPadding = 20;
    final chartWidth = size.width - leftPadding - 8;
    final chartHeight = size.height - topPadding - bottomPadding;
    final yStart = topPadding;
    final yEnd = size.height - bottomPadding;

    canvas.drawLine(Offset(leftPadding, yStart), Offset(leftPadding, yEnd), paintAxis);

    for (int i = 0; i <= 5; i++) {
      final value = minY + (i * interval);
      final y = yEnd - (i / 5) * chartHeight;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), paintGrid);
      final tp = TextPainter(
        text: TextSpan(text: value.toString(), style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 4, y - tp.height / 2));
    }

    canvas.drawLine(Offset(leftPadding, yEnd), Offset(size.width, yEnd), paintAxis);

    double valueToY(int value) {
      if (maxY == minY) return yEnd;
      return yEnd - ((value - minY) / (maxY - minY)) * chartHeight;
    }

    double indexToX(int index) {
      if (dates.length == 1) return leftPadding + chartWidth / 2;
      return leftPadding + (index / (dates.length - 1)) * chartWidth;
    }

    void drawLine(List<int> values, Color color) {
      if (values.isEmpty) return;
      final points = List.generate(values.length, (i) => Offset(indexToX(i), valueToY(values[i])));
      final linePaint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
      final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
      for (final p in points) {
        canvas.drawCircle(p, 4, dotPaint);
      }
    }

    drawLine(pemasukan, AppColors.income);
    drawLine(pengeluaran, AppColors.expense);

    for (int i = 0; i < dates.length; i++) {
      final x = indexToX(i);
      final label = dates[i].split('/')[0];
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: Colors.grey.shade700, fontSize: 9)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, yEnd + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DualLineChartPainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.pemasukan != pemasukan ||
        oldDelegate.pengeluaran != pengeluaran;
  }
}
