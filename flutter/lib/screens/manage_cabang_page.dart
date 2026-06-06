import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cabang.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/manage_page_layout.dart';

class ManageCabangPage extends StatefulWidget {
  const ManageCabangPage({super.key});

  @override
  State<ManageCabangPage> createState() => _ManageCabangPageState();
}

class _ManageCabangPageState extends State<ManageCabangPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController alamatC = TextEditingController();
  final TextEditingController modalC = TextEditingController();

  List<Cabang> _cabangs = [];
  Cabang? _editing;
  TimeOfDay? _jamBuka;
  TimeOfDay? _jamTutup;

  @override
  void initState() {
    super.initState();
    if (!AuthService.isOwner()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Akses Ditolak'),
            content: const Text('Anda tidak bisa mengakses halaman ini.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        ).then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      });
    }
    _loadCabangs();
  }

  @override
  void dispose() {
    namaC.dispose();
    alamatC.dispose();
    modalC.dispose();
    super.dispose();
  }

  Future<void> _loadCabangs() async {
    final data = await DomainApiService.fetchCabangs();
    if (!mounted) return;
    setState(() => _cabangs = data);
  }

  String _formatRupiah(double value) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);

  double _parseIndonesianNumber(String input) {
    return double.tryParse(
          input.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
  }

  Future<void> _saveCabang() async {
    if (namaC.text.isEmpty || alamatC.text.isEmpty || modalC.text.isEmpty || _jamBuka == null || _jamTutup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data cabang dan jam operasional")),
      );
      return;
    }

    final modal = _parseIndonesianNumber(modalC.text);

    try {
      if (_editing == null) {
        await DomainApiService.createCabang(
          nama: namaC.text.trim(),
          alamat: alamatC.text.trim(),
          modalAwal: modal,
          jamBuka: _formatJam(_jamBuka),
          jamTutup: _formatJam(_jamTutup),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cabang berhasil ditambahkan"), backgroundColor: Colors.green),
        );
      } else {
        await DomainApiService.updateCabang(
          _editing!.id,
          nama: namaC.text.trim(),
          alamat: alamatC.text.trim(),
          modalAwal: modal,
          jamBuka: _formatJam(_jamBuka),
          jamTutup: _formatJam(_jamTutup),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cabang berhasil diperbarui"), backgroundColor: Colors.green),
        );
        _editing = null;
      }

      if (mounted) {
        setState(() {
          namaC.clear();
          alamatC.clear();
          modalC.clear();
        });
      }
      await _loadCabangs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan cabang: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _startEdit(Cabang c) {
    setState(() {
      _editing = c;
      namaC.text = c.nama;
      alamatC.text = c.alamat;
      modalC.text = c.modalAwal.toString();
      _jamBuka = _parseTime(c.jamBuka);
      _jamTutup = _parseTime(c.jamTutup);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = null;
      namaC.clear();
      alamatC.clear();
      modalC.clear();
      _jamBuka = null;
      _jamTutup = null;
    });
  }

  Future<void> _deleteCabang(Cabang c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus cabang"),
        content: Text("Yakin ingin menghapus ${c.nama}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DomainApiService.deleteCabang(c.id);
      if (_editing?.id == c.id) _cancelEdit();
      await _loadCabangs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cabang berhasil dihapus"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus cabang: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isOwner()) {
      return const Scaffold(body: Center(child: Text('Anda tidak bisa mengakses halaman ini.')));
    }

    final isWide = !Responsive.isMobile(context);

    return ManagePageLayout(
      title: 'Kelola Cabang',
      listTitle: 'Daftar Cabang',
      formSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing == null ? "Tambah Cabang" : "Edit Cabang",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(controller: namaC, decoration: const InputDecoration(labelText: "Nama Cabang")),
          const SizedBox(height: 12),
          TextField(controller: alamatC, decoration: const InputDecoration(labelText: "Alamat")),
          const SizedBox(height: 12),
          TextField(
            controller: modalC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Modal Awal"),
            onChanged: (_) => setState(() {}),
          ),
          if (modalC.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _formatRupiah(_parseIndonesianNumber(modalC.text)),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _jamBuka ?? const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) setState(() => _jamBuka = picked);
                  },
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text('Buka: ${_formatJam(_jamBuka)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _jamTutup ?? const TimeOfDay(hour: 22, minute: 0),
                    );
                    if (picked != null) setState(() => _jamTutup = picked);
                  },
                  icon: const Icon(Icons.access_time_filled, size: 18),
                  label: Text('Tutup: ${_formatJam(_jamTutup)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_jamBuka != null && _jamTutup != null)
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _isCabangOpen ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  _isCabangOpen ? 'Cabang sedang buka' : 'Cabang sedang tutup',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isCabangOpen ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveCabang,
                        child: Text(_editing == null ? "Simpan Cabang" : "Perbarui Cabang"),
                      ),
                    ),
                    if (_editing != null) ...[
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton(onPressed: _cancelEdit, child: const Text("Batal"))),
                    ],
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveCabang,
                        child: Text(_editing == null ? "Simpan Cabang" : "Perbarui Cabang"),
                      ),
                    ),
                    if (_editing != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(onPressed: _cancelEdit, child: const Text("Batal")),
                      ),
                    ],
                  ],
                ),
        ],
      ),
      listSection: _cabangs.isEmpty
          ? const Center(child: Text("Belum ada cabang"))
          : ListView.separated(
              itemCount: _cabangs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = _cabangs[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Responsive.isMobile(context)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(c.alamat, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Modal: ${_formatRupiah(c.modalAwal)}', style: const TextStyle(color: AppColors.primary)),
                            if (c.jamBuka != null && c.jamTutup != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: c.isOpen ? Colors.green : Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${c.jamBuka} – ${c.jamTutup} • ${c.isOpen ? "Buka" : "Tutup"}',
                                    style: TextStyle(fontSize: 12, color: c.isOpen ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(onPressed: () => _startEdit(c), icon: const Icon(Icons.edit_outlined)),
                                IconButton(
                                  onPressed: () => _deleteCabang(c),
                                  icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.store, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(c.alamat, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  Text('Modal: ${_formatRupiah(c.modalAwal)}', style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                                  if (c.jamBuka != null && c.jamTutup != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, size: 8, color: c.isOpen ? Colors.green : Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${c.jamBuka} – ${c.jamTutup} • ${c.isOpen ? "Buka" : "Tutup"}',
                                            style: TextStyle(fontSize: 12, color: c.isOpen ? Colors.green : Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => _startEdit(c), icon: const Icon(Icons.edit_outlined)),
                            IconButton(
                              onPressed: () => _deleteCabang(c),
                              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }

  bool get _isCabangOpen {
    if (_jamBuka == null || _jamTutup == null) return false;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final bukaMinutes = _jamBuka!.hour * 60 + _jamBuka!.minute;
    final tutupMinutes = _jamTutup!.hour * 60 + _jamTutup!.minute;
    return nowMinutes >= bukaMinutes && nowMinutes <= tutupMinutes;
  }

  String _formatJam(TimeOfDay? jam) {
    if (jam == null) return '--:--';
    return jam.hour.toString().padLeft(2, '0') + ':' + jam.minute.toString().padLeft(2, '0');
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}
