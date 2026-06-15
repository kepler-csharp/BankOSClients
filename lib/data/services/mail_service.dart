import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Servicio de correo SIMULADO localmente.
///
/// El backend BankOS ya envía correos reales para: registro, OTP de retiro,
/// y PQRS. Pero algunos flujos pedidos NO tienen endpoint que mande correo
/// (notificación al editar la cuenta, certificado, y el OTP de acceso que
/// vive en Flutter). Para esos casos, esta clase "simula" el envío:
///
///   - Lo registra en consola (visible con `flutter logs`).
///   - Guarda un historial en memoria que la app muestra en una bandeja
///     de "Correos enviados (simulación)" dentro de la sección legal/ayuda,
///     y en diálogos puntuales (p.ej. el código OTP de acceso).
///
/// En producción real, reemplaza el cuerpo de estos métodos por una llamada
/// al endpoint correspondiente del backend (ver README → "Endpoints sugeridos").
class MailService extends ChangeNotifier {
  MailService._();
  static final MailService instance = MailService._();

  final List<SentMail> _outbox = [];
  List<SentMail> get outbox => List.unmodifiable(_outbox.reversed);

  String? _lastOtp; // solo para mostrar en la demo
  String? get lastOtp => _lastOtp;

  void _record(SentMail mail) {
    _outbox.add(mail);
    dev.log(
      '📧 [SIMULADO] Para: ${mail.to}\n   Asunto: ${mail.subject}\n   ${mail.body}',
      name: 'MailService',
    );
    notifyListeners();
  }

  Future<void> sendOtp({
    required String to,
    required String userName,
    required String code,
    required int minutes,
  }) async {
    _lastOtp = code;
    _record(SentMail(
      to: to,
      subject: 'Tu clave dinámica de acceso a BankOs',
      body:
          'Hola $userName, tu clave de acceso es $code. Vence en $minutes minutos. '
          'Si no intentaste ingresar, ignora este correo.',
      kind: MailKind.otp,
    ));
  }

  Future<void> sendAccountUpdated({
    required String to,
    required String userName,
    required String detail,
  }) async {
    _record(SentMail(
      to: to,
      subject: 'Actualización en tu cuenta BankOs',
      body: 'Hola $userName, registramos un cambio en tu perfil: $detail. '
          'Si no fuiste tú, contáctanos de inmediato.',
      kind: MailKind.accountUpdate,
    ));
  }

  Future<void> sendCertificate({
    required String to,
    required String userName,
    required String accountNumber,
    required String filePath,
  }) async {
    _record(SentMail(
      to: to,
      subject: 'Tu certificado bancario — cuenta $accountNumber',
      body: 'Hola $userName, adjuntamos el certificado de tu cuenta '
          '$accountNumber. Archivo generado: $filePath',
      kind: MailKind.certificate,
    ));
  }

  void clear() {
    _outbox.clear();
    notifyListeners();
  }
}

enum MailKind { otp, accountUpdate, certificate, generic }

class SentMail {
  final String to;
  final String subject;
  final String body;
  final MailKind kind;
  final DateTime at;
  SentMail({
    required this.to,
    required this.subject,
    required this.body,
    this.kind = MailKind.generic,
  }) : at = DateTime.now();
}
