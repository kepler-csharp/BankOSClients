import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_config.dart';
import '../../data/services/secure_store.dart';
import 'api_exception.dart';

/// Cliente HTTP central para toda la API BankOS.
///
/// Inyecta automáticamente en cada petición:
///  - X-Tenant-ID         (banco seleccionado)
///  - Authorization Bearer (JWT, si hay sesión)
///  - X-Correlation-ID     (trazabilidad, requerido por el middleware)
///  - Idempotency-Key      (en POST de transacciones)
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
        // No lanzamos por status >=400; lo gestionamos nosotros.
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Tenant scope: obligatorio en casi todos los endpoints.
          final tenant = await SecureStore.instance.tenantId;
          if (tenant != null && tenant.isNotEmpty) {
            options.headers['X-Tenant-ID'] = tenant;
          }
          // El header de tenant puede venir sobreescrito por la llamada
          // (p.ej. lista pública de bancos no lo necesita).
          if (options.extra['noTenant'] == true) {
            options.headers.remove('X-Tenant-ID');
          }

          // JWT
          if (options.extra['noAuth'] != true) {
            final token = await SecureStore.instance.token;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // Trazabilidad
          options.headers['X-Correlation-ID'] = const Uuid().v4();

          // Idempotencia para transacciones
          if (options.extra['idempotent'] == true) {
            options.headers['Idempotency-Key'] = const Uuid().v4();
          }

          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  Dio get dio => _dio;

  // ──────────────────────────────────────────────────────────────────
  // Helpers de alto nivel que normalizan la envoltura { success, data }.
  // ──────────────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool noTenant = false,
    bool noAuth = false,
  }) async {
    final res = await _dio.get(
      path,
      queryParameters: query,
      options: Options(extra: {'noTenant': noTenant, 'noAuth': noAuth}),
    );
    return _unwrap(res);
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    bool idempotent = false,
    bool noTenant = false,
    bool noAuth = false,
  }) async {
    final res = await _dio.post(
      path,
      data: data,
      options: Options(extra: {
        'idempotent': idempotent,
        'noTenant': noTenant,
        'noAuth': noAuth,
      }),
    );
    return _unwrap(res);
  }

  Future<dynamic> patch(String path, {Object? data}) async {
    final res = await _dio.patch(path, data: data);
    return _unwrap(res);
  }

  Future<dynamic> put(String path, {Object? data}) async {
    final res = await _dio.put(path, data: data);
    return _unwrap(res);
  }

  /// Desempaqueta la respuesta y lanza ApiException en caso de error.
  dynamic _unwrap(Response res) {
    final status = res.statusCode ?? 0;
    final body = res.data;

    if (status >= 200 && status < 300) {
      if (body is Map && body.containsKey('data')) return body['data'];
      return body;
    }

    // Error estructurado del backend
    if (body is Map) {
      final err = body['error'];
      if (err is Map) {
        throw ApiException(
          (err['message'] ?? 'Error desconocido').toString(),
          code: (err['code'] ?? 'ERROR').toString(),
          statusCode: status,
        );
      }
      // Errores de validación de Laravel: { message, errors:{} }
      if (body['message'] != null) {
        final errors = body['errors'];
        String msg = body['message'].toString();
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) msg = first.first.toString();
        }
        throw ApiException(msg, code: 'VALIDATION', statusCode: status);
      }
    }
    throw ApiException('Error del servidor ($status).',
        code: 'ERROR', statusCode: status);
  }
}
