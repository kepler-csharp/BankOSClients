import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/mail_service.dart';
import 'providers/auth_provider.dart';
import 'providers/banking_provider.dart';
import 'providers/pqrs_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/dashboard/home_shell.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const BankOsApp());
}

class BankOsApp extends StatelessWidget {
  const BankOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => BankingProvider()),
        ChangeNotifierProvider(create: (_) => PqrsProvider()),
        ChangeNotifierProvider.value(value: MailService.instance),
      ],
      child: MaterialApp(
        title: 'BankOs',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        locale: const Locale('es'),
        home: const _Root(),
      ),
    );
  }
}

/// Enruta según la fase de autenticación.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.phase) {
      case AuthPhase.loading:
        return const _Splash();
      case AuthPhase.loggedOut:
        return const LoginScreen();
      case AuthPhase.awaitingOtp:
        return const OtpScreen();
      case AuthPhase.loggedIn:
        return const HomeShell();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 110),
              const SizedBox(height: 20),
              const CircularProgressIndicator(strokeWidth: 2.5),
            ],
          ),
        ),
      ),
    );
  }
}
