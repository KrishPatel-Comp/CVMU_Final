import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/sms_service.dart';
import '../core/services/api_service.dart';
import '../widgets/primary_button.dart';

class EditExpenseSheet extends StatefulWidget {
  final SmsTransaction transaction;
  const EditExpenseSheet({super.key, required this.transaction});

  static void show(BuildContext context, SmsTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExpenseSheet(transaction: transaction),
    );
  }

  @override
  State<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<EditExpenseSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late TextEditingController _noteCtrl;
  late String _category;

  final List<String> _categories = [
    'Shopping',
    'Food & Dining',
    'Transport',
    'Bills & Utilities',
    'Health',
    'Income',
    'Cash Withdrawal',
    'EMI / Finance',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.transaction.amount.toString());
    _merchantCtrl = TextEditingController(text: widget.transaction.merchant ?? widget.transaction.sender);
    _noteCtrl = TextEditingController(text: widget.transaction.note ?? '');
    _category = widget.transaction.category;
  }

  void _submit() async {
    final amountText = _amountCtrl.text.trim();
    final merchant = _merchantCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and merchant name.')),
      );
      return;
    }

    final updatedTx = widget.transaction.copyWith(
      amount: amount,
      merchant: merchant,
      category: _category,
      note: note.isEmpty ? null : note,
    );

    // Sync to backend if it's a backend transaction (has int ID or we assume all are synced for now)
    // Actually our IDs are strings, either 'manual_...' or from SMS or from Backend.
    // For simplicity, we try to update if it's not starting with 'manual' or just try anyway.
    
    final result = await ApiService().updateTransaction(
      transactionId: widget.transaction.id,
      amount: amount,
      merchantName: merchant,
      category: _category,
      note: note,
    );

    if (result.containsKey('error')) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync Error: ${result['error']}')),
      );
    }

    SmsService().updateLocalTransaction(updatedTx);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Edit Expense',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            const Text('Amount (₹)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Merchant',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _merchantCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.storefront, size: 18),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category_outlined, size: 18),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('Optional Note',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              gradient: AppColors.accentGradient,
              text: 'Update Expense',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
