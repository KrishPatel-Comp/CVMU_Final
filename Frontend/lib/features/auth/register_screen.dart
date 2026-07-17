import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/sms_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(6, (_) => FocusNode());

  // State
  String? _userType;
  String? _budgetRange;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  static const List<String> _userTypes = ['Student', 'Employed', 'Unemployed'];
  static const List<String> _budgetRanges = [
    '<1000',
    '1000-2000',
    '2000-5000',
    '5000-10000',
    '>10000',
  ];

  bool get _needsBudget =>
      _userType == 'Student' || _userType == 'Unemployed';
  bool get _needsSalary => _userType == 'Employed';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _salaryCtrl.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── SMS Permission Popup ────────────────────────────────────────────────
  Future<void> _showSmsPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.sms_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'Allow SMS Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'RupeeLens would like to read your SMS messages to automatically detect and track financial transactions for a seamless experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 8),
              // Privacy note
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.accent.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your data stays private & is never shared.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Deny',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          // Actually request Android SMS permission & read inbox
                          final granted =
                              await SmsService().requestPermissionAndLoad();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(granted
                                    ? '✅ SMS access granted. Scanning transactions…'
                                    : '⚠️ SMS permission denied.'),
                                backgroundColor: granted
                                    ? AppColors.success
                                    : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Allow',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
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

  // ── Sign-Up Handler ─────────────────────────────────────────────────────
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms of Service.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Collect PIN
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a complete 6-digit PIN.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Build payload
    final String email = _emailCtrl.text.trim();
    final String firstName = _firstNameCtrl.text.trim();
    final String lastName = _lastNameCtrl.text.trim();
    final String phone = _mobileCtrl.text.trim();
    final String userType = _userType!.toLowerCase();
    
    int? monthlyBudget;
    if (_needsBudget) {
      // Parse budget range like "1000-2000" to a median or just the lower bound
      final range = _budgetRange ?? "0";
      if (range.contains('-')) {
        monthlyBudget = int.tryParse(range.split('-')[1]);
      } else if (range.startsWith('<')) {
        monthlyBudget = int.tryParse(range.substring(1));
      } else if (range.startsWith('>')) {
        monthlyBudget = int.tryParse(range.substring(1));
      } else {
        monthlyBudget = int.tryParse(range);
      }
    }

    final int? salary = _needsSalary ? int.tryParse(_salaryCtrl.text.trim()) : null;

    final result = await ApiService().register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      pin: pin,
      userType: userType,
      monthlyBudget: monthlyBudget,
      salary: salary,
    );

    setState(() => _isLoading = false);

    if (result.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Success! Send OTP before going to OTP screen
    await ApiService().sendOtp(email);

    if (!mounted) return;

    // Show SMS permission dialog after successful registration
    await _showSmsPermissionDialog();

    // Save First Name dynamically for the app session
    if (_firstNameCtrl.text.trim().isNotEmpty) {
      UserService.firstName = _firstNameCtrl.text.trim();
    }

    if (!mounted) return;
    Navigator.pushNamed(context, '/otp', arguments: email);
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF132240),
              Color(0xFF0F1B2D),
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // App Logo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withOpacity(0.2),
                          AppColors.accentSecondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'RupeeLens',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your wealth with clarity',
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 28),
                  // Register Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create Account',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Start your financial journey today',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 24),

                        // ── Name Row ─────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('First Name'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _firstNameCtrl,
                                    decoration: _inputDecoration(
                                        hintText: 'John'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Last Name'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _lastNameCtrl,
                                    decoration:
                                        _inputDecoration(hintText: 'Doe'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Email ────────────────────────────────────────
                        _label('Email Address'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            hintText: 'john.doe@example.com',
                            prefixIcon: const Icon(Icons.alternate_email,
                                color: AppColors.textTertiary, size: 20),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // ── Mobile ───────────────────────────────────────
                        _label('Mobile Number'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 17),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                border: Border.all(
                                    color:
                                        AppColors.border.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('+91',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _mobileCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                    hintText: '9876543210'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Mobile required';
                                  }
                                  if (v.trim().length != 10) {
                                    return '10 digits required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── User Type Dropdown ───────────────────────────
                        _label('User Type'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _userType,
                          decoration: _inputDecoration(
                            hintText: 'Select your occupation',
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: AppColors.textTertiary, size: 20),
                          ),
                          items: _userTypes
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _userType = val;
                              _budgetRange = null;
                              _salaryCtrl.clear();
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Please select a user type' : null,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 18),

                        // ── Dynamic Financial Section ────────────────────
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 350),
                          crossFadeState: _userType == null
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: const SizedBox.shrink(),
                          secondChild: _buildFinancialSection(),
                        ),

                        // ── 6-digit PIN ──────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _label('Create 6-digit Secure PIN'),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Required',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return Container(
                              width: 44,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                border: Border.all(
                                    color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _pinControllers[index],
                                  focusNode: _pinFocusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  maxLength: 1,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    fillColor: Colors.transparent,
                                    counterText: '',
                                  ),
                                  onChanged: (val) {
                                    if (val.isNotEmpty && index < 5) {
                                      FocusScope.of(context).requestFocus(
                                          _pinFocusNodes[index + 1]);
                                    } else if (val.isEmpty && index > 0) {
                                      FocusScope.of(context).requestFocus(
                                          _pinFocusNodes[index - 1]);
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use a unique PIN for your RupeeLens financial data security.',
                          style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 22),

                        // ── Terms Checkbox ───────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              setState(() => _agreedToTerms = !_agreedToTerms),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _agreedToTerms
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: _agreedToTerms
                                          ? AppColors.accent
                                          : AppColors.border,
                                      width: 1.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _agreedToTerms
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'I agree to the ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    children: [
                                      TextSpan(
                                          text: 'Terms of Service',
                                          style: TextStyle(
                                              color:
                                                  AppColors.accentSecondary,
                                              fontWeight: FontWeight.w600)),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                          text: 'Privacy Policy.',
                                          style: TextStyle(
                                              color:
                                                  AppColors.accentSecondary,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Sign Up Button ───────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Sign Up',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward,
                                            color: Colors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Sign-in Link ─────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                              child: const Text('Sign In',
                                  style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text('256-BIT SSL SECURE ENCRYPTION',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Financial Section (conditionally shown) ─────────────────────────────
  Widget _buildFinancialSection() {
    if (_userType == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider with label
        Row(
          children: [
            Expanded(
                child: Divider(color: AppColors.border.withOpacity(0.6))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 6),
                  const Text('Financial Profile',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
            Expanded(
                child: Divider(color: AppColors.border.withOpacity(0.6))),
          ],
        ),
        const SizedBox(height: 16),

        if (_needsBudget) ...[
          _label('Monthly Budget Range'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _budgetRange,
            decoration: _inputDecoration(
              hintText: 'Select your monthly budget',
              prefixIcon: const Icon(Icons.wallet_outlined,
                  color: AppColors.textTertiary, size: 20),
            ),
            items: _budgetRanges
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text('₹ $r'),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _budgetRange = val),
            validator: (v) =>
                v == null ? 'Please select a budget range' : null,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textTertiary),
          ),
          const SizedBox(height: 18),
        ],

        if (_needsSalary) ...[
          _label('Monthly Salary (₹)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _salaryCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              hintText: 'e.g. 45000',
              prefixIcon: const Icon(Icons.currency_rupee_rounded,
                  color: AppColors.textTertiary, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your monthly salary';
              }
              if (double.tryParse(v.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3));
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      fillColor: AppColors.surfaceVariant,
      filled: true,
      prefixIcon: prefixIcon != null
          ? Padding(padding: const EdgeInsets.all(12), child: prefixIcon)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
          color: AppColors.textTertiary, fontSize: 14),
      errorStyle:
          const TextStyle(color: AppColors.error, fontSize: 11),
    );
  }
}
