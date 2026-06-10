import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/kasentra_form_field.dart';
import '../widgets/kasentra_logo.dart';
import 'dashboard_page.dart';

class JoinBusinessPage extends StatefulWidget {
  final AppUser user;

  const JoinBusinessPage({super.key, required this.user});

  @override
  State<JoinBusinessPage> createState() => _JoinBusinessPageState();
}

class _JoinBusinessPageState extends State<JoinBusinessPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinWithCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode undangan terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DomainApiService.validateInvitation(_codeController.text.trim());
      await AuthService.updateCurrentUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode salah atau kadaluarsa. $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('Gabung Usaha'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.formMaxWidth(context)),
              child: Column(
                children: [
                  const KasentraLogo(size: 64, showText: false),
                  const SizedBox(height: 24),
                  const Text(
                    'Masukkan Kode Undangan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dapatkan kode dari pemilik usaha untuk bergabung sebagai karyawan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
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
                        const KasentraFormLabel('Kode Undangan'),
                        TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: ABC123',
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _joinWithCode,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Gabung Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
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
