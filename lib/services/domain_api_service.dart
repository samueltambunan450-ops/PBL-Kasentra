import '../models/cabang.dart';
import '../models/kategori.dart';
import '../models/transaksi.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DomainApiService {
  DomainApiService._();

  static Future<List<Cabang>> fetchCabangs() async {
    final list = await ApiService.get('/cabangs', token: AuthService.token) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return Cabang(
        id: m['id'].toString(),
        nama: (m['nama'] ?? '').toString(),
        alamat: (m['alamat'] ?? '').toString(),
        modalAwal: double.tryParse(m['modal_awal'].toString()) ?? 0,
      );
    }).toList();
  }

  static Future<List<Kategori>> fetchKategoris() async {
    final list = await ApiService.get('/kategoris', token: AuthService.token) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return Kategori(
        id: m['id'].toString(),
        nama: (m['nama'] ?? '').toString(),
        tipe: m['tipe'] == 'pemasukan' ? KategoriType.pemasukan : KategoriType.pengeluaran,
        cabangId: m['cabang_id']?.toString(),
      );
    }).toList();
  }

  static Future<List<Transaksi>> fetchTransaksis() async {
    final list = await ApiService.get('/transaksis', token: AuthService.token) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return Transaksi(
        id: m['id'].toString(),
        tanggal: DateTime.parse(m['tanggal'].toString()),
        nominal: int.tryParse(m['nominal'].toString()) ?? 0,
        keterangan: (m['keterangan'] ?? '').toString(),
        kategori: (m['kategori'] is Map<String, dynamic>) ? (m['kategori']['nama'] ?? '').toString() : null,
        jenis: m['jenis'] == 'pemasukan' ? TransaksiJenis.pemasukan : TransaksiJenis.pengeluaran,
        cabangId: m['cabang_id'].toString(),
        userId: m['user_id'].toString(),
      );
    }).toList();
  }

  static Future<void> createTransaksi(Transaksi t, {String? kategoriId}) async {
    await ApiService.post(
      '/transaksis',
      token: AuthService.token,
      body: {
        'cabang_id': int.parse(t.cabangId),
        'kategori_id': kategoriId == null ? null : int.parse(kategoriId),
        'jenis': t.jenis == TransaksiJenis.pemasukan ? 'pemasukan' : 'pengeluaran',
        'nominal': t.nominal,
        'tanggal': t.tanggal.toIso8601String().substring(0, 10),
        'keterangan': t.keterangan,
      },
    );
  }

  static Future<void> deleteTransaksi(String id) async {
    await ApiService.delete('/transaksis/$id', token: AuthService.token);
  }

  static Future<List<AppUser>> fetchKaryawans() async {
    final list = await ApiService.get('/karyawans', token: AuthService.token) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return AppUser(
        id: m['id'].toString(),
        nama: (m['name'] ?? '').toString(),
        email: (m['email'] ?? '').toString(),
        googleId: (m['google_uid'] ?? '').toString(),
        role: UserRole.karyawan,
        cabangId: m['cabang_id']?.toString(),
      );
    }).toList();
  }
}
