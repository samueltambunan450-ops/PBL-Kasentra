import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaksi.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
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

  List<Transaksi> _filtered = const [];
  List<int> _saldoKumulatif = const [];

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaksi != widget.transaksi ||
        oldWidget.role != widget.role) {
      _recompute();
    }
  }

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() {
    final now = DateTime.now();
    final newFiltered = widget.transaksi.where((t) {
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

    // Saldo kumulatif dihitung sekali agar item list tidak O(n²)
    final saldo = List<int>.filled(newFiltered.length, 0, growable: false);
    var acc = 0;
    for (int i = 0; i < newFiltered.length; i++) {
      final trans = newFiltered[i];
      acc += trans.jenis == TransaksiJenis.pemasukan
          ? trans.nominal
          : -trans.nominal;
      saldo[i] = acc;
    }

    setState(() {
      _filtered = newFiltered;
      _saldoKumulatif = saldo;
    });
  }

  String _formatRupiah(int value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonFormField<PeriodeFilter>(
              value: filter,
              decoration: const InputDecoration(
                labelText: 'Filter periode',
                border: InputBorder.none,
              ),
              items: PeriodeFilter.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => filter = v);
                _recompute();
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final t = _filtered[index];
                      final saldoKumulatif = _saldoKumulatif[index];
                      final isUntung = saldoKumulatif >= 0;
                      final warnaSaldo = isUntung
                          ? AppColors.income
                          : AppColors.expense;
                      final isMobile = Responsive.isMobile(context);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHistoryLeading(t),
                                  const SizedBox(height: 12),
                                  _buildHistoryActions(t, warnaSaldo, isUntung),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _buildHistoryLeading(t)),
                                  _buildHistoryActions(t, warnaSaldo, isUntung),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLeading(Transaksi t) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: t.warna.withValues(alpha: 0.15),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.kategori != null && t.kategori!.isNotEmpty
                    ? '${t.kategori} – ${t.keterangan}'
                    : t.keterangan,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${t.tanggal.day} ${_namaBulan(t.tanggal.month)} ${t.tanggal.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Dibuat oleh: ${t.createdByName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              if (t.fotoBukti != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _lihatFoto(t.fotoBukti!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lihat bukti foto',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryActions(Transaksi t, Color warnaSaldo, bool isUntung) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatRupiah(t.nominal),
              style: TextStyle(fontWeight: FontWeight.bold, color: t.warna),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
              onPressed: () => widget.onEdit(t),
              visualDensity: VisualDensity.compact,
            ),
            if (widget.role == UserRole.owner)
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 18,
                  color: AppColors.expense,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hapus transaksi'),
                      content: const Text(
                        'Yakin ingin menghapus transaksi ini?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await widget.onDelete(t.id);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
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
              style: TextStyle(fontSize: 12, color: warnaSaldo),
            ),
          ],
        ),
        if (t.isModalKiriman)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Modal dari Owner',
              style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
            ),
          ),
      ],
    );
  }

  void _lihatFoto(String fotoUrl) {
    // Debug logging
    final fullUrl = ApiService.buildFotoUrl(fotoUrl);
    print('🔍 DEBUG Foto: relativePath=$fotoUrl');
    print('🔍 DEBUG Foto: fullUrl=$fullUrl');
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                  errorBuilder: (context, error, stackTrace) {
                    // Debug error
                    print('❌ ERROR Loading Image: $error');
                    print('❌ URL: $fullUrl');
                    print('❌ StackTrace: $stackTrace');
                    
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Foto tidak dapat dimuat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kemungkinan penyebab:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• File foto tidak ditemukan di server\n'
                                  '• Laravel server tidak running (php artisan serve)\n'
                                  '• Koneksi jaringan bermasalah',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red.shade800,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'URL: $fullUrl',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}
