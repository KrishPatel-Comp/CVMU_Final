import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/api_service.dart';
import '../../core/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _pinCtrls = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _pinNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (var c in _pinCtrls) {
      c.dispose();
    }
    for (var n in _pinNodes) {
      n.dispose();
    }
    super.dispose();
  }

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
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // App Logo
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withOpacity(0.2),
                        AppColors.accentSecondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: AppColors.accent, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'RupeeLens',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personal lens for secure and\ntransparent financial tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                // Login Card
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
                      const Center(
                        child: Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'Enter your credentials to access your vault',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text('Email Address',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.email_outlined,
                                color: AppColors.textTertiary, size: 20),
                          ),
                          hintText: 'name@example.com',
                          fillColor: AppColors.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('Secure PIN',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3)),
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
                                controller: _pinCtrls[index],
                                focusNode: _pinNodes[index],
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
                                    _pinNodes[index + 1].requestFocus();
                                  } else if (val.isEmpty && index > 0) {
                                    _pinNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot PIN?',
                              style: TextStyle(
                                  color: AppColors.accentSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        gradient: AppColors.accentGradient,
                        text: _isLoading ? 'Logging in...' : 'Login Securely',
                        onPressed: _isLoading ? () {} : () async {
                          final email = _emailCtrl.text.trim();
                          final pin = _pinCtrls.map((c) => c.text).join();
                          
                          if (email.isEmpty || pin.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter email and 6-digit PIN')),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);
                          final result = await ApiService().login(email, pin);
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

                          // Success! Update UserService and navigate
                          if (result.containsKey('user')) {
                            final userData = result['user'];
                            UserService.userId = userData['id'];
                            UserService.firstName = userData['first_name'] ?? 'User';
                            UserService.email = userData['email'];
                            UserService.phone = userData['phone'];
                          }

                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/home_layout');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Biometrics Section
                Text('OR USE BIOMETRICS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withOpacity(0.15),
                        AppColors.accentSecondary.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.fingerprint,
                      color: AppColors.accent, size: 34),
                ),
                const SizedBox(height: 12),
                Text('Touch sensor to login',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text('Register',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
