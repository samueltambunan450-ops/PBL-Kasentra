import '../models/cabang.dart';
import '../models/kategori.dart';
import '../models/transaksi.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class DomainApiService {
  DomainApiService._();

  static Future<List<Cabang>> fetchCabangs() async {
    final response = await ApiService.get('/cabangs', token: AuthService.token) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
    return list.map((e) => Cabang.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Cabang> createCabang({
    required String nama,
    required String alamat,
    required double modalAwal,
  }) async {
    final response = await ApiService.post(
      '/cabangs',
      token: AuthService.token,
      body: {
        'nama': nama,
        'alamat': alamat,
        'modal_awal': modalAwal,
      },
    ) as Map<String, dynamic>;
    return Cabang.fromJson(response['data'] as Map<String, dynamic>);
  }

  static Future<Cabang> updateCabang(
    String id, {
    required String nama,
    required String alamat,
    required double modalAwal,
  }) async {
    final response = await ApiService.put(
      '/cabangs/$id',
      token: AuthService.token,
      body: {
        'nama': nama,
        'alamat': alamat,
        'modal_awal': modalAwal,
      },
    ) as Map<String, dynamic>;
    return Cabang.fromJson(response['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteCabang(String id) async {
    await ApiService.delete('/cabangs/$id', token: AuthService.token);
  }

  static Future<List<Kategori>> fetchKategoris() async {
    final response = await ApiService.get('/kategoris', token: AuthService.token) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
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

  static Future<Kategori> createKategori({
    required String nama,
    required String tipe,
    String? cabangId,
  }) async {
    final response = await ApiService.post(
      '/kategoris',
      token: AuthService.token,
      body: {
        'nama': nama,
        'tipe': tipe,
        'cabang_id': cabangId == null ? null : int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    final m = response['data'] as Map<String, dynamic>;
    return Kategori(
      id: m['id'].toString(),
      nama: (m['nama'] ?? '').toString(),
      tipe: m['tipe'] == 'pemasukan' ? KategoriType.pemasukan : KategoriType.pengeluaran,
      cabangId: m['cabang_id']?.toString(),
    );
  }

  static Future<Kategori> updateKategori(
    String id, {
    required String nama,
    required String tipe,
    String? cabangId,
  }) async {
    final response = await ApiService.put(
      '/kategoris/$id',
      token: AuthService.token,
      body: {
        'nama': nama,
        'tipe': tipe,
        'cabang_id': cabangId == null ? null : int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    final m = response['data'] as Map<String, dynamic>;
    return Kategori(
      id: m['id'].toString(),
      nama: (m['nama'] ?? '').toString(),
      tipe: m['tipe'] == 'pemasukan' ? KategoriType.pemasukan : KategoriType.pengeluaran,
      cabangId: m['cabang_id']?.toString(),
    );
  }

  static Future<void> deleteKategori(String id) async {
    await ApiService.delete('/kategoris/$id', token: AuthService.token);
  }

  static Future<List<Transaksi>> fetchTransaksis() async {
    final response = await ApiService.get('/transaksis', token: AuthService.token) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
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
    final response = await ApiService.get('/karyawans', token: AuthService.token) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return AppUser(
        id: m['id'].toString(),
        nama: (m['name'] ?? '').toString(),
        email: (m['email'] ?? '').toString(),
        googleId: (m['google_uid'] ?? '').toString(),
        role: m['role'] == 'owner' ? UserRole.owner : UserRole.karyawan,
        cabangId: m['cabang_id']?.toString(),
      );
    }).toList();
  }

  static Future<AppUser> createKaryawan({
    required String nama,
    required String email,
    required String cabangId,
  }) async {
    final response = await ApiService.post(
      '/karyawans',
      token: AuthService.token,
      body: {
        'name': nama,
        'email': email,
        'cabang_id': int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    final m = response['data'] as Map<String, dynamic>;
    return AppUser(
      id: m['id'].toString(),
      nama: (m['name'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      googleId: (m['google_uid'] ?? '').toString(),
      role: m['role'] == 'owner' ? UserRole.owner : UserRole.karyawan,
      cabangId: m['cabang_id']?.toString(),
    );
  }

  static Future<AppUser> updateKaryawan(
    String id, {
    required String nama,
    required String email,
    required String cabangId,
  }) async {
    final response = await ApiService.put(
      '/karyawans/$id',
      token: AuthService.token,
      body: {
        'name': nama,
        'email': email,
        'cabang_id': int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    final m = response['data'] as Map<String, dynamic>;
    return AppUser(
      id: m['id'].toString(),
      nama: (m['name'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      googleId: (m['google_uid'] ?? '').toString(),
      role: m['role'] == 'owner' ? UserRole.owner : UserRole.karyawan,
      cabangId: m['cabang_id']?.toString(),
    );
  }

  static Future<void> deleteKaryawan(String id) async {
    await ApiService.delete('/karyawans/$id', token: AuthService.token);
  }
}
