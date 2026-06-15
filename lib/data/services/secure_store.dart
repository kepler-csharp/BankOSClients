import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda de forma segura el token JWT, el tenant seleccionado y, para el
/// flujo de "solicitar certificado", credenciales temporales en memoria.
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'jwt_token';
  static const _kTenantId = 'tenant_id';
  static const _kTenantName = 'tenant_name';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserId = 'user_id';

  Future<void> saveSession({
    required String token,
    required String tenantId,
    required String tenantName,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kTenantId, value: tenantId),
      _storage.write(key: _kTenantName, value: tenantName),
      _storage.write(key: _kUserId, value: userId),
      _storage.write(key: _kUserName, value: userName),
      _storage.write(key: _kUserEmail, value: userEmail),
    ]);
  }

  Future<String?> get token => _storage.read(key: _kToken);
  Future<String?> get tenantId => _storage.read(key: _kTenantId);
  Future<String?> get tenantName => _storage.read(key: _kTenantName);
  Future<String?> get userId => _storage.read(key: _kUserId);
  Future<String?> get userName => _storage.read(key: _kUserName);
  Future<String?> get userEmail => _storage.read(key: _kUserEmail);

  Future<bool> get hasSession async => (await token)?.isNotEmpty ?? false;

  Future<void> clear() => _storage.deleteAll();
}
