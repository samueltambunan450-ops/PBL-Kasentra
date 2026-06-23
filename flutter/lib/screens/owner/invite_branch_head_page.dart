import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/cabang.dart';
import '../../services/domain_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/kasentra_form_field.dart';

class InviteBranchHeadPage extends StatefulWidget {
  final Cabang cabang;

  const InviteBranchHeadPage({super.key, required this.cabang});

  @override
  State<InviteBranchHeadPage> createState() => _InviteBranchHeadPageState();
}

class _InviteBranchHeadPageState extends State<InviteBranchHeadPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();

  bool _isLoading = false;
  String? _generatedCode;
  String? _expiresAt;

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await DomainApiService.inviteBranchHead(
        branchId: widget.cabang.id,
        nama: _namaController.text.trim(),
        noHp: _noHpController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _generatedCode = result['invitation_code'] as String?;
        _expiresAt = result['expires_at'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan kepala cabang: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyCode() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode undangan disalin ke clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('Tambah Kepala Cabang'),
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
                  // Header info cabang
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.store_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cabang.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              if (widget.cabang.alamat.isNotEmpty)
                                Text(
                                  widget.cabang.alamat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form isian
                  if (_generatedCode == null) ...[
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
                            const Text(
                              'Data Kepala Cabang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Isi data calon kepala cabang. Sistem akan generate kode undangan otomatis.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            const KasentraFormLabel('Nama Kepala Cabang'),
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
                            const KasentraFormLabel('Nomor HP'),
                            TextFormField(
                              controller: _noHpController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: 08123456789',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Nomor HP tidak boleh kosong'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _submit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_outlined),
                                label: Text(
                                  _isLoading ? 'Memproses...' : 'Generate Kode Undangan',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Tampilkan kode undangan yang sudah digenerate
                    _CodeResultCard(
                      nama: _namaController.text.trim(),
                      code: _generatedCode!,
                      expiresAt: _expiresAt,
                      onCopy: _copyCode,
                      onAddAnother: () {
                        setState(() {
                          _generatedCode = null;
                          _expiresAt = null;
                          _namaController.clear();
                          _noHpController.clear();
                        });
                      },
                      onDone: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeResultCard extends StatelessWidget {
  final String nama;
  final String code;
  final String? expiresAt;
  final VoidCallback onCopy;
  final VoidCallback onAddAnother;
  final VoidCallback onDone;

  const _CodeResultCard({
    required this.nama,
    required this.code,
    required this.expiresAt,
    required this.onCopy,
    required this.onAddAnother,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ikon sukses
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Kode undangan untuk $nama berhasil dibuat!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Bagikan kode ini ke calon kepala cabang via WhatsApp atau media lain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Kode undangan
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'KODE UNDANGAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Berlaku hingga: $expiresAt',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tombol salin
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Salin Kode'),
          ),
          const SizedBox(height: 12),

          // Tombol tambah lagi
          OutlinedButton.icon(
            onPressed: onAddAnother,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Tambah Kepala Cabang Lain'),
          ),
          const SizedBox(height: 12),

          // Tombol selesai
          FilledButton(
            onPressed: onDone,
            child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
