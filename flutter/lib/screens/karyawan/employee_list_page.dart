import 'package:flutter/material.dart';

import '../../models/employee.dart';
import '../../models/user.dart';
import '../../services/domain_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'add_edit_employee_page.dart';

class EmployeeListPage extends StatefulWidget {
  final AppUser user;
  final String branchId;
  final String branchName;

  const EmployeeListPage({
    super.key,
    required this.user,
    required this.branchId,
    required this.branchName,
  });

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final employees = await DomainApiService.fetchEmployees(widget.branchId);
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddEdit({Employee? employee}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditEmployeePage(
          user: widget.user,
          branchId: widget.branchId,
          employee: employee,
        ),
      ),
    );
    if (result == true) _loadEmployees();
  }

  Future<void> _confirmDelete(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text('Hapus "${employee.nama}" dari daftar karyawan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DomainApiService.deleteEmployee(employee.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${employee.nama} berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEmployees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Karyawan'),
            Text(
              widget.branchName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loadEmployees,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadEmployees, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Belum ada karyawan.'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _openAddEdit(),
              child: const Text('Tambah Karyawan'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.people, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${_employees.length} karyawan terdaftar',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadEmployees,
            child: ListView.builder(
              padding: Responsive.pagePadding(context).copyWith(top: 8),
              itemCount: _employees.length,
              itemBuilder: (context, index) => _EmployeeCard(
                employee: _employees[index],
                onEdit: () => _openAddEdit(employee: _employees[index]),
                onDelete: () => _confirmDelete(_employees[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Warna badge berdasarkan status
    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;
    
    if (employee.isApproved) {
      badgeColor = Colors.green;
      badgeLabel = 'Disetujui';
      badgeIcon = Icons.check_circle;
    } else if (employee.isRejected) {
      badgeColor = Colors.red;
      badgeLabel = 'Ditolak';
      badgeIcon = Icons.cancel;
    } else {
      badgeColor = Colors.orange;
      badgeLabel = 'Menunggu';
      badgeIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            employee.nama.isNotEmpty ? employee.nama[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee.nama,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Badge status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 12, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              employee.jabatan,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              employee.gajiFormatted,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: AppColors.primary,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: Colors.red,
              tooltip: 'Hapus',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
