/// Excepción tipada para errores de la API BankOS.
/// El backend devuelve { success:false, error:{ code, message } }.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.code = 'ERROR', this.statusCode});

  @override
  String toString() => message;

  /// Mensaje amigable para mostrar al usuario.
  String get friendly {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Correo o contraseña incorrectos.';
      case 'INVALID_CODE':
        return 'El código es incorrecto o ya expiró.';
      case 'INVALID_PASSWORD':
        return 'La contraseña actual no es válida.';
      case 'FORBIDDEN':
        return 'No tienes permiso para esta acción.';
      case 'UNAUTHORIZED':
        return 'Tu sesión expiró. Inicia sesión de nuevo.';
      default:
        return message;
    }
  }
}
