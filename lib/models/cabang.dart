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
    return {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'modalAwal': modalAwal,
    };
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

/// Repository sederhana di memori untuk menyimpan data cabang.
/// Digunakan oleh halaman kelola cabang dan dashboard.
class CabangRepository {
  CabangRepository._internal();

  static final CabangRepository instance = CabangRepository._internal();

  final List<Cabang> _cabangs = [
    Cabang(
      id: '1',
      nama: 'Cabang Pusat',
      alamat: 'Jl. Contoh No. 1',
      modalAwal: 10000000.0, // Modal awal contoh
    ),
    Cabang(
      id: '2',
      nama: 'Cabang Selatan',
      alamat: 'Jl. Selatan No. 2',
      modalAwal: 8000000.0,
    ),
    Cabang(
      id: '3',
      nama: 'Cabang Timur',
      alamat: 'Jl. Timur No. 3',
      modalAwal: 9000000.0,
    ),
  ];

  List<Cabang> get cabangs => List.unmodifiable(_cabangs);

  void addCabang({
    required String nama,
    required String alamat,
    required double modalAwal,
  }) {
    final newCabang = Cabang(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      alamat: alamat,
      modalAwal: modalAwal,
    );
    _cabangs.add(newCabang);
  }

  void updateCabang(String id, String nama, String alamat, double modalAwal) {
    final idx = _cabangs.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _cabangs[idx] = _cabangs[idx].copyWith(
      nama: nama,
      alamat: alamat,
      modalAwal: modalAwal,
    );
  }

  void deleteCabang(String id) {
    _cabangs.removeWhere((c) => c.id == id);
  }

  // Method untuk menghitung saldo total cabang (modal + pemasukan - pengeluaran)
  // Asumsi ada repository transaksi yang bisa filter per cabang
  double getSaldoCabang(String cabangId) {
    final cabang = _cabangs.firstWhere((c) => c.id == cabangId);
    // TODO: Integrasikan dengan TransaksiRepository untuk hitung saldo
    // Contoh sederhana: return cabang.modalAwal + totalPemasukan - totalPengeluaran
    return cabang.modalAwal; // Placeholder
  }
}