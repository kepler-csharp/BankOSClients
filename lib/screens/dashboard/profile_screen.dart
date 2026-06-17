import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/mail_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../legal/privacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              const Text('Perfil',
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Tarjeta de usuario
              GlassCard(
                gradient: LinearGradient(
                  colors: [
                    BankColors.royalBlue.withValues(alpha: 0.6),
                    BankColors.violet.withValues(alpha: 0.4),
                    BankColors.emerald.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        (user?.name.isNotEmpty == true
                                ? user!.name[0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Cliente',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(user?.email ?? '',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              auth.tenantName ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Cuenta'),
              _tile(
                context,
                Icons.lock_outline,
                'Cambiar contraseña',
                'Actualiza tu clave de acceso',
                () => _openChangePassword(context),
              ),
              _tile(
                context,
                Icons.mark_email_read_outlined,
                'Bandeja de notificaciones',
                'Correos enviados (simulación)',
                () => _openMailbox(context),
              ),

              const SizedBox(height: 16),
              _sectionTitle('Legal'),
              _tile(
                context,
                Icons.privacy_tip_outlined,
                'Política de privacidad',
                'Cómo protegemos tus datos',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
              _tile(
                context,
                Icons.info_outline,
                'Acerca de BankOs',
                'Versión 1.0.0',
                () => showAboutDialog(
                  context: context,
                  applicationName: 'BankOs',
                  applicationVersion: '1.0.0',
                  applicationIcon:
                      Image.asset('assets/images/logo.png', width: 48),
                  children: const [
                    Text(
                        'Banca para clientes. Una plataforma, todos los bancos.'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: BankColors.error),
                label: const Text('Cerrar sesión',
                    style: TextStyle(color: BankColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BankColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(t,
            style: const TextStyle(
                color: BankColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _tile(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: BankColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BankColors.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BankColors.brightBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: BankColors.skyBlue, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: BankColors.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: BankColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BankColors.cardDark,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir de tu cuenta?',
            style: TextStyle(color: BankColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BankColors.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _openChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _openMailbox(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _MailboxScreen()),
    );
  }
}

// ── Cambiar contraseña ────────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    try {
      await AuthRepository()
          .changePassword(current: _current.text, next: _next.text);
      // Notificación por correo (simulada).
      await MailService.instance.sendAccountUpdated(
        to: auth.user?.email ?? '',
        userName: auth.user?.name ?? '',
        detail: 'Cambiaste tu contraseña de acceso.',
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Contraseña actualizada. Te enviamos un correo.');
    } on ApiException catch (e) {
      setState(() => _busy = false);
      if (mounted) showSnack(context, e.friendly, error: true);
    } catch (e) {
      setState(() => _busy = false);
      if (mounted) {
        showSnack(context, 'No se pudo cambiar la contraseña.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: BankColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: BankColors.cardBorder)),
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BankColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cambiar contraseña',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (v) =>
                  (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => v != _next.text ? 'No coincide' : null,
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Actualizar',
              icon: Icons.check,
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bandeja de correos simulados ──────────────────────────────────────
class _MailboxScreen extends StatelessWidget {
  const _MailboxScreen();

  IconData _iconFor(MailKind k) => switch (k) {
        MailKind.otp => Icons.password,
        MailKind.accountUpdate => Icons.sync_alt,
        MailKind.certificate => Icons.workspace_premium,
        MailKind.generic => Icons.email_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final mail = context.watch<MailService>();
    final items = mail.outbox;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context.read<MailService>().clear(),
            ),
        ],
      ),
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BankColors.brightBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: BankColors.brightBlue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: BankColors.skyBlue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Estos correos se simulan localmente en la app para la demo. '
                        'En producción se envían desde el servidor.',
                        style: TextStyle(
                            color: BankColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('No hay notificaciones todavía.',
                            style: TextStyle(color: BankColors.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final m = items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BankColors.cardDark,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: BankColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(_iconFor(m.kind),
                                        size: 18,
                                        color: BankColors.skyBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(m.subject,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Para: ${m.to}',
                                    style: const TextStyle(
                                        color: BankColors.textMuted,
                                        fontSize: 11)),
                                const SizedBox(height: 6),
                                Text(m.body,
                                    style: const TextStyle(
                                        color: BankColors.textSecondary,
                                        fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(Formatters.date(m.at),
                                    style: const TextStyle(
                                        color: BankColors.textMuted,
                                        fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
