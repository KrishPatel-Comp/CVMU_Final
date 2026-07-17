import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/api_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isVerifying = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is String) {
        setState(() {
          _email = args;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
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
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('Verify Mobile',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accent.withOpacity(0.2),
                                AppColors.accentSecondary.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.message_outlined,
                              size: 36, color: AppColors.accent),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Enter Verification Code',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We have sent a 6-digit code to\n${_email ?? "+91 9876543210"}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.55),
                              height: 1.5),
                        ),
                        const SizedBox(height: 40),
                        // OTP Fields
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  return Container(
                                    width: 46,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      border: Border.all(
                                          color: Colors.black, width: 1.5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: TextField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary),
                                        onChanged: (value) =>
                                            _onChanged(value, index),
                                        decoration: const InputDecoration(
                                          counterText: "",
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          fillColor: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),
                              // Timer Row
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer,
                                        size: 16,
                                        color: AppColors.textTertiary),
                                    const SizedBox(width: 8),
                                    const Text('05:00',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                gradient: AppColors.accentGradient,
                                text: _isVerifying ? 'Verifying...' : 'Verify & Continue',
                                icon: _isVerifying 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                                onPressed: _isVerifying ? () {} : () async {
                                  final otp = _controllers.map((c) => c.text).join();
                                  if (otp.length < 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter 6-digit OTP')),
                                    );
                                    return;
                                  }

                                  if (_email == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Email not found')),
                                    );
                                    return;
                                  }

                                  setState(() => _isVerifying = true);
                                  final result = await ApiService().verifyOtp(_email!, otp);
                                  setState(() => _isVerifying = false);

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

                                  if (mounted) {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {},
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh,
                                        size: 16,
                                        color: AppColors.accentSecondary),
                                    const SizedBox(width: 6),
                                    const Text('Resend OTP',
                                        style: TextStyle(
                                            color: AppColors.accentSecondary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
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
