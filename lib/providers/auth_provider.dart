import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/otp_service.dart';
import '../data/services/secure_store.dart';

/// Fases del proceso de autenticación con clave dinámica.
enum AuthPhase {
  loading,        // verificando sesión guardada al arrancar
  loggedOut,      // sin sesión
  awaitingOtp,    // credenciales válidas, esperando la clave dinámica
  loggedIn,       // sesión completa y verificada
}

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  AuthPhase phase = AuthPhase.loading;
  AppUser? user;
  String? tenantId;
  String? tenantName;
  String? error;
  bool busy = false;

  // Datos guardados temporalmente entre el paso 1 (credenciales) y el
  // paso 2 (OTP). Nunca se persisten.
  String? _pendingEmail;
  String? _pendingName;

  String? get pendingEmail => _pendingEmail;

  /// Al iniciar la app: si hay sesión guardada, exige igualmente el OTP
  /// si la app se cerró por completo (seguridad). Aquí, por simplicidad,
  /// restauramos la sesión directamente; cámbialo si quieres OTP siempre.
  Future<void> bootstrap() async {
    phase = AuthPhase.loading;
    notifyListeners();
    final has = await SecureStore.instance.hasSession;
    if (has) {
      tenantId = await SecureStore.instance.tenantId;
      tenantName = await SecureStore.instance.tenantName;
      final id = await SecureStore.instance.userId ?? '';
      final name = await SecureStore.instance.userName ?? '';
      final email = await SecureStore.instance.userEmail ?? '';
      user = AppUser(id: id, name: name, email: email, role: 'cliente');
      phase = AuthPhase.loggedIn;
    } else {
      phase = AuthPhase.loggedOut;
    }
    notifyListeners();
  }

  /// Paso 1: validar credenciales contra la API. Si son correctas,
  /// generamos y "enviamos" la clave dinámica y pasamos a awaitingOtp.
  ///
  /// IMPORTANTE: rechazamos a cualquier usuario que NO sea cliente.
  Future<bool> loginStep1({
    required String email,
    required String password,
    required String tenantId,
    required String tenantName,
  }) async {
    _setBusy(true);
    error = null;
    try {
      final u = await _repo.login(
        email: email,
        password: password,
        tenantId: tenantId,
        tenantName: tenantName,
      );

      // Esta app es SOLO para clientes. Si entra un admin, lo bloqueamos.
      if (!u.isClient) {
        await _repo.logout();
        error = 'Esta aplicación es exclusiva para clientes del banco.';
        _setBusy(false);
        return false;
      }

      this.tenantId = tenantId;
      this.tenantName = tenantName;
      user = u;
      _pendingEmail = u.email;
      _pendingName = u.name;

      // Generar clave dinámica (10 min) — lógica en Flutter.
      await OtpService.instance
          .generateAndSend(email: u.email, userName: u.name);

      phase = AuthPhase.awaitingOtp;
      _setBusy(false);
      return true;
    } on ApiException catch (e) {
      error = e.friendly;
      _setBusy(false);
      return false;
    } catch (e) {
      error = 'No se pudo iniciar sesión. Verifica tu conexión.';
      _setBusy(false);
      return false;
    }
  }

  /// Reenvía la clave dinámica.
  Future<void> resendOtp() async {
    if (_pendingEmail == null) return;
    await OtpService.instance.generateAndSend(
      email: _pendingEmail!,
      userName: _pendingName ?? '',
    );
    notifyListeners();
  }

  /// Paso 2: validar el OTP. Si es correcto, completa el login.
  OtpResult verifyOtp(String code) {
    if (_pendingEmail == null) return OtpResult.noCode;
    final result = OtpService.instance.validate(code, email: _pendingEmail!);
    if (result == OtpResult.valid) {
      phase = AuthPhase.loggedIn;
      _pendingEmail = null;
      _pendingName = null;
      notifyListeners();
    }
    return result;
  }

  /// Registro de cliente nuevo. Tras registrar, también exige OTP.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String tenantId,
    required String tenantName,
    String? faceB64,
    String? idFrontB64,
    String? idBackB64,
  }) async {
    _setBusy(true);
    error = null;
    try {
      final u = await _repo.register(
        name: name,
        email: email,
        password: password,
        tenantId: tenantId,
        tenantName: tenantName,
        faceB64: faceB64,
        idFrontB64: idFrontB64,
        idBackB64: idBackB64,
      );
      this.tenantId = tenantId;
      this.tenantName = tenantName;
      user = u;
      _pendingEmail = u.email;
      _pendingName = u.name;
      await OtpService.instance
          .generateAndSend(email: u.email, userName: u.name);
      phase = AuthPhase.awaitingOtp;
      _setBusy(false);
      return true;
    } on ApiException catch (e) {
      error = e.friendly;
      _setBusy(false);
      return false;
    } catch (e) {
      error = 'No se pudo registrar. Intenta de nuevo.';
      _setBusy(false);
      return false;
    }
  }

  void cancelOtp() {
    OtpService.instance.reset();
    _pendingEmail = null;
    _pendingName = null;
    phase = AuthPhase.loggedOut;
    user = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    OtpService.instance.reset();
    user = null;
    tenantId = null;
    tenantName = null;
    phase = AuthPhase.loggedOut;
    notifyListeners();
  }

  void _setBusy(bool v) {
    busy = v;
    notifyListeners();
  }
}
