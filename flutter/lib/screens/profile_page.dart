import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/common_page_scaffold.dart';
import 'login_page.dart';
import 'manage_cabang_page.dart';
import 'manage_karyawan_page.dart';
import 'manage_kategori_page.dart';

class ProfilePage extends StatelessWidget {
  final AppUser user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CommonPageScaffold(
      title: 'Profil',
      subtitle: 'Akun dan pengaturan',
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: Responsive.value(context, mobile: 36.0, tablet: 40.0, desktop: 44.0),
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      size: Responsive.value(context, mobile: 36.0, tablet: 40.0, desktop: 44.0),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.nama,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(user.email, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(user.role == UserRole.owner ? 'Pemilik Usaha' : 'Karyawan'),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (user.role == UserRole.owner) ...[
                    _buildMenuTile(context, Icons.store, 'Kelola Cabang', const ManageCabangPage()),
                    const Divider(height: 1),
                    _buildMenuTile(context, Icons.group, 'Kelola Karyawan', const ManageKaryawanPage()),
                    const Divider(height: 1),
                    _buildMenuTile(context, Icons.category, 'Kelola Kategori', const ManageKategoriPage()),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.expense),
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      AuthService.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
