class Cabang {
  final String id;
  final String nama;
  final String alamat;
  final double modalAwal; // Modal awal usaha untuk cabang ini (F007)

  Cabang({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.modalAwal,
  });

  // Factory untuk membuat Cabang dari JSON response API
  factory Cabang.fromJson(Map<String, dynamic> json) {
    return Cabang(
      id: json['id'].toString(),
      nama: (json['nama'] ?? '').toString(),
      alamat: (json['alamat'] ?? '').toString(),
      modalAwal: double.tryParse(json['modal_awal'].toString()) ?? 0,
    );
  }

  // Factory untuk membuat Cabang dari Map (untuk database)
  factory Cabang.fromMap(Map<String, dynamic> map) {
    return Cabang(
      id: map['id'],
      nama: map['nama'],
      alamat: map['alamat'],
      modalAwal: map['modalAwal'] ?? 0.0,
    );
  }

  // Method untuk mengubah Cabang ke Map (untuk database)
  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': nama, 'alamat': alamat, 'modalAwal': modalAwal};
  }

  // CopyWith untuk update
  Cabang copyWith({
    String? id,
    String? nama,
    String? alamat,
    double? modalAwal,
  }) {
    return Cabang(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      modalAwal: modalAwal ?? this.modalAwal,
    );
  }
}
