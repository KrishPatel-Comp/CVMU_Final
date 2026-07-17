import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/services/sms_service.dart';
import '../widgets/primary_button.dart';
import '../core/services/api_service.dart';
import '../core/services/user_service.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'Food & Dining';

  final List<String> _categories = [
    'Shopping',
    'Food & Dining',
    'Transport',
    'Bills & Utilities',
    'Health',
    'EMI / Finance',
    'Other'
  ];

  void _submit() {
    final amountText = _amountCtrl.text.trim();
    final merchant = _merchantCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid amount and merchant name.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tx = SmsTransaction(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      rawBody: 'Manually added expense',
      sender: 'Manual',
      amount: amount,
      type: TransactionType.debit,
      date: DateTime.now(),
      category: _category,
      merchant: merchant,
      note: note.isEmpty ? null : note,
    );

    SmsService().addManualTransaction(tx);

    // Sync to backend if logged in
    if (UserService.userId != null) {
      ApiService().createTransaction(
        userId: UserService.userId!,
        amount: amount,
        merchantName: merchant,
        category: _category,
        note: note,
        rawSms: 'Manual entry via app',
      );
    }

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
          const Text('Add Manual Expense',
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
              hintText: 'e.g. 500',
              prefixIcon: const Icon(Icons.currency_rupee, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              fillColor: AppColors.surfaceVariant,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Merchant Name',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _merchantCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Swiggy, Amazon',
              prefixIcon: const Icon(Icons.storefront, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              fillColor: AppColors.surfaceVariant,
              filled: true,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              fillColor: AppColors.surfaceVariant,
              filled: true,
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _category = val);
              }
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              fillColor: AppColors.surfaceVariant,
              filled: true,
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            gradient: AppColors.accentGradient,
            text: 'Save Expense',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
