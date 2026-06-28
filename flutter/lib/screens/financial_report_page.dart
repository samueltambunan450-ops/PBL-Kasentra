import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../models/cabang.dart';
import '../models/transaksi.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../services/pdf_report_generator.dart';
import '../utils/responsive.dart';
import '../widgets/common_page_scaffold.dart';

const incomeChartColor = Color(0xFF1D9E75);
const expenseChartColor = Color(0xFFE24B4A);

class FinancialReportPage extends StatefulWidget {
  final List<Transaksi> transaksi;

  const FinancialReportPage({super.key, required this.transaksi});

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
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

  List<Transaksi> get _filteredTransaksi {
    final filtered = widget.transaksi.where((t) {
      final cabangMatch =
          _selectedCabangId.isEmpty || t.cabangId == _selectedCabangId;

      final bool dateMatch;
      if (_selectedDateRange != null) {
        dateMatch =
            !t.tanggal.isBefore(_selectedDateRange!.start) &&
            !t.tanggal.isAfter(_selectedDateRange!.end);
      } else {
        switch (_selectedPeriod) {
          case 'Harian':
            dateMatch =
                t.tanggal.year == _currentPeriod.year &&
                t.tanggal.month == _currentPeriod.month &&
                t.tanggal.day == _currentPeriod.day;
            break;
          case 'Mingguan':
            final startOfWeek = _currentPeriod.subtract(
              Duration(days: _currentPeriod.weekday - 1),
            );
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            dateMatch =
                !t.tanggal.isBefore(startOfWeek) &&
                !t.tanggal.isAfter(endOfWeek);
            break;
          case 'Bulanan':
          default:
            dateMatch =
                t.tanggal.year == _currentPeriod.year &&
                t.tanggal.month == _currentPeriod.month;
        }
      }

      return cabangMatch && dateMatch;
    }).toList();
    
    return filtered;
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

  double get _labaBersih => (_totalPemasukan - _totalPengeluaran).toDouble();
  double get _saldoKas => _modalAwal + _totalPemasukan - _totalPengeluaran;
  double get _modalAkhir => _modalAwal + _labaBersih;
  double get _roi => _modalAwal > 0 ? (_labaBersih / _modalAwal) * 100 : 0;

  List<DateTime> get _allChartDates {
    final dates = _filteredTransaksi
        .map((t) => DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day))
        .toSet()
        .toList()
      ..sort();
    return dates;
  }

