import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/sms_service.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/add_expense_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsService _smsService = SmsService();

  @override
  void initState() {
    super.initState();
    _smsService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _smsService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    double spentThisMonth = 0;
    for (var tx in _smsService.transactions) {
      if (tx.type == TransactionType.debit && tx.date.isAfter(firstDayOfMonth)) {
        spentThisMonth += tx.amount;
      }
    }

    final recentTxs = _smsService.transactions.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Spending Summary Card with gradient
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1628), Color(0xFF1A2D4A), Color(0xFF0F1B2D)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Spending',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward,
                              size: 12, color: Color(0xFFFF6B6B)),
                          SizedBox(width: 4),
                          Text('Live',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF6B6B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('₹${_formatAmount(spentThisMonth)}',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1)),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Spent This Month:',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13)),
                    Text('₹${_formatAmount(spentThisMonth)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
          // Quick Actions Row
          Row(
            children: [
              _quickAction(Icons.add_rounded, 'Add\nExpense', AppColors.accent, () {
                AddExpenseSheet.show(context);
              }),
              const SizedBox(width: 12),
              _quickAction(Icons.compare_arrows_rounded, 'Compare\nWealth', AppColors.accentSecondary, () {
                widget.onNavigate?.call(2);
              }),
              const SizedBox(width: 12),
              _quickAction(Icons.pie_chart_rounded, 'View\nDashboard', AppColors.pending, () {
                widget.onNavigate?.call(1);
              }),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Transactions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => widget.onNavigate?.call(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('See All',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (recentTxs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No recent transactions.',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...recentTxs.map((tx) {
              final isDebit = tx.type == TransactionType.debit;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionTile(
                  title: tx.merchant ?? tx.sender,
                  subtitle: '${tx.category}${tx.note != null ? ' • ${tx.note}' : ''} • ${tx.date.day} ${_monthName(tx.date.month)}',
                  amount: '${isDebit ? '-' : '+'} ${tx.amountFormatted}',
                  icon: Icon(Icons.receipt_long, color: isDebit ? AppColors.error : AppColors.success, size: 20),
                  iconBackgroundColor: (isDebit ? AppColors.error : AppColors.success).withOpacity(0.1),
                  isPending: false,
                  onDelete: () => _smsService.removeTransaction(tx.id),
                ),
              );
            }).toList(),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => AddExpenseSheet.show(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
