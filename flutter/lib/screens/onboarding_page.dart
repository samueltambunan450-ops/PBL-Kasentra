import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/kasentra_logo.dart';
import '../widgets/kasentra_option_card.dart';
import 'redeem_invite_page.dart';
import 'setup_business_page.dart';

/// Halaman onboarding setelah login Google.
/// Hanya 2 pilihan: Owner (buat usaha baru) atau Kepala Cabang (redeem kode).
/// Role "karyawan" tidak lagi bisa mendaftar lewat app — karyawan adalah
/// data referensi yang dikelola oleh Kepala Cabang.
class OnboardingPage extends StatelessWidget {
  final AppUser user;

  const OnboardingPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 560 : Responsive.formMaxWidth(context),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const KasentraLogo(size: 72),
                  const SizedBox(height: 28),
                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pilih peran Anda di KASENTRA',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildOwnerCard(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildHeadCard(context)),
                      ],
                    )
                  else ...[
                    _buildOwnerCard(context),
                    const SizedBox(height: 16),
                    _buildHeadCard(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context) {
    return KasentraOptionCard(
      icon: Icons.store_outlined,
      title: 'Pemilik Usaha',
      subtitle: 'Daftarkan usaha baru dan kelola semua cabang',
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SetupBusinessPage(user: user)),
        );
      },
    );
  }

  Widget _buildHeadCard(BuildContext context) {
    return KasentraOptionCard(
      icon: Icons.manage_accounts_outlined,
      title: 'Kepala Cabang',
      subtitle: 'Aktivasi akun dengan kode undangan dari pemilik usaha',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RedeemInvitePage(user: user)),
        );
      },
    );
  }
}
