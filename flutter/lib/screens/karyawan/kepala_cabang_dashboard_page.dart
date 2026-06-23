import 'package:flutter/material.dart';

import '../../models/transaksi.dart';
import '../../models/user.dart';
import '../../services/domain_api_service.dart';
import '../../widgets/adaptive_dashboard_scaffold.dart';
import '../../widgets/kasentra_bottom_nav.dart';
import '../add_transaction_page.dart';
import '../history_page.dart';
import 'kepala_cabang_home_page.dart';
import 'kepala_cabang_profile_page.dart';

/// Dashboard utama untuk Kepala Cabang dengan bottom navbar (4 tab).
class KepalaCabangDashboardPage extends StatefulWidget {
  final AppUser user;
  const KepalaCabangDashboardPage({super.key, required this.user});

  @override
  State<KepalaCabangDashboardPage> createState() =>
      _KepalaCabangDashboardPageState();
}

class _KepalaCabangDashboardPageState
    extends State<KepalaCabangDashboardPage> {
  int currentIndex = 0;
  bool _loading = true;
  List<Transaksi> _transaksi = [];
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = widget.user.id;
    _refreshTransaksi();
  }

  @override
  void didUpdateWidget(covariant KepalaCabangDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika user berganti, flush state dan re-fetch
    if (oldWidget.user.id != widget.user.id) {
      _lastUserId = widget.user.id;
      setState(() {
        _transaksi = [];
        _loading = true;
      });
      _refreshTransaksi();
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
    setState(() => currentIndex = 0);
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
    return const [
      KasentraNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      KasentraNavDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Riwayat',
      ),
      KasentraNavDestination(
        icon: Icons.add,
        selectedIcon: Icons.add,
        label: 'Tambah',
      ),
      KasentraNavDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = <Widget>[
      KepalaCabangHomePage(
        user: widget.user,
        transaksi: _transaksi,
        onDelete: _hapusTransaksi,
      ),
      HistoryPage(
        transaksi: _transaksi,
        role: UserRole.kepalaCabang,
        onDelete: _hapusTransaksi,
        onEdit: _editTransaksi,
      ),
      AddTransactionPage(
        onSaved: _tambahTransaksi,
        embedded: true,
      ),
      KepalaCabangProfilePage(user: widget.user),
    ];

    return AdaptiveDashboardScaffold(
      currentIndex: currentIndex,
      onDestinationSelected: (i) => setState(() => currentIndex = i),
      pages: pages,
      destinations: _buildDestinations(),
      fabIndex: 2,
    );
  }
}
