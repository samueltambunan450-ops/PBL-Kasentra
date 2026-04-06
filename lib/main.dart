import 'package:flutter/material.dart';

import 'screens/login_page.dart';

void main() {
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
      home: const LoginPage(),
    );
  }
}


