import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../data/models/models.dart';
import '../../providers/banking_provider.dart';
import '../../widgets/common.dart';
import '../dashboard/dashboard_screen.dart' show TransactionTile;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = 'all'; // all | deposit | withdrawal | transfer

  List<TxModel> _apply(List<TxModel> all) {
    if (_filter == 'all') return all;
    return all.where((t) => t.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final banking = context.watch<BankingProvider>();
    final txs = _apply(banking.transactions);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos')),
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Filtros
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('all', 'Todos'),
                    _chip('deposit', 'Depósitos'),
                    _chip('withdrawal', 'Retiros'),
                    _chip('transfer', 'Transferencias'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  color: BankColors.skyBlue,
                  backgroundColor: BankColors.cardDark,
                  onRefresh: () => banking.refreshTransactions(),
                  child: txs.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.receipt_long_outlined,
                                size: 56, color: BankColors.textMuted),
                            SizedBox(height: 12),
                            Center(
                              child: Text('No hay movimientos en esta categoría.',
                                  style:
                                      TextStyle(color: BankColors.textMuted)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: txs.length,
                          itemBuilder: (_, i) => TransactionTile(
                              tx: txs[i], accounts: banking.accounts),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        backgroundColor: BankColors.surfaceDark,
        selectedColor: BankColors.brightBlue,
        labelStyle: TextStyle(
          color: selected ? Colors.white : BankColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
            color: selected ? Colors.transparent : BankColors.cardBorder),
      ),
    );
  }
}
