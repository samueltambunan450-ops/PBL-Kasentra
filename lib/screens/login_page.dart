import 'package:flutter/material.dart';

import '../screens/dashboard_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  @override
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    bool success = false;
    try {
      success = await AuthService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Google gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success && AuthService.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(user: AuthService.currentUser!),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Login Google dibatalkan atau gagal."),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "KASENTRA",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Masuk untuk melanjutkan ke dashboard kas.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Gunakan akun Google yang valid.\nRole owner/karyawan ditentukan oleh backend Laravel.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black87, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(_isLoading ? "Memproses..." : "Login dengan Google"),
                          ),
                        ),
                      ],
                    ),
                  
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


