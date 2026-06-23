import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/dashboard_page.dart';
import '../screens/onboarding_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// Brand colors for login page
const Color _brandDarkGreen = Color(0xFF1B6B3A);
const Color _brandMediumGreen = Color(0xFF2E8B4E);
const Color _lightGreen = Color(0xFFE7F4EA);
const Color _darkText = Color(0xFF16201A);
const Color _grayText = Color(0xFF6B7A70);
const Color _borderColor = Color(0xFFEEF1EF);

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
      // Jika sudah punya role (owner/kepala_cabang/karyawan) → dashboard
      // Jika masih pending → onboarding
      if (user.role == UserRole.owner || 
          user.role == UserRole.kepalaCabang || 
          user.role == UserRole.karyawan) {
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HERO HEADER
            _buildHeroHeader(),
            // 2. CONTENT CONTAINER with sections 3-7 (using Transform.translate for overlap effect)
            Transform.translate(
              offset: const Offset(0, -46),
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
    );
  }

  // Hero Header with gradient, decorations, and logo
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandDarkGreen, _brandMediumGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Dot pattern decoration - top left
          Positioned(
            top: 20,
            left: 20,
            child: _buildDotPattern(size: 80, opacity: 0.3),
          ),
          // Blob decoration - top right
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Dot pattern decoration - bottom right
          Positioned(
            bottom: -30,
            right: 20,
            child: _buildDotPattern(size: 80, opacity: 0.3),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  // Logo box
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: _brandMediumGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // KASENTRA text
                  const Text(
                    'KASENTRA',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tagline with dividers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Sistem Keuangan UMKM',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Content section with white background and rounded corners
  Widget _buildContentSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        child: Column(
          children: [
            // 3. SMARTPHONE ILLUSTRATION
            _buildSmartphoneIllustration(),
            const SizedBox(height: 32),
            // 4. WELCOME TEXT
            _buildWelcomeText(),
            const SizedBox(height: 32),
            // 5. FEATURE CARD
            _buildFeatureCard(),
            const SizedBox(height: 28),
            // 6. GOOGLE SIGN IN BUTTON
            _buildGoogleSignInButton(),
            const SizedBox(height: 20),
            // 7. FOOTER NOTE
            _buildFooterNote(),
          ],
        ),
      ),
    );
  }

  // Dot pattern widget
  Widget _buildDotPattern({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: opacity),
            width: 1,
          ),
          top: BorderSide(
            color: Colors.white.withValues(alpha: opacity),
            width: 1,
          ),
        ),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        childAspectRatio: 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          16,
          (index) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Smartphone illustration with circle and sparkles
  Widget _buildSmartphoneIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lightGreen,
          ),
          child: const Icon(
            Icons.phone_android_rounded,
            size: 38,
            color: _brandMediumGreen,
          ),
        ),
        // Sparkle decoration 1 - top right
        Positioned(
          top: 10,
          right: 20,
          child: _buildSparkle(
            size: 12,
            color: const Color(0xFFFFA726), // orange
          ),
        ),
        // Sparkle decoration 2 - bottom left
        Positioned(
          bottom: 15,
          left: 15,
          child: _buildSparkle(
            size: 10,
            color: const Color(0xFFFFD54F), // yellow
          ),
        ),
        // Sparkle decoration 3 - top left
        Positioned(
          top: 25,
          left: 10,
          child: _buildSparkle(
            size: 8,
            color: _brandMediumGreen,
          ),
        ),
      ],
    );
  }

  // Sparkle/star widget
  Widget _buildSparkle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // 4. Welcome text section
  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'Selamat Datang',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kelola keuangan usaha multi-cabang dengan mudah',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14.5,
            color: _grayText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // 5. Feature card with 3 columns
  Widget _buildFeatureCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Feature 1
          Expanded(
            child: _buildFeatureColumn(
              icon: Icons.trending_up_rounded,
              title: 'Laporan Real-time',
              description: 'Pantau keuangan\nsecara real-time',
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 100,
            color: _borderColor,
          ),
          // Feature 2
          Expanded(
            child: _buildFeatureColumn(
              icon: Icons.shield_outlined,
              title: 'Aman & Terpercaya',
              description: 'Data bisnis Anda\nterlindungi',
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 100,
            color: _borderColor,
          ),
          // Feature 3
          Expanded(
            child: _buildFeatureColumn(
              icon: Icons.cloud_upload_outlined,
              title: 'Akses Kapan Saja',
              description: 'Kelola usaha dari\nmana saja',
            ),
          ),
        ],
      ),
    );
  }

  // Individual feature column
  Widget _buildFeatureColumn({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _lightGreen,
            ),
            child: Icon(
              icon,
              size: 24,
              color: _brandMediumGreen,
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: _brandMediumGreen,
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: _grayText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Google sign-in button
  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _loginWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E6E3), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_brandMediumGreen),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google logo placeholder
                  _buildGoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _brandMediumGreen,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Google logo (4-color)
  Widget _buildGoogleLogo() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simplified Google logo - just a colorful 'G'
          Text(
            'G',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4285F4),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Footer note
  Widget _buildFooterNote() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 14,
            color: _grayText,
          ),
          const SizedBox(width: 6),
          const Text(
            'Kami menjaga keamanan data Anda',
            style: TextStyle(
              fontSize: 11.5,
              color: _grayText,
            ),
          ),
        ],
      ),
    );
  }
}
