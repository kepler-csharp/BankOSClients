import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../legal/privacy_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  List<Bank> _banks = [];
  Bank? _selectedBank;
  bool _loadingBanks = true;
  String? _banksError;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _loadingBanks = true;
      _banksError = null;
    });
    try {
      final banks = await AuthRepository().fetchBanks();
      setState(() {
        _banks = banks;
        _selectedBank = banks.isNotEmpty ? banks.first : null;
        _loadingBanks = false;
      });
    } catch (e) {
      setState(() {
        _loadingBanks = false;
        _banksError = 'No se pudo cargar la lista de bancos. Revisa tu conexión.';
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedBank == null) {
      showSnack(context, 'Selecciona tu banco.', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginStep1(
      email: _email.text.trim(),
      password: _password.text,
      tenantId: _selectedBank!.id,
      tenantName: _selectedBank!.name,
    );
    if (!ok && mounted && auth.error != null) {
      showSnack(context, auth.error!, error: true);
    }
    // Si ok, el _Root cambia a OtpScreen automáticamente.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/full-logo.png', height: 150)
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Banca para clientes',
                          style: TextStyle(
                            color: BankColors.textSecondary,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Selector de banco
                      _label('Banco'),
                      const SizedBox(height: 8),
                      if (_loadingBanks)
                        const LinearProgressIndicator(minHeight: 2)
                      else if (_banksError != null)
                        _errorBox(_banksError!, _loadBanks)
                      else
                        DropdownButtonFormField<Bank>(
                          initialValue: _selectedBank,
                          isExpanded: true,
                          dropdownColor: BankColors.cardDark,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          items: _banks
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b.name,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (b) => setState(() => _selectedBank = b),
                        ),
                      const SizedBox(height: 18),

                      _label('Correo electrónico'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'tucorreo@ejemplo.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _label('Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      GradientButton(
                        label: 'Ingresar',
                        icon: Icons.login,
                        loading: auth.busy,
                        onPressed: auth.busy ? null : _submit,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?',
                              style:
                                  TextStyle(color: BankColors.textSecondary)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RegisterScreen(banks: _banks),
                                ),
                              );
                            },
                            child: const Text('Regístrate'),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.privacy_tip_outlined,
                              size: 18),
                          label: const Text('Política de privacidad'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacyScreen()),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          '🔒 Acceso con clave dinámica de un solo uso',
                          style: TextStyle(
                              color: BankColors.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: BankColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500));

  Widget _errorBox(String msg, VoidCallback retry) => GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: BankColors.warning),
            const SizedBox(width: 12),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(
                        color: BankColors.textSecondary, fontSize: 13))),
            TextButton(onPressed: retry, child: const Text('Reintentar')),
          ],
        ),
      );
}
