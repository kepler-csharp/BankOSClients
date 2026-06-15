import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/models.dart';
import '../data/repositories/banking_repository.dart';

class BankingProvider extends ChangeNotifier {
  final _accounts = AccountRepository();
  final _tx = TransactionRepository();
  final _config = ConfigRepository();

  List<Account> accounts = [];
  List<TxModel> transactions = [];
  Map<String, dynamic>? tenantConfig;

  bool loading = false;
  String? error;

  double get totalByMainCurrency {
    // Suma simple agrupada por moneda principal (la primera cuenta).
    if (accounts.isEmpty) return 0;
    final main = accounts.first.currency;
    return accounts
        .where((a) => a.currency == main)
        .fold(0.0, (s, a) => s + a.balance);
  }

  List<Account> get activeAccounts =>
      accounts.where((a) => a.isActive).toList();

  Future<void> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _accounts.myAccounts(),
        _tx.list(perPage: 50),
        _config.config().catchError((_) => <String, dynamic>{}),
      ]);
      accounts = results[0] as List<Account>;
      transactions = results[1] as List<TxModel>;
      tenantConfig = results[2] as Map<String, dynamic>;
    } on ApiException catch (e) {
      error = e.friendly;
    } catch (e) {
      error = 'No se pudieron cargar tus datos.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAccounts() async {
    accounts = await _accounts.myAccounts();
    notifyListeners();
  }

  Future<void> refreshTransactions() async {
    transactions = await _tx.list(perPage: 50);
    notifyListeners();
  }

  /// Accesos a repos para pantallas que ejecutan acciones puntuales.
  AccountRepository get accountRepo => _accounts;
  TransactionRepository get txRepo => _tx;

  double? get maxTransactionAmount {
    final v = tenantConfig?['max_transaction_amount'];
    if (v == null) return null;
    return v is num ? v.toDouble() : double.tryParse('$v');
  }
}
