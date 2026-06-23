import 'package:flutter/material.dart';

class Cabang {
  final String id;
  final String nama;
  final String alamat;
  final double modalAwal;
  final String? jamBuka;
  final String? jamTutup;
  final String? businessId; // nullable — cabang lama tidak punya business_id

  Cabang({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.modalAwal,
    this.jamBuka,
    this.jamTutup,
    this.businessId,
  });

  factory Cabang.fromJson(Map<String, dynamic> json) {
    return Cabang(
      id: json['id'].toString(),
      nama: (json['nama'] ?? '').toString(),
      alamat: (json['alamat'] ?? '').toString(),
      modalAwal: double.tryParse(json['modal_awal'].toString()) ?? 0,
      jamBuka: json['jam_buka']?.toString(),
      jamTutup: json['jam_tutup']?.toString(),
      businessId: json['business_id']?.toString(),
    );
  }

  factory Cabang.fromMap(Map<String, dynamic> map) {
    return Cabang(
      id: map['id'],
      nama: map['nama'],
      alamat: map['alamat'],
      modalAwal: map['modalAwal'] ?? 0.0,
      jamBuka: map['jam_buka']?.toString() ?? map['jamBuka']?.toString(),
      jamTutup: map['jam_tutup']?.toString() ?? map['jamTutup']?.toString(),
      businessId: map['business_id']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'modalAwal': modalAwal,
      'jamBuka': jamBuka,
      'jamTutup': jamTutup,
      'businessId': businessId,
    };
  }

  Cabang copyWith({
    String? id,
    String? nama,
    String? alamat,
    double? modalAwal,
    String? jamBuka,
    String? jamTutup,
    String? businessId,
  }) {
    return Cabang(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      modalAwal: modalAwal ?? this.modalAwal,
      jamBuka: jamBuka ?? this.jamBuka,
      jamTutup: jamTutup ?? this.jamTutup,
      businessId: businessId ?? this.businessId,
    );
  }

  bool get isOpen {
    if (jamBuka == null || jamTutup == null) return true;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final buka = _parseTime(jamBuka!);
    final tutup = _parseTime(jamTutup!);
    if (buka == null || tutup == null) return true;
    return nowMinutes >= (buka.hour * 60 + buka.minute) &&
        nowMinutes <= (tutup.hour * 60 + tutup.minute);
  }

  TimeOfDay? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}
