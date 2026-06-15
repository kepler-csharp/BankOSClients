import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/services/mail_service.dart';
import '../../data/services/secure_store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/banking_provider.dart';
import '../../widgets/common.dart';

enum TxType { deposit, withdrawal, transfer }

/// Datos pre-llenados que pueden venir del escáner de QR.
class QrPrefill {
  final String accountNumber;
  final String tenantId;
  final String currency;
  final String ownerName;
  QrPrefill({
    required this.accountNumber,
    required this.tenantId,
    required this.currency,
    required this.ownerName,
  });
}

class TransactionForm extends StatefulWidget {
  final TxType initialType;
  final Account? sourceAccount;
  final QrPrefill? prefill;

  const TransactionForm({
    super.key,
    required this.initialType,
    this.sourceAccount,
    this.prefill,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late TxType _type;
  Account? _source;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _destSearch = TextEditingController();

  // Destino de transferencia
  Account? _destAccount;
  List<Account> _destResults = [];
  bool _searching = false;
  String? _prefillNote;

  // Retiro OTP
  bool _withdrawalNeedsCode = false;
  final _otpCode = TextEditingController();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final accounts =
        context.read<BankingProvider>().activeAccounts;
    _source = widget.sourceAccount ??
        (accounts.isNotEmpty ? accounts.first : null);

    // Si vino del QR, pre-llenamos el destino.
    if (widget.prefill != null) {
      _type = TxType.transfer;
      _destSearch.text = widget.prefill!.accountNumber;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyPrefill(widget.prefill!));
    }
  }

