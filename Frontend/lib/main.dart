import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/otp_screen.dart';
import 'home_layout.dart';

void main() {
  runApp(const RupeeLensApp());
}

class RupeeLensApp extends StatelessWidget {
  const RupeeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RupeeLens',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/otp': (context) => const OtpScreen(),
        '/home_layout': (context) => const HomeLayout(),
      },
    );
  }
}
