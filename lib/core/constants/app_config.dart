/// Configuración central de la app.
///
/// Los valores sensibles (URL del API, clave de OpenAI) se inyectan en
/// tiempo de compilación con --dart-define para NO quemarlos en el binario:
///
///   flutter run \
///     --dart-define=API_BASE_URL=https://bank-os.duckdns.org/api/v1 \
///     --dart-define=OPENAI_API_KEY=sk-xxxx
///
/// Si no se pasan, se usan los valores por defecto de desarrollo.
class AppConfig {
  AppConfig._();

  /// URL base de la API BankOS (incluye /api/v1).
  /// En el emulador Android, localhost del PC es 10.0.2.2.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://87.99.154.103:3000/api/v1',
  );

  /// Clave de OpenAI para el chatbot. Si va vacía, el chatbot usa
  /// un modo local de respuestas básicas (sin IA).
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// Modelo de chat usado (igual que la app Laravel original).
  static const String openAiModel = 'gpt-4o-mini';

  /// Minutos de validez de la clave dinámica (OTP) de acceso.
  /// La lógica del OTP vive en el cliente (Flutter), según lo solicitado.
  static const int otpValidityMinutes = 10;

  /// Cuántos dígitos tiene el OTP de acceso.
  static const int otpLength = 6;

  static bool get hasOpenAi => openAiApiKey.trim().isNotEmpty;
}
