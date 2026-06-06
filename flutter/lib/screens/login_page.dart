import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/dashboard_page.dart';
import '../screens/onboarding_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    bool success = false;
    try {
      success = await AuthService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Google gagal: $e'), backgroundColor: Colors.red),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && AuthService.currentUser != null) {
      final user = AuthService.currentUser!;
      if (user.role == UserRole.owner || user.role == UserRole.karyawan) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingPage(user: user)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login Google dibatalkan atau gagal."), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 900 : Responsive.formMaxWidth(context)),
              child: isWide ? _buildWideLayout(context) : _buildCompactLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 72, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  "KASENTRA",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Kelola keuangan usaha multi-cabang dengan mudah. Pantau pemasukan, pengeluaran, dan laporan keuangan secara real-time.",
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(child: _buildLoginCard(context)),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return _buildLoginCard(context);
  }

  Widget _buildLoginCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!Responsive.isDesktop(context)) ...[
              const Icon(Icons.account_balance_wallet, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                "KASENTRA",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Kelola keuangan usaha lebih mudah",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ] else ...[
              Text(
                "Masuk ke akun",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Gunakan akun Google untuk melanjutkan", style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
            ],
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _loginWithGoogle,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Masuk dengan Google',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
