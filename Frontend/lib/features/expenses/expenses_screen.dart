import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/sms_service.dart';
import '../../widgets/add_expense_sheet.dart';
import '../../widgets/edit_expense_sheet.dart';
import '../../core/services/api_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final SmsService _smsService = SmsService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _smsService.addListener(_onSmsUpdate);
  }

  @override
  void dispose() {
    _smsService.removeListener(_onSmsUpdate);
    super.dispose();
  }

  void _onSmsUpdate() => setState(() {});

  // ── Category icon + color map ─────────────────────────────────────────────
  static const Map<String, _CategoryMeta> _categoryMeta = {
    'Shopping':        _CategoryMeta(Icons.shopping_bag_outlined,  Color(0xFF8B5CF6), Color(0xFFF3EEFF)),
    'Food & Dining':   _CategoryMeta(Icons.restaurant_menu_rounded, Color(0xFFF59E0B), Color(0xFFFFF8E6)),
    'Transport':       _CategoryMeta(Icons.directions_car_rounded,  Color(0xFF5B6EF5), Color(0xFFEEF0FF)),
    'Bills & Utilities':_CategoryMeta(Icons.bolt_rounded,           Color(0xFF00D09C), Color(0xFFE6FBF5)),
    'Health':          _CategoryMeta(Icons.favorite_border_rounded, Color(0xFFEF4444), Color(0xFFFFEEEE)),
    'Income':          _CategoryMeta(Icons.savings_outlined,        Color(0xFF00D09C), Color(0xFFE6FBF5)),
    'Cash Withdrawal': _CategoryMeta(Icons.atm_rounded,             Color(0xFF6B7A8D), Color(0xFFF0F4F8)),
    'EMI / Finance':   _CategoryMeta(Icons.account_balance_outlined,Color(0xFF0F1B2D), Color(0xFFE8EFF7)),
    'Other':           _CategoryMeta(Icons.receipt_long_rounded,    Color(0xFF9EAAB8), Color(0xFFF0F4F8)),
  };

  _CategoryMeta _metaFor(String cat) =>
      _categoryMeta[cat] ?? _categoryMeta['Other']!;

  // ── Group by date label ───────────────────────────────────────────────────
  Map<String, List<SmsTransaction>> _groupByDate(List<SmsTransaction> txs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<SmsTransaction>>{};

    for (final tx in txs) {
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (d == today) {
        label = 'TODAY';
      } else if (d == yesterday) {
        label = 'YESTERDAY';
      } else {
        label =
            '${_monthName(tx.date.month).toUpperCase()} ${tx.date.day}, ${tx.date.year}';
      }
      map.putIfAbsent(label, () => []).add(tx);
    }
    return map;
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final allTxs = _smsService.transactions;
    final txs = allTxs.where((tx) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final m = (tx.merchant ?? tx.sender).toLowerCase();
      final c = tx.category.toLowerCase();
      final n = (tx.note ?? '').toLowerCase();
      return m.contains(q) || c.contains(q) || n.contains(q);
    }).toList();

    final grouped = _groupByDate(txs);
    final hasData = txs.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Summary header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF1A2D4A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _smsService.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(
                              color: AppColors.accent),
                        ),
                      )
                    : !_smsService.permissionGranted
                        ? _buildGrantPrompt()
                        : _buildSummaryContent(),
              ),
            ),
          ),

          // ── Error banner ────────────────────────────────────────────────
          if (_smsService.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _smsService.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Search Bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by merchant, category or note...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                  fillColor: Colors.white.withOpacity(0.05),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          // ── Empty state ─────────────────────────────────────────────────
          if (_smsService.permissionGranted && !hasData && !_smsService.isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sms_outlined,
                          color: AppColors.accent, size: 48),
                    ),
                    const SizedBox(height: 20),
                    const Text('No transactions found',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      'No bank/UPI SMS found in your inbox.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),

          // ── Grouped transaction list ────────────────────────────────────
          if (hasData)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entries = grouped.entries.toList();
                    int cursor = 0;
                    for (final entry in entries) {
                      // Section header
                      if (index == cursor) {
                        return _buildSectionHeader(entry.key);
                      }
                      cursor++;
                      // Tiles
                      for (int i = 0; i < entry.value.length; i++) {
                        if (index == cursor) {
                          return _buildTransactionTile(entry.value[i]);
                        }
                        cursor++;
                      }
                      // Spacer between groups
                      if (index == cursor) {
                        return const SizedBox(height: 20);
                      }
                      cursor++;
                    }
                    return null;
                  },
                  childCount: grouped.entries.fold<int>(
                    0,
                    (sum, e) => sum + 1 + e.value.length + 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _smsService.permissionGranted
          ? Container(
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                tooltip: 'Add Expense',
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 26),
              ),
            )
          : null,
    );
  }

  // ── Grant Permission Prompt (inside header) ───────────────────────────────
  Widget _buildGrantPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sms_outlined,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SMS Transaction Tracking',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  SizedBox(height: 4),
                  Text(
                      'Allow SMS access to auto-detect your bank & UPI transactions.',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            await _smsService.requestPermissionAndLoad();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('Allow SMS Access',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary Numbers ───────────────────────────────────────────────────────
  Widget _buildSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_smsService.transactions.length} transactions detected',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent, size: 18),
              onPressed: () => _smsService.requestPermissionAndLoad(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Scan SMS',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _summaryChip(
                label: 'Total Spent',
                value:
                    '₹${_formatAmount(_smsService.totalDebit)}',
                color: AppColors.error,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryChip(
                label: 'Total Received',
                value:
                    '₹${_formatAmount(_smsService.totalCredit)}',
                color: AppColors.accent,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }

  // ── Transaction Tile ──────────────────────────────────────────────────────
  Widget _buildTransactionTile(SmsTransaction tx) {
    final meta = _metaFor(tx.category);
    final isDebit = tx.type == TransactionType.debit;
    final amountColor = isDebit ? AppColors.error : AppColors.success;
    final timeStr =
        '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          EditExpenseSheet.show(context, tx);
          return false;
        }
        return true;
      },
      onDismissed: (_) async {
        _smsService.removeTransaction(tx.id);
        await ApiService().deleteTransaction(tx.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        }
      },
      child: GestureDetector(
        onTap: () => _showTxDetail(tx),
        onLongPress: () => _confirmDelete(tx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: meta.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meta.icon, color: meta.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.merchant ?? tx.sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.category}${tx.note != null ? ' • ${tx.note}' : ''} • $timeStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? '-' : '+'}${tx.amountFormatted}',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: amountColor),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.typeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: amountColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail Bottom Sheet ───────────────────────────────────────────────────
  void _confirmDelete(SmsTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Expense?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to delete this expense record?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _smsService.removeTransaction(tx.id);
      await ApiService().deleteTransaction(tx.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    }
  }

  void _showTxDetail(SmsTransaction tx) {
    final meta = _metaFor(tx.category);
    final isDebit = tx.type == TransactionType.debit;
    final amountColor = isDebit ? AppColors.error : AppColors.success;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            // Icon + amount
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: meta.backgroundColor,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(meta.icon, color: meta.color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              '${isDebit ? '-' : '+'} ${tx.amountFormatted}',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: amountColor),
            ),
            const SizedBox(height: 6),
            Text(
              tx.merchant ?? tx.sender,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            // Details grid
            _detailRow('Category', tx.category),
            _detailRow('Type', tx.typeLabel),
            _detailRow('Sender', tx.sender),
            if (tx.account != null) _detailRow('Account', tx.account!),
            if (tx.upiRef != null) _detailRow('UPI Ref', tx.upiRef!),
            if (tx.balanceAfter != null)
              _detailRow('Balance After', tx.balanceAfter!),
            _detailRow(
              'Date & Time',
              '${tx.date.day} ${_monthName(tx.date.month)} ${tx.date.year}, '
                  '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 16),
            // Raw SMS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Text(
                tx.rawBody,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double v) {
    return v
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CategoryMeta {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  const _CategoryMeta(this.icon, this.color, this.backgroundColor);
}
