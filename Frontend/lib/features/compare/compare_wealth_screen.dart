import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/sms_service.dart';
import '../../widgets/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class CompareWealthScreen extends StatefulWidget {
  const CompareWealthScreen({super.key});

  @override
  State<CompareWealthScreen> createState() => _CompareWealthScreenState();
}

class _CompareWealthScreenState extends State<CompareWealthScreen> {
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

  String _formatAmount(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    // Dynamic computations based on real spending
    final spent = _smsService.totalDebit;
    final potential = spent * 1.12; // 12% CAGR
    final inflation = spent * 0.04; // 4% inflation loss

    final hasData = spent > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending vs. Wealth Potential',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'See how your spending could have grown if invested instead.',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
            const SizedBox(height: 24),
            
            if (!hasData) ...[
              const SizedBox(height: 40),
              _buildNoDataCard(),
            ] else ...[
              // Wealth Growth Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF1A2D4A)],
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
                    Text('Estimated Wealth Growth',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${_formatAmount(potential)}',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('+12%',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        text: 'Based on current data',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBar(
                          height: spent > 0 ? 80 : 0,
                          color: AppColors.accentSecondary,
                          label: 'SPENT',
                        ),
                        _buildBar(
                          height: potential > 0 ? 110 : 0,
                          color: AppColors.accent,
                          label: 'POTENTIAL',
                          isPrimary: true,
                        ),
                        _buildBar(
                          height: inflation > 0 ? 30 : 0,
                          color: AppColors.error,
                          label: 'INFLATION',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stat Cards
              _buildStatCard('Amount Spent', '₹${_formatAmount(spent)}', 'Direct Outflow',
                  Icons.money_off_rounded, AppColors.accentSecondary),
              _buildStatCard('Wealth Potential', '₹${_formatAmount(potential)}', '+12% CAGR',
                  Icons.trending_up_rounded, AppColors.accent),
              _buildStatCard('Inflation Impact', '₹${_formatAmount(inflation)}', '-4% Loss',
                  Icons.trending_down_rounded, AppColors.error),
              const SizedBox(height: 8),
              // Insight Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accentSecondary.withOpacity(0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.indigoGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('The Opportunity Cost',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          const Text(
                            'Every rupee spent today is a rupee that isn\'t growing for your future. '
                            'While inflation eats away 4% of your purchasing power annually, a disciplined investment can yield a 12% CAGR.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Text('Learn how to optimize',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentSecondary)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 14,
                                  color: AppColors.accentSecondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('No Comparison Data Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Start tracking your expenses or sync your SMS to see how much wealth you could be building. In the meantime, learn the basics of investing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            gradient: AppColors.accentGradient,
            text: 'Learn Investing Basics',
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
            onPressed: () async {
              final url = Uri.parse('https://www.investopedia.com/terms/b/beginnerinvesting.asp');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
      {required double height,
      required Color color,
      required String label,
      bool isPrimary = false}) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 52,
          height: height.clamp(5, 150).toDouble(), // ensure bar is slightly visible even for 0
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.3),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }
}
