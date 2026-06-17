import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../legal/privacy_screen.dart';
import 'kyc_screen.dart';

class RegisterScreen extends StatefulWidget {
  final List<Bank> banks;
  const RegisterScreen({super.key, required this.banks});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Bank? _bank;
  bool _obscure = true;
  bool _acceptedPrivacy = false;

  @override
  void initState() {
    super.initState();
    _bank = widget.banks.isNotEmpty ? widget.banks.first : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_bank == null) {
      showSnack(context, 'Selecciona tu banco.', error: true);
      return;
    }
    if (!_acceptedPrivacy) {
      showSnack(context, 'Debes aceptar la política de privacidad.',
          error: true);
      return;
    }
    // El registro se completa tras la verificación de identidad (KYC).
    // Pasamos los datos del formulario a la pantalla de captura de fotos.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycScreen(
          registration: PendingRegistration(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            tenantId: _bank!.id,
            tenantName: _bank!.name,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: BrandBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/logo-text.png', height: 60),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<Bank>(
                      initialValue: _bank,
                      isExpanded: true,
                      dropdownColor: BankColors.cardDark,
                      decoration: const InputDecoration(
                        labelText: 'Banco',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      items: widget.banks
                          .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.name,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (b) => setState(() => _bank = b),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Ingresa tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (!v.contains('@')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Mínimo 8 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'No coincide' : null,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _acceptedPrivacy,
                      onChanged: (v) =>
                          setState(() => _acceptedPrivacy = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: BankColors.brightBlue,
                      title: Wrap(
                        children: [
                          const Text('Acepto la ',
                              style: TextStyle(
                                  color: BankColors.textSecondary,
                                  fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PrivacyScreen())),
                            child: const Text('política de privacidad',
                                style: TextStyle(
                                    color: BankColors.skyBlue, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Continuar',
                      icon: Icons.arrow_forward,
                      loading: auth.busy,
                      onPressed: auth.busy ? null : _submit,
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
