import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/kasentra_logo.dart';
import '../widgets/kasentra_option_card.dart';
import 'join_business_page.dart';
import 'setup_business_page.dart';

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
              constraints: BoxConstraints(maxWidth: isWide ? 700 : Responsive.formMaxWidth(context)),
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
                    'Pilih cara Anda ingin memulai di KASENTRA',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildJoinCard(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCreateCard(context)),
                      ],
                    )
                  else ...[
                    _buildJoinCard(context),
                    const SizedBox(height: 16),
                    _buildCreateCard(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinCard(BuildContext context) {
    return KasentraOptionCard(
      icon: Icons.person_outline,
      title: 'Gabung sebagai Karyawan',
      subtitle: 'Masukkan kode undangan dari pemilik usaha',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JoinBusinessPage(user: user)),
        );
      },
    );
  }

  Widget _buildCreateCard(BuildContext context) {
    return KasentraOptionCard(
      icon: Icons.store_outlined,
      title: 'Buat Usaha Baru',
      subtitle: 'Daftarkan usaha Anda sebagai pemilik',
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SetupBusinessPage(user: user)),
        );
      },
    );
  }
}
