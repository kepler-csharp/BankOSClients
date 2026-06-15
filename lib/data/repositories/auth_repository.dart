import '../../core/network/api_client.dart';
import '../models/models.dart';
import '../services/secure_store.dart';

/// Repositorio de autenticación. Envuelve los endpoints /auth y /banks.
///
/// Nota: la API entrega el JWT directamente en el login. La "clave dinámica"
/// (OTP de acceso de 10 min) se implementa como una segunda capa en Flutter
/// — ver OtpService — y NO depende del backend.
class AuthRepository {
  final _api = ApiClient.instance;

  /// Lista pública de bancos activos para el selector (id + name).
  Future<List<Bank>> fetchBanks() async {
    final data = await _api.get('/banks', noTenant: true, noAuth: true);
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(Bank.fromJson).toList();
  }

  /// Login. Devuelve el usuario; guarda el JWT y la sesión en almacenamiento
  /// seguro. Requiere que el tenant ya esté guardado en SecureStore.
  Future<AppUser> login({
    required String email,
    required String password,
    required String tenantId,
    required String tenantName,
  }) async {
    // Aseguramos el tenant antes de la llamada (el interceptor lo lee).
    await SecureStore.instance.saveSession(
      token: '',
      tenantId: tenantId,
      tenantName: tenantName,
      userId: '',
      userName: '',
      userEmail: '',
    );

    final data = await _api.post(
      '/auth/login',
      noAuth: true,
      data: {'email': email, 'password': password},
    );

    final user = AppUser.fromJson(
        (data['user'] as Map).cast<String, dynamic>());

    await SecureStore.instance.saveSession(
      token: data['token'].toString(),
      tenantId: tenantId,
      tenantName: tenantName,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
    );
    return user;
  }

  /// Registro de cliente nuevo (self-register).
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String tenantId,
    required String tenantName,
  }) async {
    await SecureStore.instance.saveSession(
      token: '',
      tenantId: tenantId,
      tenantName: tenantName,
      userId: '',
      userName: '',
      userEmail: '',
    );

    final data = await _api.post(
      '/auth/register',
      noAuth: true,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );

    final user = AppUser.fromJson(
        (data['user'] as Map).cast<String, dynamic>());
    await SecureStore.instance.saveSession(
      token: data['token'].toString(),
      tenantId: tenantId,
      tenantName: tenantName,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
    );
    return user;
  }

  Future<AppUser> me() async {
    final data = await _api.get('/auth/me');
    return AppUser.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    await _api.dio.patch('/auth/me/password', data: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // aunque falle en el server, limpiamos local
    } finally {
      await SecureStore.instance.clear();
    }
  }
}
