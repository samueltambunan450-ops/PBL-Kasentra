import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cabang.dart';
import '../models/transaksi.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';

// ===== Design tokens (brand KASENTRA) =====
class _ReportColors {
  static const primary = Color(0xFF1B6B3A);
  static const accent = Color(0xFF2E8B4E);
  static const accentLight = Color(0xFFE7F4EA);
  static const danger = Color(0xFFD64545);
  static const dangerLight = Color(0xFFFBEAEA);
  static const neutral = Color(0xFF5B6B63);
  static const neutralLight = Color(0xFFF0F2F1);
  static const textDark = Color(0xFF16201A);
}

class ReportPage extends StatefulWidget {
  final List<Transaksi> transaksi;

  const ReportPage({super.key, required this.transaksi});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedCabangId = '';
  String _selectedPeriod = 'Bulanan';
  DateTimeRange? _selectedDateRange;
  DateTime _currentPeriod = DateTime.now();

  List<Cabang> _cabangs = [];
  bool _loadingCabangs = true;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadCabangs();
    _checkAccess();
  }

  void _checkAccess() {
    if (AuthService.isOwner()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  Future<void> _loadCabangs() async {
    try {
      final list = await DomainApiService.fetchCabangs();
      if (!mounted) return;
      setState(() {
        _cabangs = list;
        _loadingCabangs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCabangs = false);
    }
  }

  // ===================== Helpers URL foto =====================

  /// Mengubah path relatif "bukti/xxx.jpg" → URL lengkap
  String _buildFotoUrl(String relativePath) {
    return ApiService.buildFotoUrl(relativePath);
  }

  // ===================== Derived data =====================

  List<Transaksi> get _filteredTransaksi {
    return widget.transaksi.where((t) {
      final cabangMatch =
          _selectedCabangId.isEmpty || t.cabangId == _selectedCabangId;
      return cabangMatch && _matchesDate(t.tanggal);
    }).toList();
  }

  bool _matchesDate(DateTime tanggal) {
    if (_selectedDateRange != null) {
      return !tanggal.isBefore(_selectedDateRange!.start) &&
          !tanggal.isAfter(_selectedDateRange!.end);
    }
    switch (_selectedPeriod) {
      case 'Harian':
        return tanggal.year == _currentPeriod.year &&
            tanggal.month == _currentPeriod.month &&
            tanggal.day == _currentPeriod.day;
      case 'Mingguan':
        final startOfWeek = _currentPeriod
            .subtract(Duration(days: _currentPeriod.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return !tanggal.isBefore(startOfWeek) &&
            !tanggal.isAfter(endOfWeek);
      case 'Bulanan':
        return tanggal.year == _currentPeriod.year &&
            tanggal.month == _currentPeriod.month;
      default:
        return true;
    }
  }

  double get _modalAwal {
    if (_cabangs.isEmpty) return 0;
    if (_selectedCabangId.isEmpty) {
      return _cabangs.fold(0.0, (sum, cab) => sum + cab.modalAwal);
    }
    final cabang = _cabangs.firstWhere(
      (c) => c.id == _selectedCabangId,
      orElse: () => Cabang(id: '', nama: '', alamat: '', modalAwal: 0),
    );
    return cabang.modalAwal;
  }

  int get _totalPemasukan => _filteredTransaksi
      .where((t) => t.jenis == TransaksiJenis.pemasukan)
      .fold(0, (sum, t) => sum + t.nominal);

  int get _totalPengeluaran => _filteredTransaksi
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .fold(0, (sum, t) => sum + t.nominal);

  double get _saldoAkhir => _modalAwal + _totalPemasukan - _totalPengeluaran;

  List<FlSpot> _chartData(TransaksiJenis jenis) {
    final grouped = <DateTime, int>{};
    for (final t in _filteredTransaksi.where((t) => t.jenis == jenis)) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }
    final sortedDates = grouped.keys.toList()..sort();
    if (sortedDates.isEmpty) return [const FlSpot(0, 0)];
    return [
      for (int i = 0; i < sortedDates.length; i++)
        FlSpot(i.toDouble(), grouped[sortedDates[i]]!.toDouble()),
    ];
  }

  // ===================== Formatting =====================

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _getPeriodLabel() {
    if (_selectedDateRange != null) {
      final start = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start);
      final end = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end);
      return '$start - $end';
    }
    switch (_selectedPeriod) {
      case 'Harian':
        return DateFormat('dd MMMM yyyy').format(_currentPeriod);
      case 'Mingguan':
        final startOfWeek = _currentPeriod
            .subtract(Duration(days: _currentPeriod.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd/MM').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy').format(endOfWeek)}';
      case 'Bulanan':
        return DateFormat('MMMM yyyy').format(_currentPeriod);
      default:
        return '';
    }
  }

  // ===================== Actions =====================

  void _navigatePeriod(bool forward) {
    setState(() {
      switch (_selectedPeriod) {
        case 'Harian':
          _currentPeriod = forward
              ? _currentPeriod.add(const Duration(days: 1))
              : _currentPeriod.subtract(const Duration(days: 1));
          break;
        case 'Mingguan':
          _currentPeriod = forward
              ? _currentPeriod.add(const Duration(days: 7))
              : _currentPeriod.subtract(const Duration(days: 7));
          break;
        case 'Bulanan':
          _currentPeriod = DateTime(
            _currentPeriod.year,
            forward ? _currentPeriod.month + 1 : _currentPeriod.month - 1,
            1,
          );
          break;
      }
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  // ===================== Export PDF =====================

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    try {
      final cabangLabel = _selectedCabangId.isEmpty
          ? 'Semua Cabang'
          : _cabangs
              .firstWhere(
                (c) => c.id == _selectedCabangId,
                orElse: () =>
                    Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
              )
              .nama;

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Keuangan KASENTRA',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periode: ${_getPeriodLabel()}   |   Cabang: $cabangLabel',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
            ],
          ),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Halaman ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          build: (ctx) => [
            // --- Ringkasan ---
            pw.Text(
              'Ringkasan Keuangan',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(3),
              },
              children: [
                _pdfHeaderRow(['Keterangan', 'Jumlah']),
                _pdfSummaryRow(
                    'Modal Awal', _formatCurrency(_modalAwal)),
                _pdfSummaryRow('Total Pemasukan',
                    _formatCurrency(_totalPemasukan.toDouble())),
                _pdfSummaryRow('Total Pengeluaran',
                    _formatCurrency(_totalPengeluaran.toDouble())),
                _pdfSummaryRow(
                    'Saldo Akhir', _formatCurrency(_saldoAkhir),
                    isBold: true),
              ],
            ),
            pw.SizedBox(height: 24),

            // --- Detail Transaksi ---
            pw.Text(
              'Detail Transaksi',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Tanggal',
                'Cabang',
                'Kategori',
                'Jenis',
                'Nominal',
                'Keterangan',
                'Foto Bukti',
              ],
              data: _filteredTransaksi.map((t) {
                final cabang = _cabangs.firstWhere(
                  (c) => c.id == t.cabangId,
                  orElse: () =>
                      Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
                );
                final hasFoto =
                    t.fotoBukti != null && t.fotoBukti!.isNotEmpty;
                return [
                  DateFormat('dd/MM/yyyy').format(t.tanggal),
                  cabang.nama,
                  t.kategori ?? '-',
                  t.jenis == TransaksiJenis.pemasukan
                      ? 'Pemasukan'
                      : 'Pengeluaran',
                  _formatCurrency(t.nominal.toDouble()),
                  t.keterangan,
                  // Tampilkan URL foto agar bisa dibuka manual dari PDF
                  hasFoto ? _buildFotoUrl(t.fotoBukti!) : '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1B6B3A),
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 24,
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 24),

            // --- Catatan ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Catatan:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Saldo Akhir = Modal Awal + Total Pemasukan - Total Pengeluaran\n'
                    'Kolom "Foto Bukti" berisi URL foto yang dapat dibuka di browser.',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  pw.TableRow _pdfHeaderRow(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF1B6B3A)),
      children: labels
          .map(
            (l) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                l,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.TableRow _pdfSummaryRow(String label, String value,
      {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              )),
        ),
      ],
    );
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(
        body: Center(child: Text('Anda tidak bisa mengakses halaman ini.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _ReportColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _exportingPdf
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Export PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _exportPdf,
                ),
        ],
      ),
      body: _loadingCabangs
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildChartCard(),
                  const SizedBox(height: 16),
                  _buildTransactionTable(),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(),
                ],
              ),
            ),
    );
  }

  // ---- Filter ----

  Widget _buildFilterCard() {
    return _SectionCard(
      title: 'Filter Laporan',
      icon: Icons.filter_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledDropdown(
                  label: 'Pilih Cabang',
                  value: _selectedCabangId,
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('Semua Cabang')),
                    ..._cabangs.map((cab) => DropdownMenuItem(
                        value: cab.id, child: Text(cab.nama))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedCabangId = v ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LabeledDropdown(
                  label: 'Pilih Periode',
                  value: _selectedPeriod,
                  items: ['Harian', 'Mingguan', 'Bulanan']
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedPeriod = v ?? 'Bulanan';
                    _selectedDateRange = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Tanggal (Range)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18),
                            label: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                                  : 'Pilih Range Tanggal',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ReportColors.primary,
                              side: BorderSide(
                                  color: _ReportColors.primary
                                      .withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: _ReportColors.danger),
                            tooltip: 'Hapus filter tanggal',
                            onPressed: () =>
                                setState(() => _selectedDateRange = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_selectedDateRange == null) ...[
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _navigatePeriod(false),
                      color: _ReportColors.primary,
                    ),
                    Text(_getPeriodLabel(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _navigatePeriod(true),
                      color: _ReportColors.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---- Summary ----

  Widget _buildSummaryCard() {
    return _SectionCard(
      title: 'Ringkasan Keuangan',
      icon: Icons.summarize_outlined,
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'MODAL AWAL',
              value: _formatCurrency(_modalAwal),
              icon: Icons.account_balance_wallet_outlined,
              background: _ReportColors.neutralLight,
              foreground: _ReportColors.neutral,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryItem(
              label: 'PEMASUKAN',
              value: _formatCurrency(_totalPemasukan.toDouble()),
              icon: Icons.trending_up,
              background: _ReportColors.accentLight,
              foreground: _ReportColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryItem(
              label: 'PENGELUARAN',
              value: _formatCurrency(_totalPengeluaran.toDouble()),
              icon: Icons.trending_down,
              background: _ReportColors.dangerLight,
              foreground: _ReportColors.danger,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryItem(
              label: 'SALDO AKHIR',
              value: _formatCurrency(_saldoAkhir),
              icon: Icons.savings_outlined,
              background: _ReportColors.primary,
              foreground: Colors.white,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Chart ----

  Widget _buildChartCard() {
    return _SectionCard(
      title: 'Grafik Perkembangan Usaha',
      icon: Icons.show_chart,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E9E6), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, _) => Text(
                        NumberFormat.compactCurrency(
                          locale: 'id_ID',
                          symbol: 'Rp',
                          decimalDigits: 0,
                        ).format(value),
                        style: const TextStyle(
                            fontSize: 9, color: _ReportColors.neutral),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text(
                        'D${value.toInt() + 1}',
                        style: const TextStyle(
                            fontSize: 9, color: _ReportColors.neutral),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData(TransaksiJenis.pemasukan),
                    isCurved: true,
                    color: _ReportColors.accent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: _chartData(TransaksiJenis.pengeluaran),
                    isCurved: true,
                    color: _ReportColors.danger,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: _ReportColors.accent, label: 'Pemasukan'),
              SizedBox(width: 20),
              _LegendDot(
                  color: _ReportColors.danger, label: 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Tabel Transaksi ----

  Widget _buildTransactionTable() {
    return _SectionCard(
      title: 'Detail Transaksi',
      icon: Icons.receipt_long_outlined,
      child: _filteredTransaksi.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Text('Tidak ada transaksi dalam periode ini')),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    _ReportColors.accentLight),
                columns: const [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Cabang')),
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Jenis')),
                  DataColumn(label: Text('Nominal')),
                  DataColumn(label: Text('Keterangan')),
                  DataColumn(label: Text('Foto Bukti')),
                ],
                rows: _filteredTransaksi.map((t) {
                  final cabang = _cabangs.firstWhere(
                    (c) => c.id == t.cabangId,
                    orElse: () =>
                        Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
                  );
                  final isPemasukan = t.jenis == TransaksiJenis.pemasukan;
                  return DataRow(cells: [
                    DataCell(
                        Text(DateFormat('dd/MM/yyyy').format(t.tanggal))),
                    DataCell(Text(cabang.nama)),
                    DataCell(Text(t.kategori ?? '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPemasukan
                              ? _ReportColors.accentLight
                              : _ReportColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPemasukan ? 'Pemasukan' : 'Pengeluaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPemasukan
                                ? _ReportColors.primary
                                : _ReportColors.danger,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                        Text(_formatCurrency(t.nominal.toDouble()))),
                    DataCell(Text(t.keterangan)),
                    DataCell(_buildFotoCell(t.fotoBukti)),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  // ---- Foto cell & viewer ----

  Widget _buildFotoCell(String? fotoBukti) {
    if (fotoBukti == null || fotoBukti.isEmpty) {
      return const Text('-',
          style: TextStyle(color: _ReportColors.neutral));
    }
    final url = _buildFotoUrl(fotoBukti);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: _ReportColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      icon: const Icon(Icons.image_outlined, size: 18),
      label: const Text('Lihat', style: TextStyle(fontSize: 12)),
      onPressed: () => _showFotoViewer(url),
    );
  }

  void _showFotoViewer(String fotoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // Foto dengan zoom
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  fotoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 280,
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            const Text('Memuat foto...',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.black45,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 48),
                          SizedBox(height: 8),
                          Text('Gagal memuat foto',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Tombol tutup
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Keterangan ----

  Widget _buildDescriptionCard() {
    return _SectionCard(
      title: 'Keterangan Laporan',
      icon: Icons.info_outline,
      child: const Text(
        'Laporan ini menampilkan data keuangan berdasarkan cabang yang dipilih. '
        'Data mencakup seluruh transaksi pemasukan dan pengeluaran dalam periode yang dipilih.\n\n'
        'Saldo akhir dihitung berdasarkan:\n'
        'Modal awal cabang + Total pemasukan - Total pengeluaran\n\n'
        'Klik tombol "Lihat" pada kolom Foto Bukti untuk melihat foto transaksi. '
        'Gunakan tombol PDF di pojok kanan atas untuk mengekspor laporan.',
        style: TextStyle(
            fontSize: 13.5, color: _ReportColors.neutral, height: 1.5),
      ),
    );
  }
}

// ===================== Reusable widgets =====================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _ReportColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ReportColors.textDark,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool filled;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: foreground.withOpacity(filled ? 0.85 : 0.7),
                letterSpacing: 0.3,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: foreground,
              )),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, color: _ReportColors.neutral)),
      ],
    );
  }
}