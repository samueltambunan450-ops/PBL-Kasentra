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
    String? jamBuka,
    String? jamTutup,
  }) async {
    final response = await ApiService.post(
      '/cabangs',
      token: AuthService.token,
      body: {
        'nama': nama,
        'alamat': alamat,
        'modal_awal': modalAwal,
        'jam_buka': jamBuka,
        'jam_tutup': jamTutup,
      },
    ) as Map<String, dynamic>;
    return Cabang.fromJson(response['data'] as Map<String, dynamic>);
  }

  static Future<Cabang> updateCabang(
    String id, {
    required String nama,
    required String alamat,
    required double modalAwal,
    String? jamBuka,
    String? jamTutup,
  }) async {
    final response = await ApiService.put(
      '/cabangs/$id',
      token: AuthService.token,
      body: {
        'nama': nama,
        'alamat': alamat,
        'modal_awal': modalAwal,
        'jam_buka': jamBuka,
        'jam_tutup': jamTutup,
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
    return list.map((e) => Kategori.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<Kategori> createKategori({
    required String nama,
    required String jenis,
    required String scope,
    String? cabangId,
  }) async {
    final response = await ApiService.post(
      '/kategoris',
      token: AuthService.token,
      body: {
        'nama': nama,
        'jenis': jenis,
        'scope': scope,
        'cabang_id': cabangId == null ? null : int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    return Kategori.fromMap(response['data'] as Map<String, dynamic>);
  }

  static Future<Kategori> updateKategori(
    String id, {
    required String nama,
    required String jenis,
    required String scope,
    String? cabangId,
  }) async {
    final response = await ApiService.put(
      '/kategoris/$id',
      token: AuthService.token,
      body: {
        'nama': nama,
        'jenis': jenis,
        'scope': scope,
        'cabang_id': cabangId == null ? null : int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    return Kategori.fromMap(response['data'] as Map<String, dynamic>);
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
        kategori: (m['kategori'] is Map<String, dynamic>)
            ? (m['kategori']['nama'] ?? '').toString()
            : m['kategori']?.toString(),
        jenis: m['jenis'] == 'pemasukan' ? TransaksiJenis.pemasukan : TransaksiJenis.pengeluaran,
        cabangId: m['cabang_id'].toString(),
        userId: m['user_id'].toString(),
        fotoBukti: m['foto_bukti']?.toString(),
        isModalKiriman: m['is_modal_kiriman'] == true || m['is_modal_kiriman']?.toString() == '1' || m['is_modal_kiriman']?.toString().toLowerCase() == 'true',
      );
    }).toList();
  }

  static Future<void> createTransaksi(
    Transaksi t, {
    String? kategoriId,
    String? fotoBuktiBase64,
    bool isModalKiriman = false,
  }) async {
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
        'foto_bukti': fotoBuktiBase64,
        'is_modal_kiriman': isModalKiriman,
      },
    );
  }

  static Future<bool> cekPengeluaranHariIni() async {
    final response = await ApiService.get(
      '/transaksis/cek-pengeluaran-hari-ini',
      token: AuthService.token,
    ) as Map<String, dynamic>;
    return response['sudah_ada_pengeluaran'] == true;
  }

  static Future<void> updateJamOperasional(
    String cabangId, {
    required String jamBuka,
    required String jamTutup,
  }) async {
    await ApiService.put(
      '/cabangs/$cabangId/jam-operasional',
      token: AuthService.token,
      body: {
        'jam_buka': jamBuka,
        'jam_tutup': jamTutup,
      },
    );
  }

  static Future<void> deleteTransaksi(String id) async {
    await ApiService.delete('/transaksis/$id', token: AuthService.token);
  }

  static Future<List<AppUser>> fetchKaryawans() async {
    final response = await ApiService.get('/karyawans', token: AuthService.token) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
    return list.map((e) => AppUser.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<List<AppUser>> fetchKepalaCabangs() async {
    final response = await ApiService.get(
      '/users/kepala-cabang',
      token: AuthService.token,
    ) as Map<String, dynamic>;
    final list = response['data'] as List<dynamic>;
    return list.map((e) => AppUser.fromMap(e as Map<String, dynamic>)).toList();
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
    return AppUser.fromMap(response['data'] as Map<String, dynamic>);
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
    return AppUser.fromMap(response['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteKaryawan(String id) async {
    await ApiService.delete('/karyawans/$id', token: AuthService.token);
  }

  static Future<void> deleteKepalaCabang(String id) async {
    await ApiService.delete('/users/$id', token: AuthService.token);
  }

  static Future<String> generateInvitation({
    required String cabangId,
  }) async {
    final response = await ApiService.post(
      '/auth/invitation/generate',
      token: AuthService.token,
      body: {
        'cabang_id': int.tryParse(cabangId),
      },
    ) as Map<String, dynamic>;
    return response['code']?.toString() ?? '';
  }

  static Future<AppUser> validateInvitation(String code) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || currentUser.id.isEmpty || currentUser.email.isEmpty) {
      throw Exception('Pengguna belum terautentikasi untuk validasi undangan.');
    }

    final response = await ApiService.post(
      '/auth/invitation/validate',
      token: AuthService.token,
      body: {
        'code': code,
        'google_uid': currentUser.id,
        'email': currentUser.email,
      },
    ) as Map<String, dynamic>;
    return AppUser.fromMap(response['user'] as Map<String, dynamic>);
  }

  static Future<AppUser> setupBusiness({
    required String businessName,
    required String businessType,
    required String branchName,
  }) async {
    final response = await ApiService.post(
      '/auth/setup-business',
      token: AuthService.token,
      body: {
        'business_name': businessName,
        'business_type': businessType,
        'branch_name': branchName,
      },
    ) as Map<String, dynamic>;
    return AppUser.fromMap(response['user'] as Map<String, dynamic>);
  }
}
