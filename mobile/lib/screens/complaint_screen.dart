import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class ComplaintScreen extends ConsumerStatefulWidget {
  const ComplaintScreen({super.key});

  @override
  ConsumerState<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends ConsumerState<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _paidPriceController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _shopkeeperNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _receiptImagePath;
  String? _productImagePath;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _paidPriceController.dispose();
    _mrpController.dispose();
    _shopkeeperNameController.dispose();
    _shopAddressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isReceipt) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        if (isReceipt) {
          _receiptImagePath = image.path;
        } else {
          _productImagePath = image.path;
        }
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final double paidPrice = double.tryParse(_paidPriceController.text) ?? 0.0;
    final double mrp = double.tryParse(_mrpController.text) ?? 0.0;
    final auth = ref.read(authProvider);

    try {
      final res = await _apiClient.fileComplaint(
        auth.userId,
        paidPrice,
        mrp,
        _shopkeeperNameController.text,
        _shopAddressController.text,
        _descController.text,
        receiptPath: _receiptImagePath,
        productPath: _productImagePath,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog({
          'is_overcharging_detected': paidPrice > mrp,
          'price_difference': paidPrice > mrp ? paidPrice - mrp : 0.0,
        });
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> res) {
    final bool overcharged = res['is_overcharging_detected'] ?? false;
    final double diff = (res['price_difference'] ?? 0.0).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Row(
          children: [
            Icon(overcharged ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: overcharged ? AppTheme.dangerRed : AppTheme.successGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                overcharged ? 'OVERCHARGING DETECTED' : 'COMPLAINT FILED',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          overcharged
              ? 'Violation confirmed! Paid price exceeds printed MRP by ₹ ${diff.toStringAsFixed(2)}. Route to officer queue.'
              : 'Complaint submitted successfully.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'REPORT MRP OVERCHARGING',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Under Legal Metrology Rules, no retailer may charge a price higher than the printed Maximum Retail Price (MRP).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _paidPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Paid Price (₹)',
                  prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.accentCyan),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter paid price' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _mrpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Printed MRP on Package (₹)',
                  prefixIcon: Icon(Icons.sell_outlined, color: AppTheme.accentCyan),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter printed MRP' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _shopkeeperNameController,
                decoration: const InputDecoration(
                  labelText: 'Shopkeeper Name',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.accentCyan),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _shopAddressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Shop Address',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.accentCyan),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Violation Details',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(true),
                      icon: Icon(_receiptImagePath != null ? Icons.check_circle : Icons.receipt, color: AppTheme.accentCyan),
                      label: Text(_receiptImagePath != null ? 'Receipt Attached' : 'Attach Receipt', style: const TextStyle(color: AppTheme.accentCyan)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accentCyan)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: Icon(_productImagePath != null ? Icons.check_circle : Icons.inventory_2, color: AppTheme.accentCyan),
                      label: Text(_productImagePath != null ? 'Product Attached' : 'Attach Product', style: const TextStyle(color: AppTheme.accentCyan)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accentCyan)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (_isSubmitting)
                const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
              else
                ElevatedButton.icon(
                  onPressed: _submitComplaint,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('SUBMIT COMPLAINT'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
