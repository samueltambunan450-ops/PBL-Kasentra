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

/// penyimpanan sederhana (in-memory) untuk data kategori.
/// Owner dapat menambah/ubah/hapus kategori.
class KategoriRepository {
  KategoriRepository._internal();

  static final KategoriRepository instance = KategoriRepository._internal();

  final List<Kategori> _data = [
    // kategori global (cabangId null)
    Kategori(id: '1', nama: 'Operasional', tipe: KategoriType.pengeluaran),
    Kategori(id: '2', nama: 'Gaji', tipe: KategoriType.pengeluaran),
    Kategori(id: '3', nama: 'Lainnya', tipe: KategoriType.pengeluaran),
    Kategori(id: '4', nama: 'Penjualan', tipe: KategoriType.pemasukan),
    // kategori spesifik cabang (contoh untuk cabang '1')
    Kategori(id: '5', nama: 'Biaya Transport', tipe: KategoriType.pengeluaran, cabangId: '1'),
    Kategori(id: '6', nama: 'Penjualan Online', tipe: KategoriType.pemasukan, cabangId: '1'),
  ];

  List<Kategori> get all => List.unmodifiable(_data);

  List<Kategori> get pemasukan =>
      _data.where((k) => k.tipe == KategoriType.pemasukan).toList();

  List<Kategori> get pengeluaran =>
      _data.where((k) => k.tipe == KategoriType.pengeluaran).toList();

  // Filter kategori berdasarkan cabang (global + spesifik cabang)
  List<Kategori> getKategoriByCabang(String? cabangId) {
    return _data.where((k) => k.cabangId == null || k.cabangId == cabangId).toList();
  }

  void add(String nama, KategoriType tipe, {String? cabangId}) {
    final newCat = Kategori(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      tipe: tipe,
      cabangId: cabangId,
    );
    _data.add(newCat);
  }

  void update(String id, String nama) {
    final idx = _data.indexWhere((k) => k.id == id);
    if (idx == -1) return;
    final old = _data[idx];
    _data[idx] = Kategori(id: old.id, nama: nama, tipe: old.tipe);
  }

  void delete(String id) {
    _data.removeWhere((k) => k.id == id);
  }
}
