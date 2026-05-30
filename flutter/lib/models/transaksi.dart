

import 'package:flutter/material.dart';

enum TransaksiJenis { pemasukan, pengeluaran }

class Transaksi {
  final String id;
  final DateTime tanggal;
  final int nominal;
  final String keterangan;
  final String?
  kategori; // kategori untuk laporan (operasional, gaji, lain-lain)
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
    return jenis == TransaksiJenis.pemasukan ? Colors.green : Colors.red;
  }
}


