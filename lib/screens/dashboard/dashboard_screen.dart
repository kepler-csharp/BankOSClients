import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banking_provider.dart';
import '../../widgets/common.dart';
import '../certificate/certificate_screen.dart';
import '../qr/qr_display_screen.dart';
import '../qr/scan_screen.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final banking = context.watch<BankingProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: BankColors.skyBlue,
            backgroundColor: BankColors.cardDark,
            onRefresh: () => banking.loadAll(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(context, auth)),
                if (banking.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (banking.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _errorState(context, banking),
                  )
                else ...[
                  SliverToBoxAdapter(child: _accountsSection(context, banking)),
                  SliverToBoxAdapter(child: _quickActions(context, banking)),
                  SliverToBoxAdapter(child: _recentHeader(context)),
                  _recentList(banking),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _header(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola,',
                    style: TextStyle(
                        color: BankColors.textSecondary, fontSize: 13)),
                Text(
                  auth.user?.name ?? 'Cliente',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BankColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BankColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance,
                    size: 14, color: BankColors.skyBlue),
                const SizedBox(width: 6),
                Text(
                  auth.tenantName ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cuentas ───────────────────────────────────────────────────────
  Widget _accountsSection(BuildContext context, BankingProvider banking) {
    final accounts = banking.accounts;
    if (accounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            children: const [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: BankColors.textMuted),
              SizedBox(height: 12),
              Text('Aún no tienes cuentas activas',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text(
                'Cuando tu banco cree una cuenta para ti, aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: BankColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text('Mis cuentas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: accounts.length,
            itemBuilder: (_, i) => _accountCard(context, accounts[i], i),
          ),
        ),
      ],
    );
  }

  Widget _accountCard(BuildContext context, Account a, int index) {
    final accent = BankColors.forCurrency(a.currency);
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BankColors.royalBlue,
            accent.withOpacity(0.85),
            BankColors.emerald.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(a.currency,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Icon(
                a.isActive ? Icons.verified : Icons.lock_outline,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
            ],
          ),
          const Spacer(),
          Text('Saldo disponible',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.money(a.balance, a.currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '•••• ${a.accountNumber.length > 4 ? a.accountNumber.substring(a.accountNumber.length - 4) : a.accountNumber}',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniBtn(context, Icons.qr_code, 'Cobrar', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QrDisplayScreen(account: a)),
                );
              }),
              const SizedBox(width: 8),
              _miniBtn(context, Icons.description_outlined, 'Certificado', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CertificateScreen(preselectedAccount: a)),
                );
              }),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 90).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.15);
  }

  Widget _miniBtn(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Acciones rápidas ──────────────────────────────────────────────
  Widget _quickActions(BuildContext context, BankingProvider banking) {
    final actions = [
      (
        Icons.add_circle_outline,
        'Depositar',
        BankColors.green,
        () => _openTx(context, banking, TxType.deposit),
      ),
      (
        Icons.arrow_outward,
        'Transferir',
        BankColors.brightBlue,
        () => _openTx(context, banking, TxType.transfer),
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Retirar',
        BankColors.magenta,
        () => _openTx(context, banking, TxType.withdrawal),
      ),
      (
        Icons.qr_code_scanner,
        'Escanear',
        BankColors.teal,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ScanScreen())),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          return Column(
            children: [
              Material(
                color: a.$3.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: a.$4,
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: Icon(a.$1, color: a.$3, size: 26),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(a.$2,
                  style: const TextStyle(
                      fontSize: 12, color: BankColors.textSecondary)),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _openTx(BuildContext context, BankingProvider banking, TxType type) {
    if (banking.activeAccounts.isEmpty) {
      showSnack(context, 'No tienes cuentas activas para esta operación.',
          error: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionForm(initialType: type)),
    );
  }

  // ── Movimientos ───────────────────────────────────────────────────
  Widget _recentHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Movimientos recientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            ),
            child: const Text('Ver todos'),
          ),
        ],
      ),
    );
  }

  Widget _recentList(BankingProvider banking) {
    final tx = banking.transactions.take(8).toList();
    if (tx.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('Sin movimientos todavía.',
                style: TextStyle(color: BankColors.textMuted)),
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: tx.length,
      itemBuilder: (_, i) => TransactionTile(tx: tx[i], accounts: banking.accounts),
    );
  }

  Widget _errorState(BuildContext context, BankingProvider banking) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: BankColors.warning),
          const SizedBox(height: 16),
          Text(banking.error ?? 'Error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: BankColors.textSecondary)),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Reintentar',
            icon: Icons.refresh,
            onPressed: () => banking.loadAll(),
          ),
        ],
      ),
    );
  }
}

/// Fila de transacción reutilizable.
class TransactionTile extends StatelessWidget {
  final TxModel tx;
  final List<Account> accounts;
  const TransactionTile({super.key, required this.tx, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final myAccountIds = accounts.map((a) => a.id).toSet();
    final isIncoming = tx.type == 'deposit' ||
        (tx.type == 'transfer' &&
            tx.destinationAccountId != null &&
            myAccountIds.contains(tx.destinationAccountId) &&
            !myAccountIds.contains(tx.accountId));

    final (icon, color, sign) = switch (tx.type) {
      'deposit' => (Icons.south_west, BankColors.green, '+'),
      'withdrawal' => (Icons.north_east, BankColors.magenta, '−'),
      'transfer' => isIncoming
          ? (Icons.south_west, BankColors.green, '+')
          : (Icons.north_east, BankColors.brightBlue, '−'),
      _ => (Icons.swap_horiz, BankColors.textSecondary, ''),
    };

    final label = switch (tx.type) {
      'deposit' => 'Depósito',
      'withdrawal' => 'Retiro',
      'transfer' => isIncoming ? 'Transferencia recibida' : 'Transferencia enviada',
      _ => tx.type,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BankColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BankColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  tx.description?.isNotEmpty == true
                      ? tx.description!
                      : Formatters.date(tx.createdAt),
                  style: const TextStyle(
                      color: BankColors.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${Formatters.money(tx.amount, tx.currency)}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (tx.fee > 0)
                Text('Comisión ${Formatters.money(tx.fee, tx.currency)}',
                    style: const TextStyle(
                        color: BankColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