  Future<void> _applyPrefill(QrPrefill p) async {
    final myTenant = await SecureStore.instance.tenantId;
    if (p.tenantId.isNotEmpty && p.tenantId != myTenant) {
      // El destino pertenece a otro banco. La API actual no resuelve
      // cross-tenant por número; avisamos al usuario.
      setState(() {
        _prefillNote =
            'El QR es del banco "${p.tenantId}". Las transferencias entre bancos '
            'distintos no están disponibles en esta versión. Puedes transferir '
            'dentro de tu mismo banco.';
      });
      return;
    }
    await _searchDest(p.accountNumber, autoSelect: true);
    setState(() {
      _prefillNote = 'Datos cargados desde el QR de ${p.ownerName}.';
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _destSearch.dispose();
    _otpCode.dispose();
    super.dispose();
  }

  double get _amountValue =>
      double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;

  // ── Búsqueda de cuenta destino ────────────────────────────────────
  Future<void> _searchDest(String term, {bool autoSelect = false}) async {
    if (term.trim().length < 3) {
      setState(() => _destResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final banking = context.read<BankingProvider>();
      final results = await banking.accountRepo.searchByNumber(term.trim());
      // Excluir mis propias cuentas como destino.
      final myIds = banking.accounts.map((a) => a.id).toSet();
      final filtered = results.where((a) => !myIds.contains(a.id)).toList();
      setState(() {
        _destResults = filtered;
        _searching = false;
      });
      if (autoSelect && filtered.length == 1) {
        _selectDest(filtered.first);
      }
    } catch (e) {
      setState(() => _searching = false);
    }
  }

  void _selectDest(Account a) {
    setState(() {
      _destAccount = a;
      _destSearch.text = a.accountNumber;
      _destResults = [];
    });
  }

  // ── Ejecutar operaciones ──────────────────────────────────────────
  Future<void> _execute() async {
    if (_source == null) {
      showSnack(context, 'Selecciona una cuenta.', error: true);
      return;
    }
    if (_amountValue <= 0) {
      showSnack(context, 'Ingresa un monto válido.', error: true);
      return;
    }

    final max = context.read<BankingProvider>().maxTransactionAmount;
    if (max != null && _amountValue > max && _type != TxType.deposit) {
      showSnack(context,
          'El monto supera el límite por transacción (${Formatters.money(max, _source!.currency)}).',
          error: true);
      return;
    }

    switch (_type) {
      case TxType.deposit:
        await _doDeposit();
        break;
      case TxType.transfer:
        await _doTransfer();
        break;
      case TxType.withdrawal:
        await _requestWithdrawalCode();
        break;
    }
  }

  Future<void> _doDeposit() async {
    setState(() => _busy = true);
    final banking = context.read<BankingProvider>();
    final auth = context.read<AuthProvider>();
    try {
      final tx = await banking.txRepo.deposit(
        accountId: _source!.id,
        amount: _amountValue,
        description: _description.text,
      );
      // Notificación por correo (simulada, ya que la API no la envía).
      await MailService.instance.sendAccountUpdated(
        to: auth.user?.email ?? '',
        userName: auth.user?.name ?? '',
        detail:
            'Depósito de ${Formatters.money(tx.amount, tx.currency)} en la cuenta ${_source!.accountNumber}.',
      );
      await banking.loadAll();
      if (mounted) _success('Depósito realizado con éxito.');
    } on ApiException catch (e) {
      _fail(e.friendly);
    } catch (e) {
      _fail('No se pudo realizar el depósito.');
    }
  }

  Future<void> _doTransfer() async {
    if (_destAccount == null) {
      showSnack(context, 'Selecciona la cuenta de destino.', error: true);
      return;
    }
    setState(() => _busy = true);
    final banking = context.read<BankingProvider>();
    final auth = context.read<AuthProvider>();
    try {
      final tx = await banking.txRepo.transfer(
        sourceAccountId: _source!.id,
        destinationAccountId: _destAccount!.id,
        amount: _amountValue,
        description: _description.text,
      );
      await MailService.instance.sendAccountUpdated(
        to: auth.user?.email ?? '',
        userName: auth.user?.name ?? '',
        detail:
            'Transferencia enviada por ${Formatters.money(tx.amount, tx.currency)} a la cuenta ${_destAccount!.accountNumber}.',
      );
      await banking.loadAll();
      if (mounted) _success('Transferencia realizada con éxito.');
    } on ApiException catch (e) {
      _fail(e.friendly);
    } catch (e) {
      _fail('No se pudo realizar la transferencia.');
    }
  }

  Future<void> _requestWithdrawalCode() async {
    setState(() => _busy = true);
    final banking = context.read<BankingProvider>();
    try {
      await banking.txRepo.requestWithdrawalCode(
        accountId: _source!.id,
        amount: _amountValue,
      );
      setState(() {
        _busy = false;
        _withdrawalNeedsCode = true;
      });
      if (mounted) {
        showSnack(context,
            'Código enviado a tu correo. Válido 10 minutos.');
      }
    } on ApiException catch (e) {
      _fail(e.friendly);
    } catch (e) {
      _fail('No se pudo solicitar el código.');
    }
  }

  Future<void> _confirmWithdrawal() async {
    if (_otpCode.text.length != 6) {
      showSnack(context, 'Ingresa el código de 6 dígitos.', error: true);
      return;
    }
    setState(() => _busy = true);
    final banking = context.read<BankingProvider>();
    final auth = context.read<AuthProvider>();
    try {
      final tx = await banking.txRepo.confirmWithdrawal(
        accountId: _source!.id,
        amount: _amountValue,
        code: _otpCode.text,
        description: _description.text,
      );
      await MailService.instance.sendAccountUpdated(
        to: auth.user?.email ?? '',
        userName: auth.user?.name ?? '',
        detail:
            'Retiro de ${Formatters.money(tx.amount, tx.currency)} de la cuenta ${_source!.accountNumber}.',
      );
      await banking.loadAll();
      if (mounted) _success('Retiro realizado con éxito.');
    } on ApiException catch (e) {
      _fail(e.friendly);
    } catch (e) {
      _fail('No se pudo confirmar el retiro.');
    }
  }

  void _success(String msg) {
    setState(() => _busy = false);
    showSnack(context, msg);
    Navigator.pop(context);
  }

  void _fail(String msg) {
    setState(() => _busy = false);
    showSnack(context, msg, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<BankingProvider>().activeAccounts;
    final title = switch (_type) {
      TxType.deposit => 'Depositar',
      TxType.withdrawal => 'Retirar',
      TxType.transfer => 'Transferir',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BrandBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selector de tipo
                if (!_withdrawalNeedsCode) _typeSelector(),
                const SizedBox(height: 20),

                // Cuenta origen
                _sectionLabel('Cuenta'),
                const SizedBox(height: 8),
                _accountDropdown(accounts),
                const SizedBox(height: 20),

                // Destino (solo transferencia)
                if (_type == TxType.transfer && !_withdrawalNeedsCode) ...[
                  _sectionLabel('Destino'),
                  const SizedBox(height: 8),
                  _destField(),
                  if (_prefillNote != null) ...[
                    const SizedBox(height: 8),
                    _noteBox(_prefillNote!),
                  ],
                  const SizedBox(height: 20),
                ],

                if (!_withdrawalNeedsCode) ...[
                  _sectionLabel('Monto'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]')),
                    ],
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: '${_source?.currency ?? ''}  ',
                      prefixStyle: const TextStyle(
                          color: BankColors.skyBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Descripción (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Pago de servicios',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: _type == TxType.withdrawal
                        ? 'Solicitar código'
                        : 'Confirmar $title',
                    icon: _type == TxType.withdrawal
                        ? Icons.mark_email_read_outlined
                        : Icons.check_circle_outline,
                    loading: _busy,
                    onPressed: _busy ? null : _execute,
                  ),
                ],

                // Paso 2 del retiro: OTP
                if (_withdrawalNeedsCode) _otpStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeSelector() {
    final options = [
      (TxType.deposit, 'Depositar', Icons.add),
      (TxType.transfer, 'Transferir', Icons.arrow_outward),
      (TxType.withdrawal, 'Retirar', Icons.account_balance_wallet_outlined),
    ];
    return Row(
      children: options.map((o) {
        final selected = _type == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = o.$1;
              _destAccount = null;
              _destResults = [];
              _destSearch.clear();
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: selected ? BankColors.cardGradient : null,
                color: selected ? null : BankColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : BankColors.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(o.$3,
                      color: selected
                          ? Colors.white
                          : BankColors.textSecondary,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(o.$2,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white
                              : BankColors.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _accountDropdown(List<Account> accounts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: BankColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BankColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Account>(
          value: _source != null && accounts.any((a) => a.id == _source!.id)
              ? accounts.firstWhere((a) => a.id == _source!.id)
              : (accounts.isNotEmpty ? accounts.first : null),
          isExpanded: true,
          dropdownColor: BankColors.cardDark,
          items: accounts
              .map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(
                      '${a.accountNumber} · ${Formatters.money(a.balance, a.currency)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (a) => setState(() => _source = a),
        ),
      ),
    );
  }

  Widget _destField() {
    return Column(
      children: [
        TextField(
          controller: _destSearch,
          decoration: InputDecoration(
            hintText: 'Número de cuenta destino',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_destAccount != null
                    ? const Icon(Icons.check_circle, color: BankColors.green)
                    : null),
          ),
          onChanged: (v) {
            _destAccount = null;
            _searchDest(v);
          },
        ),
        if (_destResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: BankColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BankColors.cardBorder),
            ),
            child: Column(
              children: _destResults
                  .map((a) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline,
                            color: BankColors.skyBlue),
                        title: Text(a.accountNumber),
                        subtitle: Text(a.currency,
                            style: const TextStyle(fontSize: 12)),
                        onTap: () => _selectDest(a),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: BankColors.skyBlue, size: 40),
              const SizedBox(height: 12),
              const Text('Confirma tu retiro',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Enviamos un código de 6 dígitos a tu correo. Es válido por 10 minutos.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: BankColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Monto: ${Formatters.money(_amountValue, _source?.currency ?? '')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpCode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Confirmar retiro',
          icon: Icons.check_circle_outline,
          loading: _busy,
          onPressed: _busy ? null : _confirmWithdrawal,
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _withdrawalNeedsCode = false;
                    _otpCode.clear();
                  }),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          color: BankColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500));

  Widget _noteBox(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BankColors.brightBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BankColors.brightBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: BankColors.skyBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: BankColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      );
}
