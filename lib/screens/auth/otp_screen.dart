import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/services/mail_service.dart';
import '../../data/services/otp_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers =
      List.generate(AppConfig.otpLength, (_) => TextEditingController());
  final _focus = List.generate(AppConfig.otpLength, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 0;
  String? _error;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // En modo demo mostramos el código (no hay correo real configurado).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDemoCode());
  }

  void _maybeShowDemoCode() {
    final code = MailService.instance.lastOtp;
    if (code == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BankColors.cardDark,
        title: const Row(children: [
          Icon(Icons.mark_email_unread_outlined, color: BankColors.skyBlue),
          SizedBox(width: 10),
          Text('Clave enviada'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se envió una clave dinámica a tu correo (simulado en esta demo). '
              'Tu código es:',
              style: TextStyle(color: BankColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Center(
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: BankColors.skyBlue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = OtpService.instance.secondsLeft;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = OtpService.instance.secondsLeft;
      if (!mounted) return;
      setState(() => _secondsLeft = left);
      if (left <= 0) t.cancel();
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < AppConfig.otpLength) {
      setState(() => _error = 'Ingresa los ${AppConfig.otpLength} dígitos.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final result = auth.verifyOtp(_code);
    if (result == OtpResult.valid) {
      // El _Root navega a HomeShell automáticamente.
      return;
    }
    setState(() {
      _verifying = false;
      _error = result.message;
      for (final c in _controllers) {
        c.clear();
      }
      _focus.first.requestFocus();
    });
  }

  Future<void> _resend() async {
    await context.read<AuthProvider>().resendOtp();
    _startTimer();
    if (mounted) {
      _maybeShowDemoCode();
      showSnack(context, 'Te enviamos una nueva clave.');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expired = _secondsLeft <= 0;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IconButton(
                      alignment: Alignment.centerLeft,
                      onPressed: () => context.read<AuthProvider>().cancelOtp(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: BankColors.cardGradient,
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: Colors.white, size: 40),
                      ),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Clave dinámica',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Ingresa la clave de ${AppConfig.otpLength} dígitos que enviamos a\n${auth.pendingEmail ?? "tu correo"}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: BankColors.textSecondary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Casillas del OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(AppConfig.otpLength, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: SizedBox(
                            width: 46,
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focus[i],
                              autofocus: i == 0,
                              enabled: !expired,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                counterText: '',
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < AppConfig.otpLength - 1) {
                                  _focus[i + 1].requestFocus();
                                } else if (v.isEmpty && i > 0) {
                                  _focus[i - 1].requestFocus();
                                }
                                if (_code.length == AppConfig.otpLength) {
                                  _verify();
                                }
                                setState(() => _error = null);
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Contador
                    Center(
                      child: expired
                          ? const Text(
                              '⏰ La clave expiró',
                              style: TextStyle(color: BankColors.error),
                            )
                          : Text(
                              'Vence en ${Formatters.mmss(_secondsLeft)}',
                              style: TextStyle(
                                color: _secondsLeft < 60
                                    ? BankColors.warning
                                    : BankColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(_error!,
                            style: const TextStyle(color: BankColors.error)),
                      ),
                    ],
                    const SizedBox(height: 28),

                    GradientButton(
                      label: 'Verificar',
                      icon: Icons.check_circle_outline,
                      loading: _verifying,
                      onPressed: expired || _verifying ? null : _verify,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _resend,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(expired
                          ? 'Solicitar nueva clave'
                          : 'Reenviar clave'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
