import 'package:flutter/material.dart';

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
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  String _businessType = 'Kuliner';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_businessNameController.text.trim().isEmpty || _branchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua kolom terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DomainApiService.setupBusiness(
        businessName: _businessNameController.text.trim(),
        businessType: _businessType,
        branchName: _branchNameController.text.trim(),
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
        SnackBar(content: Text('Gagal membuat usaha: $e'), backgroundColor: Colors.red),
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
                    'Isi data usaha untuk memulai pencatatan keuangan.',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const KasentraFormLabel('Nama Usaha'),
                        TextField(
                          controller: _businessNameController,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Sego Pecel Mas Tyo',
                            prefixIcon: Icon(Icons.store_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const KasentraFormLabel('Nama Cabang Utama'),
                        TextField(
                          controller: _branchNameController,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Cabang Pusat',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const KasentraFormLabel('Jenis Usaha'),
                        DropdownButtonFormField<String>(
                          initialValue: _businessType,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Kuliner', child: Text('Kuliner')),
                            DropdownMenuItem(value: 'Toko', child: Text('Toko')),
                            DropdownMenuItem(value: 'Jasa', child: Text('Jasa')),
                            DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _businessType = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        const KasentraInfoBox(
                          message: 'Anda dapat menambahkan cabang lain setelah usaha berhasil dibuat.',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Simpan & Lanjut', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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
