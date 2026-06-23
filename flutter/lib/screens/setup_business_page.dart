import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/kasentra_form_field.dart';
import 'dashboard_page.dart';

class SetupBusinessPage extends StatefulWidget {
  final AppUser user;

  const SetupBusinessPage({super.key, required this.user});

  @override
  State<SetupBusinessPage> createState() => _SetupBusinessPageState();
}

class _SetupBusinessPageState extends State<SetupBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _branchNameController   = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _modalAwalController    = TextEditingController();

  String _businessType = 'Kuliner';
  bool _isLoading = false;

  // Formatter Rupiah — sama persis dengan manage_cabang_page.dart
  static String _formatRupiah(double value) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(value);

  // Parser angka — sama persis dengan manage_cabang_page.dart
  static double _parseNumber(String input) {
    return double.tryParse(
          input.replaceAll('.', '').replaceAll(',', '.').replaceAll(' ', ''),
        ) ??
        0;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _modalAwalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await DomainApiService.setupBusiness(
        businessName   : _businessNameController.text.trim(),
        businessType   : _businessType,
        branchName     : _branchNameController.text.trim(),
        branchAddress  : _branchAddressController.text.trim(),
        branchModalAwal: _parseNumber(_modalAwalController.text.trim()),
      );
      await AuthService.updateCurrentUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat usaha: $e'),
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
        title: const Text('Buat Usaha Baru'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.formMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Setup Usaha Anda',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isi data usaha dan cabang utama untuk memulai pencatatan keuangan.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Container(
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
                          // ── Nama Usaha ──────────────────────────────────────
                          const KasentraFormLabel('Nama Usaha'),
                          TextFormField(
                            controller: _businessNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Sego Pecel Mas Tyo',
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama usaha tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Nama Cabang Utama ───────────────────────────────
                          const KasentraFormLabel('Nama Cabang Utama'),
                          TextFormField(
                            controller: _branchNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Cabang Pusat',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama cabang tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Alamat Cabang (BARU) ────────────────────────────
                          const KasentraFormLabel('Alamat Cabang Utama'),
                          TextFormField(
                            controller: _branchAddressController,
                            keyboardType: TextInputType.streetAddress,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Jl. Pahlawan No. 12, Semarang',
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 24),
                                child: Icon(Icons.location_on_outlined),
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Alamat cabang tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Modal Awal (BARU) ───────────────────────────────
                          const KasentraFormLabel('Modal Awal Cabang (Rp)'),
                          TextFormField(
                            controller: _modalAwalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 5000000',
                              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                              prefixText: 'Rp ',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Modal awal tidak boleh kosong';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null) return 'Masukkan angka yang valid';
                              if (val < 0) return 'Modal awal tidak boleh negatif';
                              return null;
                            },
                            // Tampilkan preview format Rupiah di bawah field
                            onChanged: (_) => setState(() {}),
                          ),
                          // Preview format rupiah (seperti di manage_cabang_page)
                          if (_modalAwalController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                _formatRupiah(
                                  _parseNumber(_modalAwalController.text),
                                ),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // ── Jenis Usaha ─────────────────────────────────────
                          const KasentraFormLabel('Jenis Usaha'),
                          DropdownButtonFormField<String>(
                            value: _businessType,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Kuliner', child: Text('Kuliner')),
                              DropdownMenuItem(value: 'Toko',    child: Text('Toko')),
                              DropdownMenuItem(value: 'Jasa',    child: Text('Jasa')),
                              DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _businessType = value);
                            },
                          ),
                          const SizedBox(height: 16),

                          const KasentraInfoBox(
                            message:
                                'Anda dapat menambahkan cabang lain setelah usaha berhasil dibuat.',
                          ),
                          const SizedBox(height: 24),

                          // ── Tombol Submit ───────────────────────────────────
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
                                  : const Text(
                                      'Simpan & Lanjut',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
