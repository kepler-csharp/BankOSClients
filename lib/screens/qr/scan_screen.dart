import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/bank_colors.dart';
import '../../widgets/common.dart';
import '../transactions/transaction_form.dart';

/// Escanea un QR de cobro con la cámara y autollena los datos de la
/// transferencia (número de cuenta, banco/tenant, moneda, titular).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    QrPrefill? prefill;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // Validamos que sea un QR de BankOs (tiene account_number).
      if (map['account_number'] == null) {
        throw const FormatException('QR no reconocido');
      }
      prefill = QrPrefill(
        accountNumber: (map['account_number'] ?? '').toString(),
        tenantId: (map['tenant_id'] ?? '').toString(),
        currency: (map['currency'] ?? '').toString(),
        ownerName: (map['owner_name'] ?? 'destinatario').toString(),
      );
    } catch (_) {
      // No es un QR válido de BankOs.
      _handled = true;
      showSnack(context, 'Este QR no es válido para transferencias BankOs.',
          error: true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _handled = false);
      });
      return;
    }

    _handled = true;
    _controller.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionForm(
          initialType: TxType.transfer,
          prefill: prefill,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Marco visual de escaneo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: BankColors.skyBlue, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: BankColors.violet.withValues(alpha: 0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: BankColors.skyBlue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Apunta al código QR de la persona para autollenar los datos de la transferencia.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
