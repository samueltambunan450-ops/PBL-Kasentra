enum KategoriType { pemasukan, pengeluaran }
enum KategoriScope { global, cabang }

class Kategori {
  final String id;
  final String nama;
  final KategoriType tipe;
  final KategoriScope scope;
  final String? cabangId;
  final String? cabangNama;

  Kategori({
    required this.id,
    required this.nama,
    required this.tipe,
    required this.scope,
    this.cabangId,
    this.cabangNama,
  });

  // Factory untuk membuat Kategori dari Map
  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      id: map['id']?.toString() ?? '',
      nama: map['nama'] ?? '',
      tipe: map['jenis'] == 'pemasukan' || map['tipe'] == 0 || map['tipe'] == 'pemasukan'
          ? KategoriType.pemasukan
          : KategoriType.pengeluaran,
      scope: map['scope'] == 'cabang' || map['scope'] == 1 || map['scope'] == 'cabang'
          ? KategoriScope.cabang
          : KategoriScope.global,
      cabangId: map['cabang_id']?.toString() ?? map['cabangId']?.toString(),
      cabangNama: map['cabang'] != null ? map['cabang']['nama']?.toString() : map['cabangNama']?.toString(),
    );
  }

  // Method untuk mengubah Kategori ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'jenis': tipe == KategoriType.pemasukan ? 'pemasukan' : 'pengeluaran',
      'scope': scope == KategoriScope.cabang ? 'cabang' : 'global',
      'cabang_id': cabangId,
      'cabangNama': cabangNama,
    };
  }

  // CopyWith untuk update
  Kategori copyWith({
    String? id,
    String? nama,
    KategoriType? tipe,
    KategoriScope? scope,
    String? cabangId,
    String? cabangNama,
  }) {
    return Kategori(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
      scope: scope ?? this.scope,
      cabangId: cabangId ?? this.cabangId,
      cabangNama: cabangNama ?? this.cabangNama,
    );
  }
}
