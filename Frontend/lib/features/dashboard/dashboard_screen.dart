import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/sms_service.dart';
import '../../widgets/custom_card.dart';
import '../../core/services/api_service.dart';
import '../../core/services/user_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SmsService _smsService = SmsService();
  Map<String, dynamic>? _comparisonData;
  bool _isLoadingComparison = true;

  @override
  void initState() {
    super.initState();
    _smsService.addListener(_onUpdate);
    _fetchComparison();
  }

  Future<void> _fetchComparison() async {
    if (UserService.userId == null) return;
    setState(() => _isLoadingComparison = true);
    final data = await ApiService().getMonthlyComparison(UserService.userId!);
    if (mounted) {
      setState(() {
        _comparisonData = data;
        _isLoadingComparison = false;
      });
    }
  }

  @override
  void dispose() {
    _smsService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  String _formatAmount(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // Total spent THIS month
    double spentThisMonth = 0;
    for (var tx in _smsService.transactions) {
      if (tx.type == TransactionType.debit && tx.date.isAfter(firstDayOfMonth)) {
        spentThisMonth += tx.amount;
      }
    }

    // Calculate budget guidance based on salary
    double budget;
    final salary = UserService.salary;
    if (salary <= 20000) {
      budget = 2000;
    } else if (salary <= 40000) {
      budget = 4000;
    } else if (salary <= 60000) {
      budget = 6000;
    } else {
      budget = salary * 0.1;
    }

    // Humor / Motivational message
    String message;
    IconData messageIcon;
    Color messageColor;

    if (spentThisMonth == 0) {
      message = "Ready to track your first expense? 🚀";
      messageIcon = Icons.rocket_launch_rounded;
      messageColor = AppColors.accent;
    } else if (spentThisMonth > budget) {
      message = "Oops! You spent more than your budget ☕😅";
      messageIcon = Icons.warning_amber_rounded;
      messageColor = AppColors.error;
    } else {
      message = "You're saving like a pro! 🏆";
      messageIcon = Icons.emoji_events_rounded;
      messageColor = AppColors.success;
    }
    
    // Calculate simple category distribution for THIS month
    double bills = 0, shopping = 0, food = 0, transport = 0, others = 0;
    for (var tx in _smsService.transactions) {
      if (tx.type == TransactionType.debit && tx.date.isAfter(firstDayOfMonth)) {
        if (tx.category == 'Bills & Utilities') bills += tx.amount;
        else if (tx.category == 'Shopping') shopping += tx.amount;
        else if (tx.category == 'Food & Dining') food += tx.amount;
        else if (tx.category == 'Transport') transport += tx.amount;
        else others += tx.amount;
      }
    }

    final double totalDistribution = (bills + shopping + food + transport + others) == 0 ? 1 : bills + shopping + food + transport + others;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards Row
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Spent This Month',
                    '₹${_formatAmount(spentThisMonth)}',
                    Icons.calendar_month_rounded,
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    'Budget Guide',
                    '₹${_formatAmount(budget)}',
                    Icons.account_balance_wallet_outlined,
                    AppColors.accentSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Humor / Motivational Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: messageColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: messageColor.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Icon(messageIcon, color: messageColor, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: messageColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Category Distribution',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        sections: spentThisMonth == 0
                            ? [
                                PieChartSectionData(
                                  color: Colors.grey.withOpacity(0.3),
                                  value: 100,
                                  title: '0%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                )
                              ]
                            : [
                                if (bills > 0) PieChartSectionData(
                                  color: AppColors.primary,
                                  value: bills,
                                  title: '${((bills / totalDistribution) * 100).toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                if (shopping > 0) PieChartSectionData(
                                  color: AppColors.accentSecondary,
                                  value: shopping,
                                  title: '${((shopping / totalDistribution) * 100).toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                if (food > 0) PieChartSectionData(
                                  color: AppColors.accent,
                                  value: food,
                                  title: '${((food / totalDistribution) * 100).toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                if (transport > 0) PieChartSectionData(
                                  color: AppColors.pending,
                                  value: transport,
                                  title: '${((transport / totalDistribution) * 100).toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                if (others > 0) PieChartSectionData(
                                  color: Colors.grey,
                                  value: others,
                                  title: '${((others / totalDistribution) * 100).toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _legendItem('Bills', AppColors.primary),
                      _legendItem('Shopping', AppColors.accentSecondary),
                      _legendItem('Food', AppColors.accent),
                      _legendItem('Transport', AppColors.pending),
                      _legendItem('Others', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Monthly Trend',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            CustomCard(
              child: SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.border.withOpacity(0.5),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500);
                            Widget text;
                            switch (value.toInt()) {
                              case 0:
                                text = const Text('Jan', style: style);
                                break;
                              case 2:
                                text = const Text('Mar', style: style);
                                break;
                              case 4:
                                text = const Text('May', style: style);
                                break;
                              case 6:
                                text = const Text('Jul', style: style);
                                break;
                              case 8:
                                text = const Text('Sep', style: style);
                                break;
                              default:
                                text = const Text('');
                            }
                            return SideTitleWidget(axisSide: meta.axisSide, child: text);
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spentThisMonth == 0 ? [
                          const FlSpot(0, 0),
                          const FlSpot(2, 0),
                          const FlSpot(4, 0),
                          const FlSpot(6, 0),
                          const FlSpot(8, 0),
                          const FlSpot(10, 0),
                        ] : [
                          const FlSpot(0, 3),
                          const FlSpot(2, 2),
                          const FlSpot(4, 5),
                          const FlSpot(6, 3.1),
                          const FlSpot(8, 4),
                          const FlSpot(10, 3)
                        ], // Keeping trend dummy logic for aesthetic purposes for now
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentSecondary],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2.5,
                              strokeColor: AppColors.accent,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accent.withOpacity(0.2),
                              AppColors.accent.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildComparisonSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    if (_isLoadingComparison) {
      return const Center(child: CircularProgressIndicator());
    }

    final current = _comparisonData?['current_month_spending'] ?? 0.0;
    final last = _comparisonData?['last_month_spending'] ?? 0.0;

    if (current == 0 && last == 0) {
      return const SizedBox.shrink();
    }

    final diff = _comparisonData?['difference'] ?? 0.0;
    final insight = _comparisonData?['insight'] ?? 'No data yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Comparison',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        CustomCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _comparisonStat('Last Month', '₹${_formatAmount(last.toDouble())}', Colors.grey),
                  const Icon(Icons.compare_arrows_rounded, color: AppColors.textTertiary),
                  _comparisonStat('This Month', '₹${_formatAmount(current.toDouble())}', AppColors.accent),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: last == 0 ? 0 : (current / (current + last)).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  color: AppColors.accent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
