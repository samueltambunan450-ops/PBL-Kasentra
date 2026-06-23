import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/employee.dart';
import '../../models/user.dart';
import '../../services/domain_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/kasentra_form_field.dart';

class AddEditEmployeePage extends StatefulWidget {
  final AppUser user;
  final String branchId;
  final Employee? employee; // null = tambah baru, non-null = edit

  const AddEditEmployeePage({
    super.key,
    required this.user,
    required this.branchId,
    this.employee,
  });

  @override
  State<AddEditEmployeePage> createState() => _AddEditEmployeePageState();
}

class _AddEditEmployeePageState extends State<AddEditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _jabatanController;
  late final TextEditingController _gajiController;

  bool _isLoading = false;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.employee?.nama ?? '');
    _jabatanController =
        TextEditingController(text: widget.employee?.jabatan ?? '');
    _gajiController = TextEditingController(
      text: widget.employee != null
          ? widget.employee!.gajiPokok.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jabatanController.dispose();
    _gajiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final nama = _namaController.text.trim();
    final jabatan = _jabatanController.text.trim();
    final gaji = double.tryParse(_gajiController.text.trim()) ?? 0.0;

    try {
      if (_isEdit) {
        await DomainApiService.updateEmployee(
          widget.employee!.id,
          nama: nama,
          jabatan: jabatan,
          gajiPokok: gaji,
        );
      } else {
        await DomainApiService.createEmployee(
          branchId: widget.branchId,
          nama: nama,
          jabatan: jabatan,
          gajiPokok: gaji,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Data karyawan diperbarui' : 'Karyawan berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text(_isEdit ? 'Edit Karyawan' : 'Tambah Karyawan'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.formMaxWidth(context)),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isEdit ? 'Edit Data Karyawan' : 'Data Karyawan Baru',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Karyawan tidak perlu mendaftar ke aplikasi.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // Nama
                      const KasentraFormLabel('Nama Karyawan'),
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          hintText: 'Nama lengkap',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Jabatan
                      const KasentraFormLabel('Jabatan'),
                      TextFormField(
                        controller: _jabatanController,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Kasir, Chef, OB',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Jabatan tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Gaji Pokok
                      const KasentraFormLabel('Gaji Pokok (Rp)'),
                      TextFormField(
                        controller: _gajiController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 2500000',
                          prefixIcon: Icon(Icons.payments_outlined),
                          prefixText: 'Rp ',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Gaji tidak boleh kosong';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Simpan Perubahan' : 'Tambah Karyawan',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
