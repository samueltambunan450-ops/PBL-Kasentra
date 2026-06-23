import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/kasentra_form_field.dart';
import '../widgets/kasentra_logo.dart';
import 'dashboard_page.dart';

/// Screen untuk kepala cabang baru memasukkan kode undangan.
/// Menggunakan endpoint POST /api/invitation/redeem.
class RedeemInvitePage extends StatefulWidget {
  final AppUser user;

  const RedeemInvitePage({super.key, required this.user});

  @override
  State<RedeemInvitePage> createState() => _RedeemInvitePageState();
}

class _RedeemInvitePageState extends State<RedeemInvitePage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode undangan terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedUser = await DomainApiService.redeemInvitation(code);
      await AuthService.updateCurrentUser(updatedUser);

      if (!mounted) return;

      // Tampilkan pesan selamat datang sesuai role
      final msg = updatedUser.isKepalaCabang
          ? 'Selamat! Anda sekarang menjadi Kepala Cabang.'
          : 'Berhasil bergabung sebagai karyawan.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(user: updatedUser)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode tidak valid atau sudah digunakan. $e'),
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
        title: const Text('Masukkan Kode Undangan'),
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
                    'Aktivasi Akun Kepala Cabang',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan kode undangan yang dikirim oleh pemilik usaha untuk mengaktifkan akun Anda.',
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'ABC12345',
                            hintStyle: TextStyle(letterSpacing: 2, fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.vpn_key_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kode bersifat sekali pakai dan akan kadaluarsa setelah digunakan.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _redeem,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_outlined),
                            label: Text(
                              _isLoading ? 'Memvalidasi...' : 'Aktifkan Akun',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
