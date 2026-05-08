import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter web (Chrome/Edge) di project ini kita buat agar *tidak* memanggil Firebase Core,
  // supaya tidak crash ketika `firebase_options.dart` belum tersedia.
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  await AuthService.hydrateSession();
  runApp(const KasentraApp());
}

class KasentraApp extends StatelessWidget {
  const KasentraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasentra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AuthService.currentUser == null
          ? const LoginPage()
          : DashboardPage(user: AuthService.currentUser!),
    );
  }
}


