import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/cabang.dart';
import '../models/transaksi.dart';

class FinancialReportPage extends StatefulWidget {
  final List<Transaksi> transaksi;

  const FinancialReportPage({
    super.key,
    required this.transaksi,
  });

  @override
  State<FinancialReportPage> createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  String _selectedCabangId = '';
  String _selectedPeriod = 'Bulanan';
  DateTimeRange? _selectedDateRange;
  DateTime _currentPeriod = DateTime.now();

  List<Cabang> get _cabangs => CabangRepository.instance.cabangs;

  List<Transaksi> get _filteredTransaksi {
    return widget.transaksi.where((t) {
      final cabangMatch = _selectedCabangId.isEmpty || t.cabangId == _selectedCabangId;

      final bool dateMatch;
      if (_selectedDateRange != null) {
        dateMatch = !t.tanggal.isBefore(_selectedDateRange!.start) &&
            !t.tanggal.isAfter(_selectedDateRange!.end);
      } else {
        switch (_selectedPeriod) {
          case 'Harian':
            dateMatch = t.tanggal.year == _currentPeriod.year &&
                t.tanggal.month == _currentPeriod.month &&
                t.tanggal.day == _currentPeriod.day;
            break;
          case 'Mingguan':
            final startOfWeek = _currentPeriod.subtract(Duration(days: _currentPeriod.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            dateMatch = !t.tanggal.isBefore(startOfWeek) && !t.tanggal.isAfter(endOfWeek);
            break;
          case 'Bulanan':
          default:
            dateMatch = t.tanggal.year == _currentPeriod.year &&
                t.tanggal.month == _currentPeriod.month;
        }
      }

      return cabangMatch && dateMatch;
    }).toList();
  }

  double get _modalAwal {
    if (_selectedCabangId.isEmpty) {
      return _cabangs.fold(0.0, (sum, cab) => sum + cab.modalAwal);
    }
    final cabang = _cabangs.firstWhere((c) => c.id == _selectedCabangId, orElse: () => _cabangs.first);
    return cabang.modalAwal;
  }

  int get _totalPemasukan => _filteredTransaksi
      .where((t) => t.jenis == TransaksiJenis.pemasukan)
      .fold(0, (sum, t) => sum + t.nominal);

  int get _totalPengeluaran => _filteredTransaksi
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .fold(0, (sum, t) => sum + t.nominal);

  double get _saldoAkhir => _modalAwal + _totalPemasukan - _totalPengeluaran;

  List<FlSpot> get _chartDataPemasukan {
    final grouped = <DateTime, int>{};
    for (var t in _filteredTransaksi.where((t) => t.jenis == TransaksiJenis.pemasukan)) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }
    final dates = grouped.keys.toList()..sort();
    return List.generate(dates.length, (i) => FlSpot(i.toDouble(), grouped[dates[i]]!.toDouble()));
  }

  List<FlSpot> get _chartDataPengeluaran {
    final grouped = <DateTime, int>{};
    for (var t in _filteredTransaksi.where((t) => t.jenis == TransaksiJenis.pengeluaran)) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }
    final dates = grouped.keys.toList()..sort();
    return List.generate(dates.length, (i) => FlSpot(i.toDouble(), grouped[dates[i]]!.toDouble()));
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
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
        final startOfWeek = _currentPeriod.subtract(Duration(days: _currentPeriod.weekday - 1));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 320,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pilih Cabang', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCabangId,
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
                                    _selectedCabangId = value ?? '';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pilih Periode', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPeriod,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: ['Harian', 'Mingguan', 'Bulanan'].map((period) => DropdownMenuItem(
                                      value: period,
                                      child: Text(period),
                                    )).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPeriod = value ?? 'Bulanan';
                                    _selectedDateRange = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pilih Tanggal (Range)', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _selectDateRange,
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_selectedDateRange != null
                                    ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                                    : 'Pilih Range Tanggal'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedDateRange == null)
                          SizedBox(
                            width: 320,
                            child: Card(
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Keuangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildSummaryCard('MODAL AWAL', _formatCurrency(_modalAwal)),
                        _buildSummaryCard('TOTAL PEMASUKAN', _formatCurrency(_totalPemasukan.toDouble())),
                        _buildSummaryCard('TOTAL PENGELUARAN', _formatCurrency(_totalPengeluaran.toDouble())),
                        _buildSummaryCard('SALDO AKHIR', _formatCurrency(_saldoAkhir)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Grafik Perkembangan Usaha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartDataPemasukan,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots: _chartDataPengeluaran,
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegend(Colors.green, 'Pemasukan'),
                        const SizedBox(width: 16),
                        _buildLegend(Colors.red, 'Pengeluaran'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        ],
                        rows: _filteredTransaksi.map((t) {
                          final cabang = _cabangs.firstWhere(
                            (c) => c.id == t.cabangId,
                            orElse: () => Cabang(id: '-', nama: 'Tidak diketahui', alamat: '-', modalAwal: 0.0),
                          );
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yyyy').format(t.tanggal))),
                            DataCell(Text(cabang.nama)),
                            DataCell(Text(t.kategori ?? '-')),
                            DataCell(Text(t.jenis == TransaksiJenis.pemasukan ? 'Pemasukan' : 'Pengeluaran')),
                            DataCell(Text(_formatCurrency(t.nominal.toDouble()))),
                            DataCell(Text(t.keterangan)),
                          ]);
                        }).toList(),
                      ),
                    ),
                    if (_filteredTransaksi.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Tidak ada transaksi dalam periode ini', style: TextStyle(color: Colors.grey[700]))),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Keterangan Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Laporan ini menampilkan data keuangan berdasarkan cabang yang dipilih.\n'
                      'Data mencakup seluruh transaksi pemasukan dan pengeluaran dalam periode yang dipilih.\n'
                      'Saldo akhir dihitung berdasarkan: modal awal cabang + total pemasukan - total pengeluaran.\n'
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

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
      padding: const EdgeInsets.all(12),
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
}
