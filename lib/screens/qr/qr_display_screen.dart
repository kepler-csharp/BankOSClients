import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/bank_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/repositories/banking_repository.dart';
import '../../widgets/common.dart';

/// Genera y muestra el QR de cobro de una cuenta.
/// El QR NO se almacena en ningún lado: se pide el payload al backend y se
/// renderiza al vuelo. Cada vez que entras, se vuelve a generar.
class QrDisplayScreen extends StatefulWidget {
  final Account account;
  const QrDisplayScreen({super.key, required this.account});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final _repo = QrRepository();
  QrPayload? _payload;
  String? _qrData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await _repo.generate(widget.account.id);
      // Empaquetamos el payload como JSON para el QR (lo que lee el escáner).
      final data = jsonEncode({
        'account_number': payload.accountNumber,
        'tenant_id': payload.tenantId,
        'currency': payload.currency,
        'owner_name': payload.ownerName,
      });
      setState(() {
        _payload = payload;
        _qrData = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.friendly;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'No se pudo generar el código QR.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi código QR')),
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const CircularProgressIndicator()
                  : _error != null
                      ? _errorView()
                      : _qrView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qrView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Muestra este código para recibir transferencias',
          textAlign: TextAlign.center,
          style: TextStyle(color: BankColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: BankColors.violet.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: QrImageView(
            data: _qrData!,
            version: QrVersions.auto,
            size: 240,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: BankColors.deepBlue,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: BankColors.royalBlue,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            children: [
              _info('Titular', _payload!.ownerName),
              const Divider(height: 20),
              _info('Cuenta', _payload!.accountNumber),
              const Divider(height: 20),
              _info('Moneda', _payload!.currency),
              const Divider(height: 20),
              _info('Saldo',
                  Formatters.money(widget.account.balance, widget.account.currency)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: _payload!.accountNumber));
                  showSnack(context, 'Número de cuenta copiado.');
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar cuenta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BankColors.skyBlue,
                  side: const BorderSide(color: BankColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BankColors.skyBlue,
                  side: const BorderSide(color: BankColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '🔒 Este código se genera al momento y no se almacena.',
          style: TextStyle(color: BankColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _info(String label, String value) {
    return Row(
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

  Widget _errorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2, size: 56, color: BankColors.warning),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BankColors.textSecondary)),
        const SizedBox(height: 16),
        GradientButton(
            label: 'Reintentar', icon: Icons.refresh, onPressed: _generate),
      ],
    );
  }
}
