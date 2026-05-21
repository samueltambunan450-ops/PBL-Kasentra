import 'package:flutter/material.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Owner'),
      ),
      body: const Center(
        child: Text(
          'Selamat datang, Owner',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}