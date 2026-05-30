import 'package:flutter/material.dart';

import '../models/kategori.dart';
import '../models/cabang.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';

class ManageKategoriPage extends StatefulWidget {
  const ManageKategoriPage({super.key});

  @override
  State<ManageKategoriPage> createState() => _ManageKategoriPageState();
}

class _ManageKategoriPageState extends State<ManageKategoriPage> {
  final _searchC = TextEditingController();
  final _namaC = TextEditingController();

  KategoriType _tipe = KategoriType.pengeluaran;
  KategoriScope _scope = KategoriScope.global;
  String? _selectedCabangId;
  Kategori? _editing;

  List<Kategori> _kategoris = [];
  List<Cabang> _cabangs = [];
  bool _isLoading = false;
  String? _errorMsg;
  String _searchQuery = '';
  String _activeFilter = 'semua'; // 'semua', 'global', 'cabang'

  @override
  void initState() {
    super.initState();
    if (!AuthService.isOwner()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Akses Ditolak'),
            content: const Text('Hanya Owner yang dapat mengelola kategori.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
      return;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final categoris = await DomainApiService.fetchKategoris();
      final cabangs = await DomainApiService.fetchCabangs();
      if (!mounted) return;
      setState(() {
        _kategoris = categoris;
        _cabangs = cabangs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'Gagal memuat data: $e';
      });
    }
  }

  List<Kategori> get _filteredKategoris {
    return _kategoris.where((k) {
      final matchesSearch = k.nama.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _activeFilter == 'semua' ||
          (_activeFilter == 'global' && k.scope == KategoriScope.global) ||
          (_activeFilter == 'cabang' && k.scope == KategoriScope.cabang);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showFormBottomSheet([Kategori? item]) {
    setState(() {
      _editing = item;
      if (item != null) {
        _namaC.text = item.nama;
        _tipe = item.tipe;
        _scope = item.scope;
        _selectedCabangId = item.cabangId;
      } else {
        _namaC.clear();
        _tipe = KategoriType.pemasukan;
        _scope = KategoriScope.global;
        _selectedCabangId = _cabangs.isNotEmpty ? _cabangs.first.id : null;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editing == null ? 'Tambah Kategori' : 'Edit Kategori',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nama Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _namaC,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama kategori',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Jenis Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pemasukan')),
                            selected: _tipe == KategoriType.pemasukan,
                            selectedColor: Colors.blue.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _tipe == KategoriType.pemasukan ? Colors.blue.shade800 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _tipe = KategoriType.pemasukan);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pengeluaran')),
                            selected: _tipe == KategoriType.pengeluaran,
                            selectedColor: Colors.red.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _tipe == KategoriType.pengeluaran ? Colors.red.shade800 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _tipe = KategoriType.pengeluaran);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Berlaku Untuk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Semua Cabang')),
                            selected: _scope == KategoriScope.global,
                            selectedColor: Colors.green.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _scope == KategoriScope.global ? Colors.green.shade800 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _scope = KategoriScope.global);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cabang Tertentu')),
                            selected: _scope == KategoriScope.cabang,
                            selectedColor: Colors.green.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _scope == KategoriScope.cabang ? Colors.green.shade800 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _scope = KategoriScope.cabang);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_scope == KategoriScope.cabang) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Pilih Cabang',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCabangId,
                        items: _cabangs.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nama),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            _selectedCabangId = val;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text('Pilih cabang'),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _save(context),
                        child: Text(
                          _editing == null ? 'Simpan Kategori' : 'Perbarui Kategori',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _save(BuildContext ctx) async {
    final nama = _namaC.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Nama kategori wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_scope == KategoriScope.cabang && _selectedCabangId == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Pilih cabang terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(ctx); // Close BottomSheet

    setState(() => _isLoading = true);
    try {
      final jenisStr = _tipe == KategoriType.pemasukan ? 'pemasukan' : 'pengeluaran';
      final scopeStr = _scope == KategoriScope.global ? 'global' : 'cabang';
      final cabId = _scope == KategoriScope.cabang ? _selectedCabangId : null;

      if (_editing == null) {
        await DomainApiService.createKategori(
          nama: nama,
          jenis: jenisStr,
          scope: scopeStr,
          cabangId: cabId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await DomainApiService.updateKategori(
          _editing!.id,
          nama: nama,
          jenis: jenisStr,
          scope: scopeStr,
          cabangId: cabId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(Kategori k) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${k.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await DomainApiService.deleteKategori(k.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _filteredKategoris;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Kategori',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormBottomSheet(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kategori', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.green,
        child: Column(
          children: [
            // Search Bar & Filters Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchC,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari kategori...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('semua', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('global', 'Global'),
                      const SizedBox(width: 8),
                      _buildFilterChip('cabang', 'Cabang'),
                    ],
                  ),
                ],
              ),
            ),

            // Category List Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _errorMsg != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Kategori tidak ditemukan'
                                        : 'Belum ada kategori',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final k = filtered[index];
                                final isPemasukan = k.tipe == KategoriType.pemasukan;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          // Left side vertical color bar
                                          Container(
                                            width: 6,
                                            color: isPemasukan ? Colors.blue : Colors.red,
                                          ),
                                          const SizedBox(width: 14),
                                          // Icon representing jenis
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: (isPemasukan ? Colors.blue : Colors.red).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isPemasukan ? Icons.arrow_upward : Icons.arrow_downward,
                                                color: isPemasukan ? Colors.blue : Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Category Info
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    k.nama,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        isPemasukan ? 'Pemasukan' : 'Pengeluaran',
                                                        style: TextStyle(
                                                          color: isPemasukan ? Colors.blue.shade700 : Colors.red.shade700,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        ' • ',
                                                        style: TextStyle(color: Colors.grey.shade400),
                                                      ),
                                                      Text(
                                                        k.scope == KategoriScope.global
                                                            ? 'Global'
                                                            : 'Cabang',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (k.scope == KategoriScope.cabang) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Cabang: ${k.cabangNama ?? k.cabangId ?? "-"}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Action Buttons
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                                  onPressed: () => _showFormBottomSheet(k),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                  onPressed: () => _confirmDelete(k),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
