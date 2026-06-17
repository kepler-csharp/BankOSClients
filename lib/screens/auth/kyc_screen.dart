import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/bank_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

/// Datos del formulario de registro que llegan a la verificación de identidad.
class PendingRegistration {
  final String name;
  final String email;
  final String password;
  final String tenantId;
  final String tenantName;

  PendingRegistration({
    required this.name,
    required this.email,
    required this.password,
    required this.tenantId,
    required this.tenantName,
  });
}

/// Verificación de identidad (KYC). Tres capturas obligatorias con la cámara:
///   1. Foto del rostro
///   2. Documento de identidad — frente
///   3. Documento de identidad — reverso
///
/// Al completar, registra al usuario (que entra con normalidad) y las fotos
/// se envían al administrador del banco. El registro NO depende de que el
/// correo se entregue.
class KycScreen extends StatefulWidget {
  final PendingRegistration registration;
  const KycScreen({super.key, required this.registration});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _picker = ImagePicker();

  File? _face;
  File? _idFront;
  File? _idBack;

  bool get _allCaptured => _face != null && _idFront != null && _idBack != null;

  Future<void> _capture(String which) async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
            which == 'face' ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (shot == null) return;
      setState(() {
        final f = File(shot.path);
        if (which == 'face') _face = f;
        if (which == 'front') _idFront = f;
        if (which == 'back') _idBack = f;
      });
    } catch (e) {
      if (mounted) {
        showSnack(context, 'No se pudo abrir la cámara: $e', error: true);
      }
    }
  }

  Future<String> _toB64(File f) async {
    final bytes = await f.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _submit() async {
    if (!_allCaptured) {
      showSnack(context, 'Captura las tres fotos para continuar.', error: true);
      return;
    }

    final auth = context.read<AuthProvider>();
    final r = widget.registration;

    final faceB64 = await _toB64(_face!);
    final frontB64 = await _toB64(_idFront!);
    final backB64 = await _toB64(_idBack!);

    final ok = await auth.register(
      name: r.name,
      email: r.email,
      password: r.password,
      tenantId: r.tenantId,
      tenantName: r.tenantName,
      faceB64: faceB64,
      idFrontB64: frontB64,
      idBackB64: backB64,
    );

    if (ok && mounted) {
      // Vuelve al root → OtpScreen (la cuenta ya quedó creada y con sesión).
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (mounted && auth.error != null) {
      showSnack(context, auth.error!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación de identidad')),
      body: BrandBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            color: BankColors.skyBlue, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Por seguridad, necesitamos verificar tu identidad. '
                            'Toma una foto de tu rostro y de ambos lados de tu '
                            'documento de identidad.',
                            style: TextStyle(
                                color: BankColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _captureCard(
                    step: '1',
                    title: 'Foto de tu rostro',
                    subtitle: 'Mira de frente, con buena luz.',
                    icon: Icons.face_outlined,
                    file: _face,
                    onTap: () => _capture('face'),
                  ),
                  const SizedBox(height: 16),
                  _captureCard(
                    step: '2',
                    title: 'Documento — frente',
                    subtitle: 'Lado frontal de tu identificación.',
                    icon: Icons.badge_outlined,
                    file: _idFront,
                    onTap: () => _capture('front'),
                  ),
                  const SizedBox(height: 16),
                  _captureCard(
                    step: '3',
                    title: 'Documento — reverso',
                    subtitle: 'Lado posterior de tu identificación.',
                    icon: Icons.flip_to_back_outlined,
                    file: _idBack,
                    onTap: () => _capture('back'),
                  ),

                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'Finalizar registro',
                    icon: Icons.check_circle_outline,
                    loading: auth.busy,
                    onPressed:
                        (auth.busy || !_allCaptured) ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _allCaptured
                          ? 'Tus fotos se enviarán al banco para validación.'
                          : 'Captura las tres fotos para continuar.',
                      style: const TextStyle(
                          color: BankColors.textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _captureCard({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    final captured = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BankColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: captured ? BankColors.green : BankColors.cardBorder,
            width: captured ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Miniatura / placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: captured
                  ? Image.file(file, width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64,
                      height: 64,
                      color: BankColors.surfaceDark,
                      child: Icon(icon,
                          color: BankColors.textMuted, size: 28),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: captured
                              ? BankColors.green
                              : BankColors.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        child: captured
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text(step,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: BankColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    captured ? 'Foto capturada · toca para repetir' : subtitle,
                    style: TextStyle(
                        color: captured
                            ? BankColors.green
                            : BankColors.textMuted,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              captured ? Icons.refresh : Icons.camera_alt_outlined,
              color: captured ? BankColors.textSecondary : BankColors.skyBlue,
            ),
          ],
        ),
      ),
    );
  }
}
