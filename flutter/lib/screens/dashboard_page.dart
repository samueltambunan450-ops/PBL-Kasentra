import 'package:flutter/material.dart';

import '../models/transaksi.dart';
import '../models/user.dart';
import '../services/domain_api_service.dart';
import '../widgets/adaptive_dashboard_scaffold.dart';
import '../widgets/kasentra_bottom_nav.dart';
import 'add_transaction_page.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'financial_report_page.dart';
import 'karyawan/kepala_cabang_dashboard_page.dart';

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
  // Simpan userId terakhir yang dipakai untuk deteksi ganti akun
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = widget.user.id;
    if (widget.user.isKepalaCabang) {
      setState(() => _loading = false);
    } else {
      _refreshTransaksi();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika user berganti (ganti akun), wajib flush state dan re-fetch
    if (oldWidget.user.id != widget.user.id) {
      _lastUserId = widget.user.id;
      setState(() {
        _transaksi = [];
        _loading = true;
      });
      if (!widget.user.isKepalaCabang) {
        _refreshTransaksi();
      } else {
        setState(() => _loading = false);
      }
    }
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

  List<KasentraNavDestination> _buildDestinations() {
    final destinations = <KasentraNavDestination>[
      const KasentraNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      const KasentraNavDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Riwayat',
      ),
      const KasentraNavDestination(
        icon: Icons.add,
        selectedIcon: Icons.add,
        label: 'Transaksi',
      ),
      const KasentraNavDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profil',
      ),
    ];

    if (widget.user.role == UserRole.owner) {
      destinations.add(
        const KasentraNavDestination(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: 'Laporan',
        ),
      );
    }

    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    // Kepala cabang punya dashboard khusus
    if (widget.user.isKepalaCabang) {
      return KepalaCabangDashboardPage(user: widget.user);
    }

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

    return AdaptiveDashboardScaffold(
      currentIndex: currentIndex,
      onDestinationSelected: (i) => setState(() => currentIndex = i),
      pages: pages,
      destinations: _buildDestinations(),
      fabIndex: 2,
    );
  }
}
