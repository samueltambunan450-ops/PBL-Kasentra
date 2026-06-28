

import 'package:flutter/material.dart';

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
  final String? fotoBukti;
  final bool isModalKiriman;
  final String createdByName; // Nama pembuat transaksi

  Transaksi({
    required this.id,
    required this.tanggal,
    required this.nominal,
    required this.keterangan,
    this.kategori,
    required this.jenis,
    required this.cabangId,
    required this.userId,
    this.fotoBukti,
    this.isModalKiriman = false,
    this.createdByName = 'Tidak diketahui',
  });

  // Factory untuk membuat Transaksi dari Map
  factory Transaksi.fromMap(Map<String, dynamic> map) {
    final jenisValue = map['jenis'];
    final jenis = jenisValue is int
        ? TransaksiJenis.values[jenisValue]
        : (jenisValue?.toString() == 'pemasukan'
            ? TransaksiJenis.pemasukan
            : TransaksiJenis.pengeluaran);

    final isModalValue = map['is_modal_kiriman'] ?? map['isModalKiriman'];
    final isModal = isModalValue == true ||
        isModalValue?.toString().toLowerCase() == 'true' ||
        isModalValue?.toString() == '1';

    return Transaksi(
      id: map['id']?.toString() ?? '',
      tanggal: DateTime.parse(map['tanggal'].toString()),
      nominal: int.tryParse(map['nominal'].toString()) ?? 0,
      keterangan: map['keterangan']?.toString() ?? '',
      kategori: map['kategori'] is Map<String, dynamic>
          ? (map['kategori']['nama']?.toString() ?? '')
          : map['kategori']?.toString(),
      jenis: jenis,
      cabangId: map['cabangId']?.toString() ?? map['cabang_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      fotoBukti: map['foto_bukti']?.toString(),
      isModalKiriman: isModal,
      createdByName: map['created_by_name']?.toString() ?? 
                     (map['user'] is Map ? map['user']['name']?.toString() : null) ?? 
                     'Tidak diketahui',
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
      'foto_bukti': fotoBukti,
      'is_modal_kiriman': isModalKiriman,
      'created_by_name': createdByName,
    };
  }

  Color get warna {
    return jenis == TransaksiJenis.pemasukan ? Colors.green : Colors.red;
  }
}


