import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/transaksi.dart';
import '../models/cabang.dart';
import '../models/kategori.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/common_page_scaffold.dart';

class AddTransactionPage extends StatefulWidget {
  final void Function(Transaksi) onSaved;
  final Transaksi? transaksi;
  final bool embedded;

  const AddTransactionPage({
    super.key,
    required this.onSaved,
    this.transaksi,
    this.embedded = false,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late bool _isEditing;
  TransaksiJenis jenis = TransaksiJenis.pemasukan;
  final TextEditingController nominalC = TextEditingController();
  final TextEditingController keteranganC = TextEditingController();
  String? kategori; // selected category for transaksi
  String? _selectedCabangId;
  String? _fotoBuktiPath;
  String? _fotoBuktiBase64;
  bool _isModalKiriman = false;
  bool _sudahAdaPengeluaran = true;
  List<Cabang> _cabangs = [];
  List<Kategori> _kategoris = [];
  DateTime? tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaksi != null;
    if (_isEditing) {
      final t = widget.transaksi!;
      jenis = t.jenis;
      nominalC.text = t.nominal.toString();
      keteranganC.text = t.keterangan;
      kategori = t.kategori;
      tanggal = t.tanggal;
      _selectedCabangId = t.cabangId;
    } else {
      if (!AuthService.isOwner()) {
        _selectedCabangId = AuthService.currentUser?.cabangId;
      }
    }
    _loadReferenceData();
    if (!AuthService.isOwner()) {
      _checkPengeluaranStatus();
    }
  }

  Future<void> _loadReferenceData() async {
    try {
      final fetchedCabangs = await DomainApiService.fetchCabangs();
      final fetchedKategoris = await DomainApiService.fetchKategoris();
      if (!mounted) return;
      setState(() {
        _cabangs = fetchedCabangs;
        _kategoris = fetchedKategoris;
        if (AuthService.isOwner() && _selectedCabangId == null && _cabangs.isNotEmpty) {
          _selectedCabangId = _cabangs.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkPengeluaranStatus() async {
    try {
      final sudahAda = await DomainApiService.cekPengeluaranHariIni();
      if (!mounted) return;
      setState(() => _sudahAdaPengeluaran = sudahAda);
    } catch (_) {
      // Jika gagal cek, biarkan pengguna tetap melanjutkan tanpa memblokir form.
    }
  }

  Cabang? get _selectedCabang {
    if (_selectedCabangId == null) return null;
    final index = _cabangs.indexWhere((c) => c.id == _selectedCabangId);
    if (index == -1) return null;
    return _cabangs[index];
  }

  @override
  void dispose() {
    nominalC.dispose();
    keteranganC.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => tanggal = picked);
    }
  }

  void _simpan() async {
    if (nominalC.text.isEmpty ||
        keteranganC.text.isEmpty ||
        tanggal == null ||
        (kategori == null || kategori!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data transaksi"),
        ),
      );
      return;
    }

    final nominal = int.tryParse(nominalC.text.replaceAll('.', '')) ?? 0;
    if (_selectedCabangId == null || _selectedCabangId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih cabang transaksi terlebih dahulu")),
      );
      return;
    }

    final selectedCabang = _selectedCabang;
    if (!AuthService.isOwner()) {
      if (selectedCabang == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cabang tidak tersedia untuk saat ini")),
        );
        return;
      }
      if (!selectedCabang.isOpen) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cabang sedang tutup. Jam: ${selectedCabang.jamBuka} - ${selectedCabang.jamTutup}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!AuthService.isOwner() && jenis == TransaksiJenis.pemasukan && !_sudahAdaPengeluaran) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catat pengeluaran terlebih dahulu sebelum input pemasukan hari ini.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_fotoBuktiBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti transaksi wajib dilampirkan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final transaksi = Transaksi(
        id: widget.transaksi?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        tanggal: tanggal!,
        nominal: nominal,
        keterangan: keteranganC.text,
        kategori: kategori,
        jenis: jenis,
        cabangId: _selectedCabangId!,
        userId: AuthService.currentUser?.id ?? '2',
      );

      if (!_isEditing) {
        // Create new transaction
        final selectedKategori = _kategoris.firstWhere(
          (k) => k.nama == kategori,
          orElse: () => throw Exception('Kategori tidak ditemukan'),
        );
        final kategoriId = selectedKategori.id;

        await DomainApiService.createTransaksi(
          transaksi,
          kategoriId: kategoriId,
          fotoBuktiBase64: _fotoBuktiBase64,
          isModalKiriman: _isModalKiriman,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaksi berhasil ditambahkan"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing transaction
        final selectedKategori = _kategoris.firstWhere(
          (k) => k.nama == kategori,
          orElse: () => throw Exception('Kategori tidak ditemukan'),
        );
        final kategoriId = selectedKategori.id;

        await ApiService.put(
          '/transaksis/${transaksi.id}',
          token: AuthService.token,
          body: {
            'cabang_id': int.parse(transaksi.cabangId),
            'kategori_id': int.parse(kategoriId),
            'jenis': transaksi.jenis == TransaksiJenis.pemasukan
                ? 'pemasukan'
                : 'pengeluaran',
            'nominal': transaksi.nominal,
            'tanggal': transaksi.tanggal.toIso8601String().substring(0, 10),
            'keterangan': transaksi.keterangan,
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaksi berhasil diperbarui"),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        widget.onSaved(transaksi);
        if (widget.embedded) {
          _resetForm();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan transaksi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTanggal(DateTime? t) {
    if (t == null) return "--------------";
    const bulan = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    return "${t.day} ${bulan[t.month]} ${t.year}";
  }

  String _formatNominalPreview() {
    final raw = nominalC.text.replaceAll('.', '');
    final value = int.tryParse(raw);
    if (value == null) return 'Rp 0';
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final form = _buildForm(context);
    final title = _isEditing ? 'Edit Transaksi' : 'Tambah Transaksi';

    if (widget.embedded) {
      return CommonPageScaffold(
        title: title,
        subtitle: 'Catat pemasukan atau pengeluaran',
        body: form,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      backgroundColor: AppColors.surface,
      body: ResponsiveContent(
        maxWidth: Responsive.formMaxWidth(context),
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: form,
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    jenis = TransaksiJenis.pemasukan;
                                    kategori = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: jenis == TransaksiJenis.pemasukan
                                        ? Colors.green
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Pemasukan",
                                      style: TextStyle(
                                        color: jenis ==
                                                TransaksiJenis.pemasukan
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    jenis = TransaksiJenis.pengeluaran;
                                    kategori = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: jenis ==
                                            TransaksiJenis.pengeluaran
                                        ? Colors.green
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Pengeluaran",
                                      style: TextStyle(
                                        color: jenis ==
                                                TransaksiJenis.pengeluaran
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _formatNominalPreview(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.value(context, mobile: 24.0, tablet: 28.0, desktop: 32.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Nominal",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nominalC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Masukkan jumlah uang",
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Tanggal",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pilihTanggal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatTanggal(tanggal),
                                style: TextStyle(
                                  color: tanggal == null
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              Icon(Icons.calendar_today_outlined,
                                  size: 18, color: Colors.grey[700]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (AuthService.isOwner()) ...[
                        const Text("Cabang", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCabangId,
                          items: _cabangs
                              .map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.nama)))
                              .toList(),
                          decoration: const InputDecoration(),
                          onChanged: (v) => setState(() {
                            _selectedCabangId = v;
                            kategori = null;
                          }),
                          hint: const Text('Pilih cabang'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildKategoriField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCatatanField()),
                          ],
                        )
                      else ...[
                        _buildKategoriField(),
                        const SizedBox(height: 16),
                        _buildCatatanField(),
                      ],
                      const SizedBox(height: 16),
                      const Text("Foto Bukti", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      const SizedBox(height: 8),
                      if (_fotoBuktiPath != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_fotoBuktiPath!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _fotoBuktiPath = null;
                                  _fotoBuktiBase64 = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _ambilFoto,
                                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                label: const Text('Kamera'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _ambilDariGaleri,
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: const Text('Galeri'),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      if (AuthService.isOwner())
                        Row(
                          children: [
                            Switch(
                              value: _isModalKiriman,
                              onChanged: (v) => setState(() => _isModalKiriman = v),
                              activeColor: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Ini adalah kiriman modal ke cabang'),
                          ],
                        ),
                      if (!AuthService.isOwner() && jenis == TransaksiJenis.pemasukan && !_sudahAdaPengeluaran)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Anda belum mencatat pengeluaran hari ini. Catat pengeluaran terlebih dahulu.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _simpan,
                                    child: Text(_isEditing ? "Perbarui" : "Selesai"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    child: const Text("Batal"),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _simpan,
                                    child: Text(_isEditing ? "Perbarui" : "Selesai"),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    child: const Text("Batal"),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 12),
                    ],
                  ),
    );
  }

  Widget _buildKategoriField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kategori", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: kategori,
          items: _kategoris
              .where((k) {
                final matchesType = k.tipe == (jenis == TransaksiJenis.pemasukan
                    ? KategoriType.pemasukan
                    : KategoriType.pengeluaran);
                final matchesScope = k.scope == KategoriScope.global ||
                    (k.cabangId != null && k.cabangId == _selectedCabangId);
                return matchesType && matchesScope;
              })
              .map((k) => DropdownMenuItem(value: k.nama, child: Text(k.nama)))
              .toList(),
          decoration: const InputDecoration(),
          onChanged: (v) => setState(() => kategori = v),
          hint: const Text('Pilih kategori'),
        ),
      ],
    );
  }

  Widget _buildCatatanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Catatan", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: keteranganC,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Contoh: Penjualan harian, listrik, dll.",
          ),
        ),
      ],
    );
  }

  Future<void> _ambilFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _fotoBuktiPath = picked.path;
      _fotoBuktiBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _ambilDariGaleri() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _fotoBuktiPath = picked.path;
      _fotoBuktiBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  void _resetForm() {
    setState(() {
      jenis = TransaksiJenis.pemasukan;
      nominalC.clear();
      keteranganC.clear();
      kategori = null;
      tanggal = DateTime.now();
      _selectedCabangId = AuthService.currentUser?.cabangId;
      _fotoBuktiBase64 = null;
      _fotoBuktiPath = null;
      _isModalKiriman = false;
    });
  }
}


