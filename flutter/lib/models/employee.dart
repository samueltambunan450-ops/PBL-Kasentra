import 'package:intl/intl.dart';

class Employee {
  final String id;
  final String branchId;
  final String branchHeadId;
  final String nama;
  final String jabatan;
  final double gajiPokok;
  final String? branchName;
  final String status; // 'pending' | 'approved' | 'rejected'

  Employee({
    required this.id,
    required this.branchId,
    required this.branchHeadId,
    required this.nama,
    required this.jabatan,
    required this.gajiPokok,
    this.branchName,
    this.status = 'pending',
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      branchId: json['branch_id'].toString(),
      branchHeadId: json['branch_head_id'].toString(),
      nama: (json['nama'] ?? '').toString(),
      jabatan: (json['jabatan'] ?? '').toString(),
      gajiPokok: double.tryParse(json['gaji_pokok'].toString()) ?? 0.0,
      branchName: json['branch_name']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'branch_head_id': branchHeadId,
      'nama': nama,
      'jabatan': jabatan,
      'gaji_pokok': gajiPokok,
      'status': status,
    };
  }

  Employee copyWith({
    String? id,
    String? branchId,
    String? branchHeadId,
    String? nama,
    String? jabatan,
    double? gajiPokok,
    String? branchName,
    String? status,
  }) {
    return Employee(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchHeadId: branchHeadId ?? this.branchHeadId,
      nama: nama ?? this.nama,
      jabatan: jabatan ?? this.jabatan,
      gajiPokok: gajiPokok ?? this.gajiPokok,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
    );
  }

  String get gajiFormatted {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(gajiPokok);
  }
}
