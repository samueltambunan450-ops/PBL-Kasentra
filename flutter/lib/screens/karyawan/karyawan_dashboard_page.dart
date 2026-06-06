import 'package:flutter/material.dart';

import '../../models/transaksi.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/domain_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';
import '../add_transaction_page.dart';
import '../login_page.dart';

class KaryawanDashboardPage extends StatefulWidget {
  const KaryawanDashboardPage({super.key});

  @override
  State<KaryawanDashboardPage> createState() => _KaryawanDashboardPageState();
}

class _KaryawanDashboardPageState extends State<KaryawanDashboardPage> {
  int _currentIndex = 0;
  bool _loading = true;
  List<Transaksi> _transaksis = [];

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
        _transaksis = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _onSaved(Transaksi transaksi) async {
    await _refreshTransaksi();
    if (!mounted) return;
    setState(() => _currentIndex = 0);
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  String _formatRupiah(int value) {
    final absValue = value.abs();
    final formatted = absValue.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return value < 0 ? '-Rp $formatted' : 'Rp $formatted';
  }

  String _formatTanggal(DateTime date) {
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${bulan[date.month]} ${date.year}';
  }

  AppUser? get _currentUser => AuthService.currentUser;
  String? get _cabangId => _currentUser?.cabangId;

  List<Transaksi> get _branchTransaksis {
    if (_cabangId == null) return [];
    return _transaksis.where((t) => t.cabangId == _cabangId).toList();
  }

  List<Transaksi> get _userTransaksis {
    final userId = _currentUser?.id;
    if (userId == null) return [];
    return _branchTransaksis.where((t) => t.userId == userId).toList();
  }

  List<Transaksi> get _todayBranchTransaksis {
    final now = DateTime.now();
    return _branchTransaksis.where((t) {
      return t.tanggal.year == now.year &&
          t.tanggal.month == now.month &&
          t.tanggal.day == now.day;
    }).toList();
  }

  int get _todayIncome => _todayBranchTransaksis
      .where((t) => t.jenis == TransaksiJenis.pemasukan)
      .fold(0, (sum, t) => sum + t.nominal);

  int get _todayExpense => _todayBranchTransaksis
      .where((t) => t.jenis == TransaksiJenis.pengeluaran)
      .fold(0, (sum, t) => sum + t.nominal);

  int get _saldoCabang => _branchTransaksis.fold(
    0,
    (sum, t) => sum + (t.jenis == TransaksiJenis.pemasukan ? t.nominal : -t.nominal),
  );

  List<Transaksi> get _sortedUserTransaksis {
    final list = _userTransaksis.toList();
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list;
  }

  Widget _buildSummaryCard(BuildContext context) {
    final isWide = !Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: MetricTile(title: 'Pemasukan hari ini', value: _formatRupiah(_todayIncome), color: AppColors.income)),
                const SizedBox(width: 12),
                Expanded(child: MetricTile(title: 'Pengeluaran hari ini', value: _formatRupiah(_todayExpense), color: AppColors.expense)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Cabang', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          _formatRupiah(_saldoCabang),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: MetricTile(title: 'Pemasukan hari ini', value: _formatRupiah(_todayIncome), color: AppColors.income)),
                    const SizedBox(width: 12),
                    Expanded(child: MetricTile(title: 'Pengeluaran hari ini', value: _formatRupiah(_todayExpense), color: AppColors.expense)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Cabang', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        _formatRupiah(_saldoCabang),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHistorySection() {
    final transactions = _sortedUserTransaksis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Belum ada transaksi yang ditambahkan oleh Anda.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = transactions[index];
              final isMobile = Responsive.isMobile(context);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.kategori ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(item.keterangan, style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTanggal(item.tanggal), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                              Text(
                                _formatRupiah(item.nominal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.jenis == TransaksiJenis.pemasukan ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.kategori ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(item.keterangan, style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 8),
                                Text(_formatTanggal(item.tanggal), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                              ],
                            ),
                          ),
                          Text(
                            _formatRupiah(item.nominal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.jenis == TransaksiJenis.pemasukan ? AppColors.income : AppColors.expense,
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildProfilePage() {
    final user = _currentUser;
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: ResponsiveContent(
        padding: EdgeInsets.zero,
        maxWidth: Responsive.formMaxWidth(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil Karyawan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileField('Nama', user?.nama ?? '-'),
                  const SizedBox(height: 14),
                  _buildProfileField('Email', user?.email ?? '-'),
                  const SizedBox(height: 14),
                  _buildProfileField('Cabang', user?.cabangId ?? '-'),
                  const SizedBox(height: 14),
                  _buildProfileField('Peran', 'Karyawan'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHomePage() {
    final user = _currentUser;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: Responsive.pagePadding(context).copyWith(bottom: 12),
              child: ResponsiveContent(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nama ?? 'Karyawan',
                      style: TextStyle(
                        fontSize: Responsive.value(context, mobile: 24.0, tablet: 28.0, desktop: 32.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Karyawan', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    const Text('Saldo Cabang', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(_saldoCabang),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.value(context, mobile: 28.0, tablet: 32.0, desktop: 36.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: Responsive.pagePadding(context),
                  child: ResponsiveContent(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(context),
                        const SizedBox(height: 24),
                        _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      _buildHomePage(),
      AddTransactionPage(onSaved: _onSaved, embedded: true),
      _buildProfilePage(),
    ];

    return AdaptiveDashboardScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      pages: pages,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle, color: AppColors.primary),
          label: 'Tambah',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profil',
        ),
      ],
    );
  }
}
