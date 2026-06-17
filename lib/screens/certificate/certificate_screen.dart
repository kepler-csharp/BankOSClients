import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/certificate_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banking_provider.dart';
import '../../widgets/common.dart';

/// Solicitud y descarga de certificado bancario.
///
/// Requisito de seguridad (#7): antes de generar el certificado, el cliente
/// debe reingresar sus credenciales de acceso. Validamos contra el endpoint
/// real /auth/login (mismo tenant). Solo si es correcto, generamos el PDF,
/// lo "enviamos" al correo (simulado) y permitimos descargarlo/compartirlo.
class CertificateScreen extends StatefulWidget {
  final Account? preselectedAccount;
  const CertificateScreen({super.key, this.preselectedAccount});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Account? _account;
  final _password = TextEditingController();
  bool _obscure = true;
  bool _verified = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final accounts = context.read<BankingProvider>().accounts;
    _account = widget.preselectedAccount ??
        (accounts.isNotEmpty ? accounts.first : null);
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Verifica las credenciales reingresadas contra el backend.
  Future<void> _verifyIdentity() async {
    if (_password.text.isEmpty) {
      showSnack(context, 'Ingresa tu contraseña.', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() => _busy = true);
    try {
      // Reautenticación: validamos contraseña con el email y tenant actuales.
      await AuthRepository().login(
        email: auth.user?.email ?? '',
        password: _password.text,
        tenantId: auth.tenantId ?? '',
        tenantName: auth.tenantName ?? '',
      );
      setState(() {
        _verified = true;
        _busy = false;
        _password.clear();
      });
      if (mounted) {
        showSnack(context, 'Identidad verificada.');
      }
    } on ApiException catch (e) {
      setState(() => _busy = false);
      if (mounted) showSnack(context, e.friendly, error: true);
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        showSnack(context, 'No se pudo verificar tu identidad.', error: true);
      }
    }
  }

  Future<void> _generate() async {
    if (_account == null) {
      showSnack(context, 'Selecciona una cuenta.', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() => _busy = true);
    try {
      final file = await CertificateService.instance.generate(
        account: _account!,
        holderName: auth.user?.name ?? 'Cliente',
        holderEmail: auth.user?.email ?? '',
        bankName: auth.tenantName ?? '',
      );
      setState(() => _busy = false);
      if (!mounted) return;
      // Confirmación + opción de descargar/compartir.
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: BankColors.cardDark,
          title: const Row(children: [
            Icon(Icons.verified, color: BankColors.green),
            SizedBox(width: 10),
            Expanded(child: Text('Certificado listo')),
          ]),
          content: Text(
            'Generamos el certificado de tu cuenta ${_account!.accountNumber} y '
            'lo enviamos a ${auth.user?.email}. También puedes descargarlo ahora.',
            style: const TextStyle(
                color: BankColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: BankColors.brightBlue),
              onPressed: () async {
                Navigator.pop(context);
                await CertificateService.instance.shareOrPrint(file);
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        showSnack(context, 'No se pudo generar el certificado.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<BankingProvider>().accounts;
    return Scaffold(
      appBar: AppBar(title: const Text('Certificado bancario')),
      body: BrandBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  gradient: LinearGradient(
                    colors: [
                      BankColors.royalBlue.withValues(alpha: 0.5),
                      BankColors.violet.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.workspace_premium,
                          color: Colors.white, size: 40),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Genera un certificado oficial de tu cuenta. Por tu '
                          'seguridad, confirma tu identidad antes de continuar.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (accounts.isEmpty)
                  const GlassCard(
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 48, color: BankColors.textMuted),
                        SizedBox(height: 12),
                        Text('No tienes cuentas para certificar.',
                            style: TextStyle(color: BankColors.textSecondary)),
                      ],
                    ),
                  )
                else ...[
                  const Text('Cuenta a certificar',
                      style: TextStyle(
                          color: BankColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: BankColors.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BankColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Account>(
                        value: _account != null &&
                                accounts.any((a) => a.id == _account!.id)
                            ? accounts
                                .firstWhere((a) => a.id == _account!.id)
                            : accounts.first,
                        isExpanded: true,
                        dropdownColor: BankColors.cardDark,
                        items: accounts
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    '${a.accountNumber} · ${a.currency}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (a) => setState(() => _account = a),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_account != null)
                    GlassCard(
                      child: Column(
                        children: [
                          _row('Número', _account!.accountNumber),
                          const Divider(height: 18),
                          _row('Moneda', _account!.currency),
                          const Divider(height: 18),
                          _row(
                              'Saldo',
                              Formatters.money(
                                  _account!.balance, _account!.currency)),
                          const Divider(height: 18),
                          _row(
                              'Estado',
                              _account!.isActive
                                  ? 'Activa'
                                  : _account!.status),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Paso de seguridad
                  if (!_verified) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BankColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: BankColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  color: BankColors.warning, size: 18),
                              SizedBox(width: 8),
                              Text('Verificación de seguridad',
                                  style: TextStyle(
                                      color: BankColors.warning,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Confirma tu contraseña para generar y recibir el certificado.',
                            style: TextStyle(
                                color: BankColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: 'Tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Verificar identidad',
                      icon: Icons.verified_user_outlined,
                      loading: _busy,
                      onPressed: _busy ? null : _verifyIdentity,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BankColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: BankColors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: BankColors.green, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Identidad verificada. Ya puedes generar tu certificado.',
                                style: TextStyle(
                                    color: BankColors.textSecondary,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Generar y enviar certificado',
                      icon: Icons.workspace_premium,
                      loading: _busy,
                      onPressed: _busy ? null : _generate,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: BankColors.textSecondary)),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}
