import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
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

  // ── Destino de transferencia ──────────────────────────────────────
  // Modo del destino: mismo banco vs. otro banco.
  bool _externalMode = false;

  // Mismo banco (búsqueda por número dentro de mis cuentas del tenant)
  Account? _destAccount;
  List<Account> _destResults = [];

  // Otro banco (cross-tenant)
  List<Bank> _banks = [];
  String? _myTenantId;
  Bank? _destBank;
  ExternalAccount? _destExternal; // cuenta resuelta en el otro banco

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
    final accounts = context.read<BankingProvider>().activeAccounts;
    _source = widget.sourceAccount ??
        (accounts.isNotEmpty ? accounts.first : null);

    _loadBanksAndTenant();

    // Si vino del QR, pre-llenamos el destino.
    if (widget.prefill != null) {
      _type = TxType.transfer;
      _destSearch.text = widget.prefill!.accountNumber;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyPrefill(widget.prefill!));
    }
  }

  Future<void> _loadBanksAndTenant() async {
    _myTenantId = await SecureStore.instance.tenantId;
    try {
      final banking = context.read<BankingProvider>();
      final banks = await banking.accountRepo.banks();
      if (mounted) {
        setState(() {
          // Para "otro banco" excluimos el banco propio.
          _banks = banks.where((b) => b.id != _myTenantId).toList();
        });
      }
    } catch (_) {
      // Si no carga la lista de bancos, el modo "otro banco" quedará vacío.
    }
  }

  Future<void> _applyPrefill(QrPrefill p) async {
    final myTenant = await SecureStore.instance.tenantId;
    if (p.tenantId.isNotEmpty && p.tenantId != myTenant) {
      // El QR es de OTRO banco → activamos modo externo y resolvemos.
      setState(() {
        _externalMode = true;
        _destBank = _banks.cast<Bank?>().firstWhere(
              (b) => b?.id == p.tenantId,
              orElse: () => Bank(id: p.tenantId, name: p.tenantId),
            );
      });
      // Asegurar que el banco del QR esté en la lista del dropdown.
      if (!_banks.any((b) => b.id == p.tenantId)) {
        setState(() => _banks = [..._banks, _destBank!]);
      }
      await _resolveExternal(p.accountNumber);
      if (mounted && _destExternal != null) {
        setState(() => _prefillNote =
            'Datos cargados desde el QR de ${p.ownerName} (banco ${_destBank!.name}).');
      }
      return;
    }
    // Mismo banco
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

  // ── Búsqueda de cuenta destino (MISMO banco) ──────────────────────
  Future<void> _searchDest(String term, {bool autoSelect = false}) async {
    if (term.trim().length < 3) {
      setState(() => _destResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final banking = context.read<BankingProvider>();
      final results = await banking.accountRepo.searchByNumber(term.trim());
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

  // ── Resolver cuenta en OTRO banco (cross-tenant) ──────────────────
  Future<void> _resolveExternal(String number) async {
    if (_destBank == null) {
      showSnack(context, 'Selecciona el banco destino primero.', error: true);
      return;
    }
    if (number.trim().length < 3) {
      setState(() => _destExternal = null);
      return;
    }
    setState(() {
      _searching = true;
      _destExternal = null;
    });
    try {
      final banking = context.read<BankingProvider>();
      final ext = await banking.txRepo.resolveExternal(
        destTenantId: _destBank!.id,
        destAccountNumber: number.trim(),
      );
      setState(() {
        _destExternal = ext;
        _searching = false;
      });
    } on ApiException catch (e) {
      setState(() => _searching = false);
      showSnack(context, e.friendly, error: true);
    } catch (e) {
      setState(() => _searching = false);
      showSnack(context, 'No se encontró la cuenta en ese banco.', error: true);
    }
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
        if (_externalMode) {
          await _doTransferExternal();
        } else {
          await _doTransfer();
        }
        break;
      case TxType.withdrawal:
        await _requestWithdrawalCode();
        break;
    }
  }

  Future<void> _doDeposit() async {
    setState(() => _busy = true);
    final banking = context.read<BankingProvider>();
    try {
      await banking.txRepo.deposit(
        accountId: _source!.id,
        amount: _amountValue,
        description: _description.text,
      );
      await banking.loadAll();
      if (mounted) _success('Depósito realizado con éxito. Te enviamos un correo.');
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
    try {
      await banking.txRepo.transfer(
        sourceAccountId: _source!.id,
        destinationAccountId: _destAccount!.id,
        amount: _amountValue,
        description: _description.text,
      );
      await banking.loadAll();
      if (mounted) _success('Transferencia realizada con éxito. Te enviamos un correo.');
    } on ApiException catch (e) {
      _fail(e.friendly);
    } catch (e) {
      _fail('No se pudo realizar la transferencia.');
    }
  }

  Future<void> _doTransferExternal() async {
    if (_destBank == null) {
      showSnack(context, 'Selecciona el banco destino.', error: true);
      return;
    }
    if (_destExternal == null) {
      showSnack(context, 'Busca y confirma la cuenta destino.', error: true);
      return;
    }
    setState(() => _busy = true);
    final banking = context.read<BankingProvider>();
    try {
      await banking.txRepo.transferExternal(
        sourceAccountId: _source!.id,
        destTenantId: _destBank!.id,
        destAccountNumber: _destExternal!.accountNumber,
        amount: _amountValue,
        description: _description.text,
      );
      await banking.loadAll();
      if (mounted) {
        _success('Transferencia a ${_destBank!.name} realizada. Te enviamos un correo.');
      }
    } on ApiException catch (e) {
      _fail(e.friendly);
    } catch (e) {
      _fail('No se pudo realizar la transferencia entre bancos.');
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
        showSnack(context, 'Código enviado a tu correo. Válido 10 minutos.');
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
    try {
      await banking.txRepo.confirmWithdrawal(
        accountId: _source!.id,
        amount: _amountValue,
        code: _otpCode.text,
        description: _description.text,
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
                if (!_withdrawalNeedsCode) _typeSelector(),
                const SizedBox(height: 20),

                _sectionLabel('Cuenta'),
                const SizedBox(height: 8),
                _accountDropdown(accounts),
                const SizedBox(height: 20),

                // Destino (solo transferencia)
                if (_type == TxType.transfer && !_withdrawalNeedsCode) ...[
                  _destModeToggle(),
                  const SizedBox(height: 16),
                  _sectionLabel(_externalMode ? 'Banco destino' : 'Destino'),
                  const SizedBox(height: 8),
                  if (_externalMode) _externalDestSection() else _destField(),
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
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
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
              _destExternal = null;
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

  // Toggle entre "Mismo banco" y "Otro banco"
  Widget _destModeToggle() {
    Widget chip(String label, IconData icon, bool external) {
      final selected = _externalMode == external;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _externalMode = external;
            _destAccount = null;
            _destExternal = null;
            _destResults = [];
            _destSearch.clear();
            _prefillNote = null;
          }),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? BankColors.brightBlue.withOpacity(0.18)
                  : BankColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected
                      ? BankColors.brightBlue
                      : BankColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected
                        ? BankColors.skyBlue
                        : BankColors.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? BankColors.skyBlue
                            : BankColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Mismo banco', Icons.account_balance, false),
        chip('Otro banco', Icons.swap_horiz, true),
      ],
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

  // ── Destino mismo banco ───────────────────────────────────────────
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

  // ── Destino otro banco (cross-tenant) ─────────────────────────────
  Widget _externalDestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selector de banco
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: BankColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BankColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Bank>(
              value: _destBank,
              isExpanded: true,
              hint: const Text('Selecciona el banco'),
              dropdownColor: BankColors.cardDark,
              items: _banks
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance,
                                size: 16, color: BankColors.skyBlue),
                            const SizedBox(width: 8),
                            Flexible(
                                child: Text(b.name,
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (b) => setState(() {
                _destBank = b;
                _destExternal = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Número de cuenta + botón buscar
        _sectionLabel('Número de cuenta en ese banco'),
        const SizedBox(height: 8),
        TextField(
          controller: _destSearch,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
          ],
          decoration: InputDecoration(
            hintText: 'Número de cuenta destino',
            prefixIcon: const Icon(Icons.tag),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.search, color: BankColors.skyBlue),
                    onPressed: _destBank == null
                        ? null
                        : () => _resolveExternal(_destSearch.text),
                  ),
          ),
          onChanged: (_) => setState(() => _destExternal = null),
          onSubmitted: (v) => _resolveExternal(v),
        ),
        // Confirmación del titular resuelto
        if (_destExternal != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BankColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BankColors.green.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user,
                    color: BankColors.green, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _destExternal!.ownerName.isEmpty
                            ? 'Cuenta verificada'
                            : _destExternal!.ownerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_destExternal!.bankName} · ${_destExternal!.accountNumber} · ${_destExternal!.currency}',
                        style: const TextStyle(
                            color: BankColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text(
                'Enviamos un código de 6 dígitos a tu correo. Es válido por 10 minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(
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