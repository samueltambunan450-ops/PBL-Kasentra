import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/user.dart';
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
  final List<Transaksi> _transaksi = [];

  void _tambahTransaksi(Transaksi t) {
    setState(() {
      _transaksi.add(t);
      currentIndex = 0;
    });
  }

  void _hapusTransaksi(String id) {
    setState(() {
      _transaksi.removeWhere((t) => t.id == id);
    });
  }

  void _editTransaksi(Transaksi updated) {
    setState(() {
      final idx = _transaksi.indexWhere((t) => t.id == updated.id);
      if (idx != -1) {
        _transaksi[idx] = updated;
      }
      // jangan ubah currentIndex agar jika user berada di riwayat
      // tetap di sana setelah edit
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // home dashboard
      HomePage(
        transaksi: _transaksi,
        role: widget.user.role,
        onDelete: _hapusTransaksi,
      ),
      // riwayat tab – show history page
      HistoryPage(
        transaksi: _transaksi,
        role: widget.user.role,
        onDelete: _hapusTransaksi,
      ),
      // tambah
      AddTransactionPage(
        onSaved: _tambahTransaksi,
      ),
      // profil
      ProfilePage(user: widget.user),
      // laporan
      FinancialReportPage(transaksi: _transaksi),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => setState(() => currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.green),
            label: "Home",
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Colors.green),
            label: "Riwayat",
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: "Tambah",
          ),
              const NavigationDestination(
               icon: Icon(Icons.person_outline),
  selectedIcon: Icon(Icons.person, color: Colors.green),
  label: "Profil",
),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.green),
            label: "Laporan",
          ),
        ],
      ),
    );
  }
}


