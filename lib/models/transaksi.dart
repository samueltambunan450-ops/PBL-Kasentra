import 'package:flutter/material.dart';
import 'cabang.dart';

enum TransaksiJenis { pemasukan, pengeluaran }

class Transaksi {
  final String id;
  final DateTime tanggal;
  final int nominal;
  final String keterangan;
  final String? kategori; // kategori untuk laporan (operasional, gaji, lain-lain)
  final TransaksiJenis jenis;
  final String cabangId; // ID cabang tempat transaksi terjadi
  final String userId; // ID user yang menambah transaksi

  Transaksi({
    required this.id,
    required this.tanggal,
    required this.nominal,
    required this.keterangan,
    this.kategori,
    required this.jenis,
    required this.cabangId,
    required this.userId,
  });

  // Factory untuk membuat Transaksi dari Map
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      tanggal: DateTime.parse(map['tanggal']),
      nominal: map['nominal'],
      keterangan: map['keterangan'],
      kategori: map['kategori'],
      jenis: TransaksiJenis.values[map['jenis']],
      cabangId: map['cabangId'],
      userId: map['userId'],
    );
  }

  // Method untuk mengubah Transaksi ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'nominal': nominal,
      'keterangan': keterangan,
      'kategori': kategori,
      'jenis': jenis.index,
      'cabangId': cabangId,
      'userId': userId,
    };
  }

  Color get warna {
    return jenis == TransaksiJenis.pemasukan
        ? Colors.green
        : Colors.red;
  }
}

/// Repository sederhana di memori untuk menyimpan data transaksi.
/// Digunakan oleh halaman tambah transaksi, history, dan laporan.
class TransaksiRepository {
  TransaksiRepository._internal();

  static final TransaksiRepository instance = TransaksiRepository._internal();

  final List<Transaksi> _transaksis = [
    // Contoh data transaksi
    Transaksi(
      id: '1',
      tanggal: DateTime.now().subtract(Duration(days: 1)),
      nominal: 500000,
      keterangan: 'Penjualan produk',
      kategori: 'Penjualan',
      jenis: TransaksiJenis.pemasukan,
      cabangId: '1',
      userId: '2', // Karyawan
    ),
    Transaksi(
      id: '2',
      tanggal: DateTime.now().subtract(Duration(days: 1)),
      nominal: 100000,
      keterangan: 'Beli bahan baku',
      kategori: 'Operasional',
      jenis: TransaksiJenis.pengeluaran,
      cabangId: '1',
      userId: '2',
    ),
  ];

  List<Transaksi> get transaksis => List.unmodifiable(_transaksis);

  // Filter transaksi berdasarkan cabang
  List<Transaksi> getTransaksiByCabang(String cabangId) {
    return _transaksis.where((t) => t.cabangId == cabangId).toList();
  }

  // Filter transaksi berdasarkan periode
  List<Transaksi> getTransaksiByPeriode(DateTime start, DateTime end) {
    return _transaksis.where((t) => t.tanggal.isAfter(start.subtract(Duration(days: 1))) && t.tanggal.isBefore(end.add(Duration(days: 1)))).toList();
  }

  // Hitung total pemasukan
  int getTotalPemasukan([String? cabangId, DateTime? start, DateTime? end]) {
    var filtered = _transaksis.where((t) => t.jenis == TransaksiJenis.pemasukan);
    if (cabangId != null) filtered = filtered.where((t) => t.cabangId == cabangId);
    if (start != null && end != null) filtered = filtered.where((t) => t.tanggal.isAfter(start.subtract(Duration(days: 1))) && t.tanggal.isBefore(end.add(Duration(days: 1))));
    return filtered.fold(0, (sum, t) => sum + t.nominal);
  }

  // Hitung total pengeluaran
  int getTotalPengeluaran([String? cabangId, DateTime? start, DateTime? end]) {
    var filtered = _transaksis.where((t) => t.jenis == TransaksiJenis.pengeluaran);
    if (cabangId != null) filtered = filtered.where((t) => t.cabangId == cabangId);
    if (start != null && end != null) filtered = filtered.where((t) => t.tanggal.isAfter(start.subtract(Duration(days: 1))) && t.tanggal.isBefore(end.add(Duration(days: 1))));
    return filtered.fold(0, (sum, t) => sum + t.nominal);
  }

  // Hitung saldo (pemasukan - pengeluaran + modal awal)
  double getSaldo(String cabangId, [DateTime? start, DateTime? end]) {
    final modalAwal = CabangRepository.instance.cabangs.firstWhere((c) => c.id == cabangId).modalAwal;
    final pemasukan = getTotalPemasukan(cabangId, start, end);
    final pengeluaran = getTotalPengeluaran(cabangId, start, end);
    return modalAwal + pemasukan - pengeluaran;
  }

  void addTransaksi({
    required DateTime tanggal,
    required int nominal,
    required String keterangan,
    String? kategori,
    required TransaksiJenis jenis,
    required String cabangId,
    required String userId,
  }) {
    final newTransaksi = Transaksi(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tanggal: tanggal,
      nominal: nominal,
      keterangan: keterangan,
      kategori: kategori,
      jenis: jenis,
      cabangId: cabangId,
      userId: userId,
    );
    _transaksis.add(newTransaksi);
  }

  // Karyawan tidak bisa edit/hapus, jadi method ini untuk owner saja
  void updateTransaksi(String id, {
    required DateTime tanggal,
    required int nominal,
    required String keterangan,
    String? kategori,
    required TransaksiJenis jenis,
  }) {
    final idx = _transaksis.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _transaksis[idx] = Transaksi(
      id: id,
      tanggal: tanggal,
      nominal: nominal,
      keterangan: keterangan,
      kategori: kategori,
      jenis: jenis,
      cabangId: _transaksis[idx].cabangId,
      userId: _transaksis[idx].userId,
    );
  }

  void deleteTransaksi(String id) {
    _transaksis.removeWhere((t) => t.id == id);
  }
}


