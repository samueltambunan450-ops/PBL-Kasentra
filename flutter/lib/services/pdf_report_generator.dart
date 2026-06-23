import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cabang.dart';
import '../models/transaksi.dart';

/// Professional PDF Report Generator for KASENTRA Financial Reports
/// Redesigned with comprehensive analysis, charts, and narrative
class PdfReportGenerator {
  // Brand colors
  static const brandGreen = PdfColor.fromInt(0xFF1B6B3A);
  static const brandGreenMedium = PdfColor.fromInt(0xFF2E8B4E);
  static const brandGreenLight = PdfColor.fromInt(0xFFE8F5E9);
  static const incomeColor = PdfColor.fromInt(0xFF1D9E75);
  static const expenseColor = PdfColor.fromInt(0xFFE24B4A);
  static const warningColor = PdfColor.fromInt(0xFFFFA726);
  
  final List<Transaksi> transactions;
  final List<Cabang> branches;
  final String selectedBranchId;
  final String periodLabel;
  final double modalAwal;

  PdfReportGenerator({
    required this.transactions,
    required this.branches,
    required this.selectedBranchId,
    required this.periodLabel,
    required this.modalAwal,
  });

  // Calculate financial metrics
  int get totalPendapatan => transactions
      .where((t) => t.jenis == TransaksiJenis.pemasukan)
      .fold(0, (sum, t) => sum + t.nominal);

  int get totalPengeluaran => transactions
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .fold(0, (sum, t) => sum + t.nominal);

  double get labaBersih => (totalPendapatan - totalPengeluaran).toDouble();
  double get saldoAkhirKas => modalAwal + labaBersih;

  double get marginLabaBersih {
    if (totalPendapatan == 0) return 0;
    return (labaBersih / totalPendapatan) * 100;
  }

  double get rasioPengeluaran {
    if (totalPendapatan == 0) return 0;
    return (totalPengeluaran / totalPendapatan) * 100;
  }

  String get statusKeuangan => labaBersih >= 0 ? 'SURPLUS' : 'DEFISIT';

  // Group expenses by category
  Map<String, int> get expensesByCategory {
    final Map<String, int> grouped = {};
    for (var t in transactions.where((t) => t.jenis == TransaksiJenis.pengeluaran)) {
      final kategori = t.kategori ?? 'Lainnya';
      grouped[kategori] = (grouped[kategori] ?? 0) + t.nominal;
    }
    return grouped;
  }

  String get maxExpenseCategory {
    if (expensesByCategory.isEmpty) return '-';
    var maxEntry = expensesByCategory.entries.first;
    for (var entry in expensesByCategory.entries) {
      if (entry.value > maxEntry.value) {
        maxEntry = entry;
      }
    }
    return maxEntry.key;
  }

