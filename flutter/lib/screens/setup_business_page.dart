import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/domain_api_service.dart';
import '../utils/responsive.dart';
import 'dashboard_page.dart';

class SetupBusinessPage extends StatefulWidget {
  final AppUser user;

  const SetupBusinessPage({super.key, required this.user});

  @override
  State<SetupBusinessPage> createState() => _SetupBusinessPageState();
}

class _SetupBusinessPageState extends State<SetupBusinessPage> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  String _businessType = 'Toko';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_businessNameController.text.trim().isEmpty || _branchNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua kolom terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await DomainApiService.setupBusiness(
        businessName: _businessNameController.text.trim(),
        businessType: _businessType,
        branchName: _branchNameController.text.trim(),
      );
      await AuthService.updateCurrentUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(user: user)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat usaha: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Usaha Baru')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.formMaxWidth(context)),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Isi data usaha Anda untuk melanjutkan.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildBusinessNameField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildBranchNameField()),
                          ],
                        )
                      else ...[
                        _buildBusinessNameField(),
                        const SizedBox(height: 16),
                        _buildBranchNameField(),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _businessType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis usaha',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Toko', child: Text('Toko')),
                          DropdownMenuItem(value: 'Jasa', child: Text('Jasa')),
                          DropdownMenuItem(value: 'Kuliner', child: Text('Kuliner')),
                          DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _businessType = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Buat Usaha'),
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

  Widget _buildBusinessNameField() {
    return TextField(
      controller: _businessNameController,
      decoration: const InputDecoration(
        labelText: 'Nama usaha',
        prefixIcon: Icon(Icons.store_outlined),
      ),
    );
  }

  Widget _buildBranchNameField() {
    return TextField(
      controller: _branchNameController,
      decoration: const InputDecoration(
        labelText: 'Nama cabang utama',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
    );
  }
}
