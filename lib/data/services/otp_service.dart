import 'dart:math';
import '../../core/constants/app_config.dart';
import 'mail_service.dart';

/// Servicio de "clave dinámica de acceso" (segundo factor en el login).
///
/// Según lo solicitado, la lógica vive 100% en Flutter:
///   1. El usuario ingresa email + contraseña correctos.
///   2. Se genera un código de 6 dígitos.
///   3. Se "envía" al correo (vía MailService, simulado localmente).
///   4. El código vence a los 10 minutos.
///   5. Solo tras validar el código se entra al dashboard.
///
/// Es un OTP en memoria: no se persiste en disco para que no quede expuesto.
class OtpService {
  OtpService._();
  static final OtpService instance = OtpService._();

  String? _code;
  DateTime? _expiresAt;
  String? _forEmail;
  int _attempts = 0;

  static const _maxAttempts = 5;

  bool get hasActiveCode =>
      _code != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  DateTime? get expiresAt => _expiresAt;

  /// Segundos restantes antes de expirar (0 si ya venció).
  int get secondsLeft {
    if (_expiresAt == null) return 0;
    final s = _expiresAt!.difference(DateTime.now()).inSeconds;
    return s > 0 ? s : 0;
  }

  /// Genera y "envía" un nuevo código para [email].
  /// Devuelve el código solo para fines de demostración (ver MailService).
  Future<String> generateAndSend({
    required String email,
    required String userName,
  }) async {
    final rng = Random.secure();
    final max = pow(10, AppConfig.otpLength).toInt();
    final n = rng.nextInt(max);
    _code = n.toString().padLeft(AppConfig.otpLength, '0');
    _expiresAt =
        DateTime.now().add(Duration(minutes: AppConfig.otpValidityMinutes));
    _forEmail = email;
    _attempts = 0;

    // "Envío" por correo (simulado): registra y muestra el código.
    await MailService.instance.sendOtp(
      to: email,
      userName: userName,
      code: _code!,
      minutes: AppConfig.otpValidityMinutes,
    );

    return _code!;
  }

  /// Valida el código ingresado. Maneja expiración e intentos.
  OtpResult validate(String input, {required String email}) {
    if (_code == null || _expiresAt == null) {
      return OtpResult.noCode;
    }
    if (_forEmail != email) {
      return OtpResult.noCode;
    }
    if (DateTime.now().isAfter(_expiresAt!)) {
      _clear();
      return OtpResult.expired;
    }
    if (_attempts >= _maxAttempts) {
      _clear();
      return OtpResult.tooManyAttempts;
    }
    _attempts++;
    if (input.trim() == _code) {
      _clear();
      return OtpResult.valid;
    }
    return OtpResult.invalid;
  }

  void _clear() {
    _code = null;
    _expiresAt = null;
    _forEmail = null;
    _attempts = 0;
  }

  void reset() => _clear();
}

enum OtpResult { valid, invalid, expired, noCode, tooManyAttempts }

extension OtpResultMsg on OtpResult {
  String get message {
    switch (this) {
      case OtpResult.valid:
        return 'Código verificado.';
      case OtpResult.invalid:
        return 'Código incorrecto. Intenta de nuevo.';
      case OtpResult.expired:
        return 'El código expiró. Solicita uno nuevo.';
      case OtpResult.noCode:
        return 'No hay un código activo. Solicita uno nuevo.';
      case OtpResult.tooManyAttempts:
        return 'Demasiados intentos. Solicita un código nuevo.';
    }
  }
}
