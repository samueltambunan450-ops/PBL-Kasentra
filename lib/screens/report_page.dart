import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  String _selectedCabangId = '';
  String _selectedPeriod = 'Bulanan'; // Harian, Mingguan, Bulanan
  DateTimeRange? _selectedDateRange;
  DateTime _currentPeriod = DateTime.now();

  List<Cabang> get _cabangs => CabangRepository.instance.cabangs;

  @override
  void initState() {
    super.initState();
    if (!AuthService.isOwner()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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
        }
      });
    }
  }

  List<Transaksi> get _filteredTransaksi {
    return widget.transaksi.where((t) {
      // Filter cabang
      final cabangMatch = _selectedCabangId.isEmpty || t.cabangId == _selectedCabangId;

      // Filter tanggal berdasarkan periode
      bool dateMatch = true;
      if (_selectedDateRange != null) {
        dateMatch = t.tanggal.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                   t.tanggal.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
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
            dateMatch = t.tanggal.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                       t.tanggal.isBefore(endOfWeek.add(const Duration(days: 1)));
            break;
          case 'Bulanan':
            dateMatch = t.tanggal.year == _currentPeriod.year &&
                       t.tanggal.month == _currentPeriod.month;
            break;
        }
      }

      return cabangMatch && dateMatch;
    }).toList();
  }

  double get _modalAwal {
    if (_selectedCabangId.isEmpty) {
      return _cabangs.fold(0.0, (sum, cab) => sum + cab.modalAwal);
    } else {
      final cabang = _cabangs.firstWhere((c) => c.id == _selectedCabangId);
      return cabang.modalAwal;
    }
  }

  int get _totalPemasukan =>
      _filteredTransaksi
          .where((t) => t.jenis == TransaksiJenis.pemasukan)
          .fold(0, (sum, t) => sum + t.nominal);

  int get _totalPengeluaran =>
      _filteredTransaksi
          .where((t) => t.jenis == TransaksiJenis.pengeluaran)
          .fold(0, (sum, t) => sum + t.nominal);

  double get _saldoAkhir => _modalAwal + _totalPemasukan - _totalPengeluaran;

  List<FlSpot> get _chartDataPemasukan {
    final data = <FlSpot>[];
    final grouped = <DateTime, int>{};

    for (var t in _filteredTransaksi.where((t) => t.jenis == TransaksiJenis.pemasukan)) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }

    final sortedDates = grouped.keys.toList()..sort();
    for (int i = 0; i < sortedDates.length; i++) {
      data.add(FlSpot(i.toDouble(), grouped[sortedDates[i]]!.toDouble()));
    }

    return data;
  }

  List<FlSpot> get _chartDataPengeluaran {
    final data = <FlSpot>[];
    final grouped = <DateTime, int>{};

    for (var t in _filteredTransaksi.where((t) => t.jenis == TransaksiJenis.pengeluaran)) {
      final date = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped[date] = (grouped[date] ?? 0) + t.nominal;
    }

    final sortedDates = grouped.keys.toList()..sort();
    for (int i = 0; i < sortedDates.length; i++) {
      data.add(FlSpot(i.toDouble(), grouped[sortedDates[i]]!.toDouble()));
    }

    return data;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
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
        final startOfWeek = _currentPeriod.subtract(Duration(days: _currentPeriod.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final start = DateFormat('dd/MM').format(startOfWeek);
        final end = DateFormat('dd/MM/yyyy').format(endOfWeek);
        return '$start - $end';
      case 'Bulanan':
        return DateFormat('MMMM yyyy').format(_currentPeriod);
      default:
        return '';
    }
  }

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
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Keuangan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // TODO: Implement PDF export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF akan diimplementasikan')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section
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
                    Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 16),
                        Expanded(
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
                                    _selectedDateRange = null; // Reset date range when changing period
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedDateRange == null) ...[
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () => _navigatePeriod(false),
                                  ),
                                  Text(
                                    _getPeriodLabel(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () => _navigatePeriod(true),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ringkasan Keuangan
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
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("MODAL AWAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_formatCurrency(_modalAwal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                const Text("TOTAL PEMASUKAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_formatCurrency(_totalPemasukan.toDouble()), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                                const Text("TOTAL PENGELUARAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_formatCurrency(_totalPengeluaran.toDouble()), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("SALDO AKHIR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_formatCurrency(_saldoAkhir), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

            // Grafik Perkembangan Usaha
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
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartDataPemasukan,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: false),
                            ),
                            LineChartBarData(
                              spots: _chartDataPengeluaran,
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            const Text('Pemasukan'),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text('Pengeluaran'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detail Transaksi (Tabel)
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _filteredTransaksi.isEmpty
                            ? const Center(child: Text('Tidak ada transaksi dalam periode ini'))
                            : SingleChildScrollView(
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
                                    final cabang = _cabangs.firstWhere((c) => c.id == t.cabangId);
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Keterangan Laporan
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
                      'Saldo akhir dihitung berdasarkan:\n'
                      'Modal awal cabang + Total pemasukan - Total pengeluaran\n'
                      'Grafik menunjukkan perkembangan usaha dalam periode tertentu.\n'
                      'Tabel detail menampilkan semua transaksi dengan informasi lengkap.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


