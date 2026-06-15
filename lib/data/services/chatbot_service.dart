import 'package:dio/dio.dart';
import '../../core/constants/app_config.dart';
import '../models/models.dart';

/// Chatbot del cliente. Replica el comportamiento de la app Laravel:
/// responde SOLO sobre las cuentas del propio usuario y sobre el uso de la app.
/// Si no hay clave de OpenAI configurada, usa un modo local con reglas.
class ChatbotService {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Construye el system prompt acotado a los datos del usuario.
  String _systemPrompt({
    required String userName,
    required String email,
    required String bank,
    required List<Account> accounts,
    required List<TxModel> recent,
  }) {
    final accountsCtx = accounts
        .map((a) =>
            'cuenta:${a.accountNumber} moneda:${a.currency} saldo:${a.balance} estado:${a.status}')
        .join(' | ');
    final txCtx = recent
        .take(10)
        .map((t) =>
            '${t.type} ${t.amount} ${t.currency} ${t.createdAt ?? ''}')
        .join(' | ');

    return '''
Eres el asistente bancario personal de $userName en BankOs.
Responde SOLO preguntas relacionadas con su cuenta bancaria, sus movimientos, y el uso de esta app (cómo transferir, retirar, generar/escanear QR, solicitar certificado, crear PQRS, etc.).
Si preguntan algo ajeno al banco, a sus cuentas o a la app, responde exactamente: "Solo puedo ayudarte con temas relacionados a tu cuenta bancaria y el uso de la app."
Sé conciso, amable y responde en español.

DATOS DEL USUARIO (confidenciales, solo suyos):
Nombre: $userName
Email: $email
Banco: $bank

CUENTAS:
$accountsCtx

ÚLTIMOS MOVIMIENTOS:
$txCtx
''';
  }

  /// Envía la conversación a OpenAI y devuelve la respuesta del asistente.
  Future<String> ask({
    required List<Map<String, String>> history,
    required String userName,
    required String email,
    required String bank,
    required List<Account> accounts,
    required List<TxModel> recent,
  }) async {
    if (!AppConfig.hasOpenAi) {
      return _localFallback(history.isNotEmpty ? history.last['content'] ?? '' : '',
          accounts: accounts);
    }

    try {
      final messages = [
        {
          'role': 'system',
          'content': _systemPrompt(
            userName: userName,
            email: email,
            bank: bank,
            accounts: accounts,
            recent: recent,
          ),
        },
        ...history,
      ];

      final res = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': AppConfig.openAiModel,
          'max_tokens': 350,
          'temperature': 0.4,
          'messages': messages,
        },
      );

      final content =
          res.data?['choices']?[0]?['message']?['content']?.toString();
      return content?.trim().isNotEmpty == true
          ? content!.trim()
          : 'No pude obtener una respuesta. Intenta de nuevo.';
    } catch (e) {
      return '⚠️ No pude conectar con el asistente en este momento.';
    }
  }

  /// Respuestas básicas sin IA (cuando no hay clave de OpenAI).
  String _localFallback(String question, {required List<Account> accounts}) {
    final q = question.toLowerCase();
    if (q.contains('saldo') || q.contains('cuanto tengo') || q.contains('cuánto')) {
      if (accounts.isEmpty) return 'No veo cuentas activas en tu perfil.';
      final lines = accounts
          .map((a) =>
              '• ${a.accountNumber} (${a.currency}): ${a.balance.toStringAsFixed(2)}')
          .join('\n');
      return 'Estos son tus saldos:\n$lines';
    }
    if (q.contains('transfer')) {
      return 'Para transferir: ve al inicio, toca una cuenta, elige "Transferir", '
          'busca el destino por número o escanea su QR, ingresa el monto y confirma.';
    }
    if (q.contains('retir')) {
      return 'Para retirar: elige "Retirar" en tu cuenta, ingresa el monto y te '
          'llegará un código de 6 dígitos al correo (válido 10 min) para confirmar.';
    }
    if (q.contains('qr')) {
      return 'Puedes generar un QR de cobro desde tu cuenta, o escanear el de otra '
          'persona para autollenar los datos de la transferencia.';
    }
    if (q.contains('certificad')) {
      return 'Ve a "Certificados", elige la cuenta y confirma tus datos; '
          'el certificado se genera y se envía a tu correo.';
    }
    if (q.contains('pqrs') || q.contains('queja') || q.contains('reclamo')) {
      return 'En "PQRS" puedes crear una petición, queja, reclamo o sugerencia. '
          'El banco te responderá por correo.';
    }
    if (q.contains('hola') || q.contains('buenas') || q.contains('ayuda')) {
      return '¡Hola! Puedo ayudarte con tus saldos, movimientos, transferencias, '
          'retiros, QR, certificados y PQRS. ¿Qué necesitas?';
    }
    return 'Solo puedo ayudarte con temas relacionados a tu cuenta bancaria y el uso de la app.';
  }
}
