import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/karyawan/karyawan_dashboard_page.dart';
import 'screens/onboarding_page.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }
  await AuthService.hydrateSession();
  runApp(const KasentraApp());
}

class KasentraApp extends StatelessWidget {
  const KasentraApp({super.key});

  Widget _buildHome(AppUser currentUser) {
    if (currentUser.role == UserRole.pending) {
      return OnboardingPage(user: currentUser);
    }
    if (currentUser.role == UserRole.owner) {
      return DashboardPage(user: currentUser);
    }
    return const KaryawanDashboardPage();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;

    return MaterialApp(
      title: 'Kasentra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: currentUser == null
          ? const LoginPage()
          : _buildHome(currentUser),
    );
  }
}
