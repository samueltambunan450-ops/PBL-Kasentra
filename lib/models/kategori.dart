enum KategoriType { pemasukan, pengeluaran }

class Kategori {
  final String id;
  final String nama;
  final KategoriType tipe;
  final String? cabangId; // Jika null, kategori global; jika ada, spesifik per cabang

  Kategori({
    required this.id,
    required this.nama,
    required this.tipe,
    this.cabangId,
  });

  // Factory untuk membuat Kategori dari Map
  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id'],
      nama: map['nama'],
      tipe: KategoriType.values[map['tipe']],
      cabangId: map['cabangId'],
    );
  }

  // Method untuk mengubah Kategori ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'tipe': tipe.index,
      'cabangId': cabangId,
    };
  }

  // CopyWith untuk update
  Kategori copyWith({
    String? id,
    String? nama,
    KategoriType? tipe,
    String? cabangId,
  }) {
    return Kategori(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
      cabangId: cabangId ?? this.cabangId,
    );
  }
}