  double get maxExpensePercentage {
    if (totalPengeluaran == 0) return 0;
    if (expensesByCategory.isEmpty) return 0;
    final max = expensesByCategory[maxExpenseCategory] ?? 0;
    return (max / totalPengeluaran) * 100;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Generate complete PDF document
  Future<pw.Document> generate() async {
    final doc = pw.Document();
    
    final cabangLabel = selectedBranchId.isEmpty
        ? 'Semua Cabang'
        : branches
            .firstWhere(
              (c) => c.id == selectedBranchId,
              orElse: () => Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
            )
            .nama;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => [
          _buildHeader(cabangLabel),
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildRingkasanKeuangan(),
                pw.SizedBox(height: 16),
                _buildDetailTransaksiSideBySide(),
                pw.SizedBox(height: 16),
                _buildAnalisisKeuangan(),
                pw.SizedBox(height: 16),
                _buildKomposisiPengeluaran(),
                pw.SizedBox(height: 16),
                _buildCatatan(),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );

    return doc;
  }

  /// Section 1: Header with gradient background
  pw.Widget _buildHeader(String cabangLabel) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [brandGreen, brandGreenMedium],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo & Brand
          pw.Row(
            children: [
              pw.Container(
                width: 50,
                height: 50,
                decoration: const pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.white,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'K',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: brandGreen,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'KASENTRA',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'Kelola Keuangan, Kendalikan Masa Depan',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Title & Info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'LAPORAN KEUANGAN',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text('📅 ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    'Periode: $periodLabel',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Text('📍 ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    'Cabang: $cabangLabel',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 2: Ringkasan Keuangan (5 cards)
  pw.Widget _buildRingkasanKeuangan() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. RINGKASAN KEUANGAN',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _buildSummaryCard('Modal Awal', modalAwal, PdfColors.teal800, '●'),
            pw.SizedBox(width: 8),
            _buildSummaryCard('Total Pendapatan', totalPendapatan.toDouble(), incomeColor, '↑'),
            pw.SizedBox(width: 8),
            _buildSummaryCard('Total Pengeluaran', totalPengeluaran.toDouble(), expenseColor, '↓'),
            pw.SizedBox(width: 8),
            _buildSummaryCard('Laba / (Rugi)', labaBersih, warningColor, '⬤'),
            pw.SizedBox(width: 8),
            _buildSummaryCard('Saldo Akhir Kas', saldoAkhirKas, brandGreen, '₿'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Rumus Perhitungan:',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Laba Bersih = Total Pendapatan − Total Pengeluaran',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Saldo Akhir Kas = Modal Awal + Laba Bersih',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryCard(String label, double value, PdfColor color, String icon) {
    final isNegative = value < 0;
    final displayValue = isNegative ? '(${_formatCurrency(value.abs())})' : _formatCurrency(value);
    
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 1.5),
        ),
        child: pw.Column(
          children: [
            pw.Container(
              width: 20,
              height: 20,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: color,
              ),
              child: pw.Center(
                child: pw.Text(
                  icon,
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              displayValue,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: isNegative ? expenseColor : PdfColors.black,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Section 3: Detail Transaksi Side by Side
  pw.Widget _buildDetailTransaksiSideBySide() {
    final pendapatan = transactions.where((t) => t.jenis == TransaksiJenis.pemasukan).toList();
    final pengeluaran = transactions.where((t) => t.jenis == TransaksiJenis.pengeluaran).toList();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildDetailPendapatan(pendapatan)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildDetailPengeluaran(pengeluaran)),
      ],
    );
  }

  pw.Widget _buildDetailPendapatan(List<Transaksi> pendapatan) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: incomeColor, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: const pw.BoxDecoration(
              color: incomeColor,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text('↑ ', style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                pw.Text(
                  '2. DETAIL PENDAPATAN',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableHeader('Tanggal'),
                  _buildTableHeader('Cabang'),
                  _buildTableHeader('Sumber'),
                  _buildTableHeader('Nominal'),
                ],
              ),
              ...pendapatan.take(15).map((t) {
                final cabang = branches.firstWhere(
                  (c) => c.id == t.cabangId,
                  orElse: () => Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
                );
                return pw.TableRow(
                  children: [
                    _buildTableCell(DateFormat('dd/MM/yy').format(t.tanggal)),
                    _buildTableCell(cabang.nama),
                    _buildTableCell(t.kategori ?? 'Lainnya'),
                    _buildTableCell(_formatCurrency(t.nominal.toDouble())),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8F5E9),
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL PENDAPATAN',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _formatCurrency(totalPendapatan.toDouble()),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailPengeluaran(List<Transaksi> pengeluaran) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: expenseColor, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: const pw.BoxDecoration(
              color: expenseColor,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text('↓ ', style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                pw.Text(
                  '3. DETAIL PENGELUARAN',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableHeader('Tanggal'),
                  _buildTableHeader('Cabang'),
                  _buildTableHeader('Kategori'),
                  _buildTableHeader('Nominal'),
                ],
              ),
              ...pengeluaran.take(15).map((t) {
                final cabang = branches.firstWhere(
                  (c) => c.id == t.cabangId,
                  orElse: () => Cabang(id: '', nama: '-', alamat: '', modalAwal: 0),
                );
                return pw.TableRow(
                  children: [
                    _buildTableCell(DateFormat('dd/MM/yy').format(t.tanggal)),
                    _buildTableCell(cabang.nama),
                    _buildTableCell(t.kategori ?? 'Lainnya'),
                    _buildTableCell(_formatCurrency(t.nominal.toDouble())),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFEBEE),
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL PENGELUARAN',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _formatCurrency(totalPengeluaran.toDouble()),
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
    );
  }

  /// Section 4: Analisis Keuangan
  pw.Widget _buildAnalisisKeuangan() {
    final marginInterpretation = totalPendapatan == 0
        ? 'Tidak dapat dihitung (tidak ada pendapatan)'
        : marginLabaBersih > 0
            ? 'Setiap Rp 1 pendapatan menghasilkan untung Rp ${(marginLabaBersih / 100).toStringAsFixed(2)}'
            : 'Setiap Rp 1 pendapatan mengalami rugi Rp ${(marginLabaBersih.abs() / 100).toStringAsFixed(2)}';

    final rasioInterpretation = totalPendapatan == 0
        ? 'Tidak dapat dihitung (tidak ada pendapatan)'
        : rasioPengeluaran > 100
            ? 'Pengeluaran ${_formatPercentage(rasioPengeluaran - 100)} lebih besar dari pendapatan'
            : rasioPengeluaran > 80
                ? 'Pengeluaran tinggi, margin keuntungan kecil'
                : 'Pengeluaran terkendali dengan baik';

    final statusInterpretation = labaBersih >= 0
        ? 'Keuangan usaha dalam kondisi surplus.'
        : 'Keuangan usaha dalam kondisi defisit.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '4. ANALISIS KEUANGAN',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: brandGreen, width: 1.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: const pw.BoxDecoration(
                  color: brandGreen,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(6),
                    topRight: pw.Radius.circular(6),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Indikator',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Nilai',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'Interpretasi',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildAnalysisRow(
                'Laba/(Rugi) Bersih',
                labaBersih < 0 ? '(${_formatCurrency(labaBersih.abs())})' : _formatCurrency(labaBersih),
                labaBersih >= 0 ? 'Usaha mengalami untung pada periode ini.' : 'Usaha mengalami rugi pada periode ini.',
                labaBersih >= 0 ? incomeColor : expenseColor,
              ),
              _buildAnalysisRow(
                'Margin Laba Bersih',
                totalPendapatan == 0 ? 'N/A' : _formatPercentage(marginLabaBersih),
                marginInterpretation,
                totalPendapatan == 0 ? PdfColors.grey : (marginLabaBersih >= 0 ? incomeColor : expenseColor),
              ),
              _buildAnalysisRow(
                'Rasio Pengeluaran thd Pendapatan',
                totalPendapatan == 0 ? 'N/A' : _formatPercentage(rasioPengeluaran),
                rasioInterpretation,
                totalPendapatan == 0 ? PdfColors.grey : (rasioPengeluaran > 80 ? warningColor : incomeColor),
              ),
              _buildAnalysisRow(
                'Status Keuangan',
                '',
                statusInterpretation,
                labaBersih >= 0 ? incomeColor : expenseColor,
                badge: statusKeuangan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAnalysisRow(
    String indikator,
    String nilai,
    String interpretasi,
    PdfColor color, {
    String? badge,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(indikator, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Expanded(
            flex: 2,
            child: badge != null
                ? pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      badge,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  )
                : pw.Text(
                    nilai,
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color),
                  ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Text(interpretasi, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
          ),
        ],
      ),
    );
  }

  /// Section 5: Komposisi Pengeluaran (Visual Bar Chart)
  pw.Widget _buildKomposisiPengeluaran() {
    if (expensesByCategory.isEmpty || totalPengeluaran == 0) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '5. KOMPOSISI PENGELUARAN',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Tidak ada data pengeluaran untuk ditampilkan.', style: const pw.TextStyle(fontSize: 9)),
        ],
      );
    }

    final sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      expenseColor,
      warningColor,
      incomeColor,
      brandGreenMedium,
      const PdfColor.fromInt(0xFF9C27B0),
      const PdfColor.fromInt(0xFF3F51B5),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '5. KOMPOSISI PENGELUARAN',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: expenseColor, width: 1.5),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Summary box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFEBEE),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Pengeluaran',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatCurrency(totalPengeluaran.toDouble()),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: expenseColor),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              // Visual bars for each category
              ...sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryEntry = entry.value;
                final percentage = (categoryEntry.value / totalPengeluaran) * 100;
                final color = colors[index % colors.length];

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 10,
                                height: 10,
                                decoration: pw.BoxDecoration(
                                  color: color,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                categoryEntry.key,
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                          pw.Text(
                            '${_formatCurrency(categoryEntry.value.toDouble())} (${percentage.toStringAsFixed(1)}%)',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Stack(
                        children: [
                          pw.Container(
                            height: 16,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                          ),
                          pw.Container(
                            height: 16,
                            width: (percentage / 100) * 520, // Max width adjusted for layout
                            decoration: pw.BoxDecoration(
                              color: color,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  /// Section 6: Catatan (Narrative)
  pw.Widget _buildCatatan() {
    final statusText = labaBersih >= 0 ? 'surplus' : 'defisit';
    final labaNominal = _formatCurrency(labaBersih.abs());
    final comparison = labaBersih >= 0 
        ? 'total pendapatan lebih besar dibandingkan pengeluaran'
        : 'total pengeluaran lebih besar dibandingkan pendapatan';
    
    final maxCategory = maxExpenseCategory;
    final maxPercentage = maxExpensePercentage.toStringAsFixed(1);

    // Format period label for narrative
    final periodText = periodLabel;

    final narrative = 'Pada periode $periodText, usaha mengalami $statusText sebesar $labaNominal karena $comparison. '
        '${expensesByCategory.isEmpty ? '' : 'Pengeluaran terbesar berasal dari kategori $maxCategory yang mencapai sekitar $maxPercentage% dari total pengeluaran.'}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: brandGreenLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: brandGreen, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 30,
            height: 30,
            decoration: pw.BoxDecoration(
              color: brandGreen,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                '📝',
                style: const pw.TextStyle(fontSize: 16),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '6. CATATAN',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: brandGreen,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  narrative,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Footer
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            'Dokumen ini digenerate otomatis oleh sistem KASENTRA',
            style: pw.TextStyle(
              fontSize: 8,
              color: brandGreen,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