  List<FlSpot> get _chartDataPemasukan {
    final grouped = <DateTime, int>{};
    for (var t in _filteredTransaksi.where(
      (t) => t.jenis == TransaksiJenis.pemasukan,
    )) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }
    return _allChartDates
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (grouped[e.value] ?? 0).toDouble()))
        .toList();
  }

  List<FlSpot> get _chartDataPengeluaran {
    final grouped = <DateTime, int>{};
    for (var t in _filteredTransaksi.where(
      (t) => t.jenis == TransaksiJenis.pengeluaran,
    )) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }
    return _allChartDates
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), (grouped[e.value] ?? 0).toDouble()))
        .toList();
  }

  List<FlSpot> _safeSpots(List<FlSpot> spots) {
    if (spots.isEmpty) {
      return [FlSpot(0, 0), FlSpot(1, 0)];
    }
    if (spots.length == 1) {
      return [FlSpot(0, 0), FlSpot(1, spots.first.y)];
    }
    return spots;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getPeriodLabel() {
    if (_selectedDateRange != null) {
      return '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    }

    switch (_selectedPeriod) {
      case 'Harian':
        return DateFormat('dd MMMM yyyy').format(_currentPeriod);
      case 'Mingguan':
        final startOfWeek = _currentPeriod.subtract(
          Duration(days: _currentPeriod.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd/MM').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy').format(endOfWeek)}';
      case 'Bulanan':
      default:
        return DateFormat('MMMM yyyy').format(_currentPeriod);
    }
  }

  void _navigatePeriod(bool forward) {
    if (_selectedDateRange != null) return;
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
        default:
          _currentPeriod = DateTime(
            _currentPeriod.year,
            forward ? _currentPeriod.month + 1 : _currentPeriod.month - 1,
            1,
          );
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
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _buildFotoUrl(String relativePath) {
    return ApiService.buildFotoUrl(relativePath);
  }

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    try {
      // Use the new PdfReportGenerator
      final generator = PdfReportGenerator(
        transactions: _filteredTransaksi,
        branches: _cabangs,
        selectedBranchId: _selectedCabangId,
        periodLabel: _getPeriodLabel(),
        modalAwal: _modalAwal,
      );

      final doc = await generator.generate();

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

  @override
  Widget build(BuildContext context) {
    if (_loadingCabangs) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CommonPageScaffold(
      title: 'Laporan Keuangan',
      subtitle: 'Laporan transaksi dan ringkasan',
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
                onPressed: _exportPdf,
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildFilterField(
                          context,
                          label: 'Pilih Cabang',
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCabangId,
                            decoration: const InputDecoration(),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('Semua Cabang')),
                              ..._cabangs.map((cab) => DropdownMenuItem(value: cab.id, child: Text(cab.nama))),
                            ],
                            onChanged: (value) => setState(() => _selectedCabangId = value ?? ''),
                          ),
                        ),
                        _buildFilterField(
                          context,
                          label: 'Pilih Periode',
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPeriod,
                            decoration: const InputDecoration(),
                            items: ['Harian', 'Mingguan', 'Bulanan']
                                .map((period) => DropdownMenuItem(value: period, child: Text(period)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value ?? 'Bulanan';
                                _selectedDateRange = null;
                              });
                            },
                          ),
                        ),
                        _buildFilterField(
                          context,
                          label: 'Pilih Tanggal (Range)',
                          child: ElevatedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                                  : 'Pilih Range Tanggal',
                            ),
                          ),
                        ),
                        if (_selectedDateRange == null)
                          _buildFilterField(
                            context,
                            label: 'Navigasi Periode',
                            child: Card(
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: () => _navigatePeriod(false),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _getPeriodLabel(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: () => _navigatePeriod(true),
                                    ),
                                  ],
                                ),
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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Responsive.isMobile(context)
                        ? Column(
                            children: [
                              _buildSummaryCard('MODAL AWAL', _formatCurrency(_modalAwal), expand: false),
                              const SizedBox(height: 12),
                              _buildSummaryCard('TOTAL PEMASUKAN', _formatCurrency(_totalPemasukan.toDouble()), expand: false),
                              const SizedBox(height: 12),
                              _buildSummaryCard('TOTAL PENGELUARAN', _formatCurrency(_totalPengeluaran.toDouble()), expand: false),
                              const SizedBox(height: 12),
                              _buildSummaryCard('SALDO KAS', _formatCurrency(_saldoKas), expand: false),
                            ],
                          )
                        : Row(
                            children: [
                              _buildSummaryCard('MODAL AWAL', _formatCurrency(_modalAwal)),
                              const SizedBox(width: 12),
                              _buildSummaryCard('TOTAL PEMASUKAN', _formatCurrency(_totalPemasukan.toDouble())),
                              const SizedBox(width: 12),
                              _buildSummaryCard('TOTAL PENGELUARAN', _formatCurrency(_totalPengeluaran.toDouble())),
                              const SizedBox(width: 12),
                              _buildSummaryCard('SALDO KAS', _formatCurrency(_saldoKas)),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grafik Perkembangan Usaha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Responsive.isMobile(context)
                        ? Column(
                            children: [
                              _buildChartMetricCard(
                                'Total Pemasukan',
                                _formatCurrency(_totalPemasukan.toDouble()),
                                incomeChartColor,
                              ),
                              const SizedBox(height: 12),
                              _buildChartMetricCard(
                                'Total Pengeluaran',
                                _formatCurrency(_totalPengeluaran.toDouble()),
                                expenseChartColor,
                              ),
                              const SizedBox(height: 12),
                              _buildChartMetricCard(
                                'Laba Bersih',
                                _formatCurrency(_labaBersih),
                                _labaBersih >= 0 ? incomeChartColor : expenseChartColor,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildChartMetricCard(
                                  'Total Pemasukan',
                                  _formatCurrency(_totalPemasukan.toDouble()),
                                  incomeChartColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildChartMetricCard(
                                  'Total Pengeluaran',
                                  _formatCurrency(_totalPengeluaran.toDouble()),
                                  expenseChartColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildChartMetricCard(
                                  'Laba Bersih',
                                  _formatCurrency(_labaBersih),
                                  _labaBersih >= 0 ? incomeChartColor : expenseChartColor,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.grey.shade100,
                              strokeWidth: 1,
                            ),
                          ), // ← FlGridData
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= _allChartDates.length) {
                                    return const SizedBox();
                                  }
                                  final date = _allChartDates[idx];
                                  return Text(
                                    DateFormat('d MMM').format(date),
                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  );
                                },
                              ), // ← SideTitles
                            ), // ← AxisTitles
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 56,
                                getTitlesWidget: (value, meta) {
                                  String text;
                                  if (value >= 1000000) {
                                    text = '${(value / 1000000).toStringAsFixed(1)}jt';
                                  } else if (value >= 1000) {
                                    text = '${(value / 1000).toStringAsFixed(0)}rb';
                                  } else {
                                    text = value.toInt().toString();
                                  }
                                  return Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey));
                                },
                              ), // ← SideTitles
                            ), // ← AxisTitles
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // ← AxisTitles
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // ← AxisTitles
                          ), // ← FlTitlesData
                          borderData: FlBorderData(
                            show: true,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ), // ← FlBorderData
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots.map((spot) {
                                final isIncome = spot.barIndex == 0;
                                return LineTooltipItem(
                                  'Rp ${NumberFormat.decimalPattern('id').format(spot.y.toInt())}',
                                  TextStyle(
                                    color: isIncome ? incomeChartColor : expenseChartColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                            ), // ← LineTouchTooltipData
                          ), // ← LineTouchData
                          lineBarsData: [
                            LineChartBarData(
                              spots: _safeSpots(_chartDataPemasukan),
                              isCurved: true,
                              color: incomeChartColor,
                              barWidth: 2.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                  radius: 3,
                                  color: incomeChartColor,
                                  strokeWidth: 0,
                                ),
                              ), // ← FlDotData
                              belowBarData: BarAreaData(
                                show: true,
                                color: incomeChartColor.withOpacity(0.08),
                              ), // ← BarAreaData
                            ), // ← LineChartBarData
                            LineChartBarData(
                              spots: _safeSpots(_chartDataPengeluaran),
                              isCurved: true,
                              color: expenseChartColor,
                              barWidth: 2.5,
                              dashArray: [6, 4],
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                  radius: 3,
                                  color: expenseChartColor,
                                  strokeWidth: 0,
                                ),
                              ), // ← FlDotData
                              belowBarData: BarAreaData(
                                show: true,
                                color: expenseChartColor.withOpacity(0.06),
                              ), // ← BarAreaData
                            ), // ← LineChartBarData
                          ], // ← lineBarsData
                        ), // ← LineChartData
                      ), // ← LineChart
                    ), // ← SizedBox
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(incomeChartColor, 'Pemasukan'),
                        const SizedBox(width: 16),
                        _buildLegend(expenseChartColor, 'Pengeluaran'),
                      ],
                    ), // ← Row
                  ],
                ), // ← Column
              ), // ← Padding
            ), // ← Card
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
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
                            orElse: () => Cabang(
                              id: '-',
                              nama: 'Tidak diketahui',
                              alamat: '-',
                              modalAwal: 0.0,
                            ),
                          );
                          final hasFoto = t.fotoBukti != null && t.fotoBukti!.isNotEmpty;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat('dd/MM/yyyy').format(t.tanggal),
                                ),
                              ),
                              DataCell(Text(cabang.nama)),
                              DataCell(Text(t.kategori ?? '-')),
                              DataCell(
                                Text(
                                  t.jenis == TransaksiJenis.pemasukan
                                      ? 'Pemasukan'
                                      : 'Pengeluaran',
                                ),
                              ),
                              DataCell(
                                Text(_formatCurrency(t.nominal.toDouble())),
                              ),
                              DataCell(Text(t.keterangan)),
                              DataCell(
                                hasFoto
                                    ? TextButton(
                                        onPressed: () {
                                          final fotoUrl = _buildFotoUrl(t.fotoBukti!);
                                          _showFotoViewer(fotoUrl);
                                        },
                                        child: const Text('Lihat'),
                                      )
                                    : const Text('-'),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    if (_filteredTransaksi.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Tidak ada transaksi dalam periode ini',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keterangan Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Laporan ini menampilkan data keuangan berdasarkan cabang yang dipilih.\n'
                      'Data mencakup seluruh transaksi pemasukan dan pengeluaran dalam periode yang dipilih.\n'
                      'Saldo kas dihitung berdasarkan: modal awal cabang + total pemasukan - total pengeluaran.\n'
                      'Grafik menunjukkan perkembangan usaha dalam periode tertentu.\n'
                      'Tabel detail menampilkan semua transaksi dengan informasi lengkap.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterField(BuildContext context, {required String label, required Widget child}) {
    final width = Responsive.isMobile(context)
        ? double.infinity
        : Responsive.isTablet(context)
            ? 280.0
            : 300.0;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, {bool expand = true}) {
    final card = Container(
      width: expand ? null : double.infinity,
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    return expand ? Expanded(child: card) : card;
  }

  Widget _buildChartMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  void _showFotoViewer(String fotoUrl) {
    final token = AuthService.token;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.network(
                  fotoUrl,
                  fit: BoxFit.contain,
                  headers: token != null ? {'Authorization': 'Bearer $token'} : null,
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
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            const Text('Memuat foto...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.black45,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                          const SizedBox(height: 8),
                          const Text('Gagal memuat foto', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            fotoUrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
}
