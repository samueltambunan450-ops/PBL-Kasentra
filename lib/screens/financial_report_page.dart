import 'package:flutter/material.dart';

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
  DateTime _selectedMonth = DateTime.now();

  List<Transaksi> get _monthTransactions {
    return widget.transaksi.where((t) {
      return t.tanggal.year == _selectedMonth.year &&
          t.tanggal.month == _selectedMonth.month;
    }).toList();
  }


  // Pendapatan
  int get _totalPemasukan => _monthTransactions
      .where((t) => t.jenis == TransaksiJenis.pemasukan)
      .fold(0, (sum, t) => sum + t.nominal);

  // Beban Operasional
  int get _bebanOperasional => _monthTransactions
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .where((t) => t.kategori == 'Operasional')
      .fold(0, (sum, t) => sum + t.nominal);

  // Beban Gaji
  int get _bebanGaji => _monthTransactions
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .where((t) => t.kategori == 'Gaji')
      .fold(0, (sum, t) => sum + t.nominal);

  // Beban Lainnya
  int get _bebanLain => _monthTransactions
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .where((t) => t.kategori != 'Operasional' && t.kategori != 'Gaji')
      .fold(0, (sum, t) => sum + t.nominal);

  // Total Beban
  int get _totalBeban => _bebanOperasional + _bebanGaji + _bebanLain;

  // Laba Bersih
  int get _labaBersih => _totalPemasukan - _totalBeban;

  // Saldo kas : untuk pedagang lokal cukup sama dengan laba bersih
  int get _saldoKas => _labaBersih;

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String _monthName() {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan Lengkap'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    _monthName(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Saldo kas sederhana untuk UMKM
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SALDO KAS SAAT INI',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_saldoKas),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // LAPORAN LABA RUGI
            const Text(
              'LAPORAN LABA RUGI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PENDAPATAN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('  Pendapatan Usaha'),
                        Text(_formatCurrency(_totalPemasukan)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BEBAN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('  Beban Operasional'),
                        Text(_formatCurrency(_bebanOperasional)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('  Beban Gaji'),
                        Text(_formatCurrency(_bebanGaji)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('  Beban Lain-lain'),
                        Text(_formatCurrency(_bebanLain)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL BEBAN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatCurrency(_totalBeban),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LABA BERSIH',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatCurrency(_labaBersih),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _labaBersih >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Catatan
            Card(
              color: Colors.yellow.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Catatan: Laporan ini disusun berdasarkan data transaksi yang tercatat. '
                  'Untuk laporan keuangan yang lengkap dan akurat, konsultasikan dengan akuntan profesional.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
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