import 'package:flutter/material.dart';

class KaryawanDashboardPage extends StatelessWidget {
  const KaryawanDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Karyawan'),
      ),
      body: const Center(
        child: Text(
          'Selamat datang, Karyawan',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}