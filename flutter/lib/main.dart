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

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return MaterialApp(
        title: 'Kasentra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const LoginPage(),
      );
    }

    return MaterialApp(
      title: 'Kasentra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: currentUser.role == UserRole.pending
          ? OnboardingPage(user: currentUser)
          : currentUser.role == UserRole.owner
              ? DashboardPage(user: currentUser)
              : const KaryawanDashboardPage(),
    );
  }
}


