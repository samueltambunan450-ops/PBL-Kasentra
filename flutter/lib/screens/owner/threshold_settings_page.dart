import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/domain_api_service.dart';
import '../../theme/app_theme.dart';

/// Halaman untuk Owner set threshold transaksi besar
class ThresholdSettingsPage extends StatefulWidget {
  const ThresholdSettingsPage({super.key});

  @override
  State<ThresholdSettingsPage> createState() => _ThresholdSettingsPageState();
}

class _ThresholdSettingsPageState extends State<ThresholdSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _thresholdController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _businessId;
  int? _currentThreshold;

  @override
  void initState() {
    super.initState();
    _loadCurrentThreshold();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentThreshold() async {
    setState(() => _isLoading = true);
    
    try {
      // Get businessId from first cabang
      final cabangs = await DomainApiService.fetchCabangs();
      if (!mounted || cabangs.isEmpty) return;
      
      _businessId = cabangs.first.businessId;
      if (_businessId == null || _businessId!.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      // Get business info
      final business = await DomainApiService.getBusinessInfo(_businessId!);
      if (!mounted) return;
      
      _currentThreshold = business['threshold_transaksi'] as int?;
      
      if (_currentThreshold != null && _currentThreshold! > 0) {
        _thresholdController.text = _formatCurrency(_currentThreshold!);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0)
        .format(amount)
        .replaceAll(',', '.');
  }

  int _parseCurrency(String text) {
    return int.tryParse(text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  Future<void> _saveThreshold() async {
    if (!_formKey.currentState!.validate()) return;
    if (_businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business ID tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final threshold = _thresholdController.text.isEmpty 
          ? null 
          : _parseCurrency(_thresholdController.text);
      
      await DomainApiService.updateBusinessThreshold(_businessId!, threshold);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Threshold berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Batas Transaksi Besar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Tentang Fitur Ini',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sistem akan mendeteksi transaksi yang melebihi batas nominal yang Anda tetapkan. '
                              'Anda akan mendapat notifikasi untuk meninjau transaksi tersebut.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Batas Nominal Transaksi Besar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _thresholdController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        helperText: 'Kosongkan untuk menonaktifkan notifikasi',
                        helperMaxLines: 2,
                        border: const OutlineInputBorder(),
                        suffixIcon: _thresholdController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _thresholdController.clear());
                                },
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = _parseCurrency(value);
                          if (amount <= 0) {
                            return 'Nominal harus lebih dari 0';
                          }
                        }
                        return null;
                      },
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    if (_thresholdController.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          border: Border.all(color: Colors.amber.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, 
                                color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Transaksi di atas Rp ${_thresholdController.text} '
                                'akan muncul di notifikasi untuk ditinjau.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveThreshold,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Custom input formatter untuk format Rupiah
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) {
      return oldValue;
    }

    // Format with thousand separators
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
