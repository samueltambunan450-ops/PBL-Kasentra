import 'dart:convert';
import 'dart:typed_data';

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
import '../widgets/kasentra_form_field.dart';

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
  Uint8List? _fotoBuktiBytes;
  String? _fotoBuktiBase64;
  bool _isModalKiriman = false;
  bool _sudahAdaPengeluaran = false;
  List<Cabang> _cabangs = [];
  List<Kategori> _kategoris = [];
  DateTime? tanggal = DateTime.now();
  bool _isLoadingGaji = false; // Loading state untuk auto-hitung gaji
  String? _infoGaji; // Info text untuk Owner tentang kalkulasi gaji

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
        subtitle: 'Catat pemasukan atau pengeluaran harian',
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJenisToggle(),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _formatNominalPreview(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.value(context, mobile: 28.0, tablet: 32.0, desktop: 36.0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const KasentraFormLabel('Nominal'),
            TextField(
              controller: nominalC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Masukkan jumlah uang'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const KasentraFormLabel('Tanggal'),
            GestureDetector(
              onTap: _pilihTanggal,
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _formatTanggal(tanggal),
                  style: TextStyle(color: tanggal == null ? Colors.grey : Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (AuthService.isOwner()) ...[
              const KasentraFormLabel('Cabang'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCabangId,
                items: _cabangs
                    .map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.nama)))
                    .toList(),
                decoration: const InputDecoration(),
                onChanged: (v) {
                  setState(() {
                    _selectedCabangId = v;
                    // Reset kategori saat cabang berubah
                    final oldKategori = kategori;
                    kategori = null;
                    _infoGaji = null;
                    
                    // Jika sebelumnya kategori Gaji, langsung trigger ulang setelah delay
                    if (oldKategori?.toLowerCase() == 'gaji' && v != null) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          setState(() => kategori = oldKategori);
                          _autoFillGaji();
                        }
                      });
                    }
                  });
                },
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
            const KasentraFormLabel('Foto Bukti'),
            KasentraPhotoPicker(
              previewBytes: _fotoBuktiBytes,
              onCamera: _ambilFoto,
              onGallery: _ambilDariGaleri,
              onRemove: () => setState(() {
                _fotoBuktiBytes = null;
                _fotoBuktiBase64 = null;
              }),
            ),
            if (AuthService.isOwner()) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _isModalKiriman,
                    onChanged: (v) => setState(() => _isModalKiriman = v),
                    activeThumbColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Ini adalah kiriman modal ke cabang', style: TextStyle(fontSize: 13))),
                ],
              ),
            ],
            if (!AuthService.isOwner() && jenis == TransaksiJenis.pemasukan && !_sudahAdaPengeluaran) ...[
              const SizedBox(height: 12),
              Container(
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
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _simpan,
                child: Text(
                  _isEditing ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (widget.embedded) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _resetForm,
                  child: const Text('Reset Form'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJenisToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _buildJenisChip(TransaksiJenis.pemasukan, 'Pemasukan')),
          Expanded(child: _buildJenisChip(TransaksiJenis.pengeluaran, 'Pengeluaran')),
        ],
      ),
    );
  }

  Widget _buildJenisChip(TransaksiJenis type, String label) {
    final selected = jenis == type;
    final color = type == TransaksiJenis.pemasukan ? AppColors.income : AppColors.expense;

    return GestureDetector(
      onTap: () {
        setState(() {
          jenis = type;
          kategori = null;
        });
        // Re-check status pengeluaran saat user switch ke "pemasukan"
        if (!AuthService.isOwner() && type == TransaksiJenis.pemasukan) {
          _checkPengeluaranStatus();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKategoriField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KasentraFormLabel('Kategori'),
        DropdownButtonFormField<String>(
          initialValue: kategori,
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
          onChanged: (v) {
            setState(() => kategori = v);
            // Auto-hitung gaji jika kategori Gaji dipilih oleh Owner
            if (v != null && v.toLowerCase() == 'gaji' && 
                AuthService.isOwner() && 
                _selectedCabangId != null) {
              _autoFillGaji();
            } else {
              setState(() {
                _infoGaji = null; // Reset info jika bukan kategori Gaji
              });
            }
          },
          hint: const Text('Pilih kategori'),
        ),
        // Info gaji (ditampilkan saat kategori Gaji dipilih)
        if (_infoGaji != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _infoGaji!,
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Auto-fill nominal saat Owner memilih kategori "Gaji"
  Future<void> _autoFillGaji() async {
    if (_selectedCabangId == null || _isLoadingGaji) return;
    
    setState(() {
      _isLoadingGaji = true;
      _infoGaji = 'Menghitung total gaji karyawan...';
    });

    try {
      final data = await DomainApiService.fetchTotalSalary(_selectedCabangId!);
      final totalGaji = data['total_gaji'] as double;
      final jumlahKaryawan = data['jumlah_karyawan'] as int;

      if (!mounted) return;

      // Auto-fill nominal
      nominalC.text = totalGaji.toStringAsFixed(0);

      setState(() {
        _infoGaji = jumlahKaryawan > 0
            ? 'Dihitung dari $jumlahKaryawan karyawan aktif (approved). Nominal dapat diubah manual.'
            : 'Tidak ada karyawan aktif (approved) di cabang ini. Isi manual.';
        _isLoadingGaji = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _infoGaji = 'Gagal menghitung total gaji: $e';
        _isLoadingGaji = false;
      });
    }
  }

  Widget _buildCatatanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KasentraFormLabel('Catatan'),
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

  Future<void> _ambilFoto() => _pilihFoto(ImageSource.camera);

  Future<void> _ambilDariGaleri() => _pilihFoto(ImageSource.gallery);

  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';

      setState(() {
        _fotoBuktiBytes = bytes;
        _fotoBuktiBase64 = 'data:$mimeType;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (!mounted) return;
      final label = source == ImageSource.camera ? 'kamera' : 'galeri';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil foto dari $label. Pastikan izin kamera/galeri diaktifkan.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
      _fotoBuktiBytes = null;
      _isModalKiriman = false;
    });
  }
}


