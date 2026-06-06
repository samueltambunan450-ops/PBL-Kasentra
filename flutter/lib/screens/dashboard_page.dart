import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/user.dart';
import '../services/domain_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_dashboard_scaffold.dart';
import 'add_transaction_page.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'financial_report_page.dart';

class DashboardPage extends StatefulWidget {
  final AppUser user;

  const DashboardPage({
    super.key,
    required this.user,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;
  bool _loading = true;
  List<Transaksi> _transaksi = [];

  @override
  void initState() {
    super.initState();
    _refreshTransaksi();
  }

  Future<void> _refreshTransaksi() async {
    try {
      final list = await DomainApiService.fetchTransaksis();
      if (!mounted) return;
      setState(() {
        _transaksi = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _tambahTransaksi(Transaksi t) async {
    await _refreshTransaksi();
    if (!mounted) return;
    setState(() {
      currentIndex = 0;
    });
  }

  Future<void> _hapusTransaksi(String id) async {
    await DomainApiService.deleteTransaksi(id);
    await _refreshTransaksi();
  }

  Future<void> _editTransaksi(Transaksi updated) async {
    try {
      await DomainApiService.deleteTransaksi(updated.id);
      await DomainApiService.createTransaksi(updated);
      await _refreshTransaksi();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memperbarui transaksi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = <Widget>[
      HomePage(
        transaksi: _transaksi,
        role: widget.user.role,
        onDelete: _hapusTransaksi,
      ),
      HistoryPage(
        transaksi: _transaksi,
        role: widget.user.role,
        onDelete: _hapusTransaksi,
        onEdit: _editTransaksi,
      ),
      AddTransactionPage(
        onSaved: _tambahTransaksi,
        embedded: true,
      ),
      ProfilePage(user: widget.user),
    ];
    if (widget.user.role == UserRole.owner) {
      pages.add(FinancialReportPage(transaksi: _transaksi));
    }

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: AppColors.primary),
        label: "Home",
      ),
      const NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt, color: AppColors.primary),
        label: "Riwayat",
      ),
      NavigationDestination(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
        selectedIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
        label: "Tambah",
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppColors.primary),
        label: "Profil",
      ),
    ];
    if (widget.user.role == UserRole.owner) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
          label: "Laporan",
        ),
      );
    }

    return AdaptiveDashboardScaffold(
      currentIndex: currentIndex,
      onDestinationSelected: (i) => setState(() => currentIndex = i),
      pages: pages,
      destinations: destinations,
    );
  }
}
