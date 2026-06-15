import '../../core/network/api_client.dart';
import '../models/models.dart';

/// Cuentas del cliente.
class AccountRepository {
  final _api = ApiClient.instance;

  /// Lista las cuentas del cliente (la API filtra a "solo las propias").
  Future<List<Account>> myAccounts({String? status}) async {
    final data = await _api.get('/accounts', query: {
      'per_page': 100,
      if (status != null) 'status': status,
    });
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(Account.fromJson).toList();
  }

  Future<Account> show(String id) async {
    final data = await _api.get('/accounts/$id');
    return Account.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Busca cuentas activas por número (para destino de transferencia).
  /// La API de cliente, al pasar `search`, devuelve cuentas activas que
  /// coinciden por número de cuenta.
  Future<List<Account>> searchByNumber(String number) async {
    final data = await _api.get('/accounts', query: {
      'search': number,
      'per_page': 10,
    });
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(Account.fromJson).toList();
  }
}

/// Transacciones y retiro con OTP (2 pasos del backend).
class TransactionRepository {
  final _api = ApiClient.instance;

  Future<List<TxModel>> list({
    String? type,
    String? accountId,
    int perPage = 50,
  }) async {
    final data = await _api.get('/transactions', query: {
      'per_page': perPage,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
    });
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(TxModel.fromJson).toList();
  }

  Future<TxModel> show(String id) async {
    final data = await _api.get('/transactions/$id');
    return TxModel.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<TxModel> deposit({
    required String accountId,
    required double amount,
    String? description,
  }) async {
    final data = await _api.post(
      '/transactions/deposit',
      idempotent: true,
      data: {
        'account_id': accountId,
        'amount': amount,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return TxModel.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Transferencia. Acepta destino por UUID (mismo tenant).
  Future<TxModel> transfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amount,
    String? description,
  }) async {
    final data = await _api.post(
      '/transactions/transfer',
      idempotent: true,
      data: {
        'source_account_id': sourceAccountId,
        'destination_account_id': destinationAccountId,
        'amount': amount,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return TxModel.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Retiro paso 1: el backend envía un OTP de 6 dígitos al correo (10 min).
  Future<void> requestWithdrawalCode({
    required String accountId,
    required double amount,
  }) async {
    await _api.post('/withdrawal/request-code', data: {
      'account_id': accountId,
      'amount': amount,
    });
  }

  /// Retiro paso 2: confirma el OTP y ejecuta el retiro.
  Future<TxModel> confirmWithdrawal({
    required String accountId,
    required double amount,
    required String code,
    String? description,
  }) async {
    final data = await _api.post(
      '/withdrawal/confirm',
      idempotent: true,
      data: {
        'account_id': accountId,
        'amount': amount,
        'code': code,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return TxModel.fromJson((data as Map).cast<String, dynamic>());
  }
}

/// QR de recepción. El backend solo entrega el payload; el QR se renderiza
/// en el cliente y NO se almacena en ningún lado.
class QrRepository {
  final _api = ApiClient.instance;

  Future<QrPayload> generate(String accountId) async {
    final data = await _api.get('/accounts/$accountId/qr');
    final map = (data as Map).cast<String, dynamic>();
    // El endpoint entrega { payload, payload_data }.
    final payloadData =
        (map['payload_data'] as Map).cast<String, dynamic>();
    return QrPayload.fromJson(payloadData);
  }
}

/// PQRS del cliente.
class PqrsRepository {
  final _api = ApiClient.instance;

  Future<List<PqrsModel>> myPqrs() async {
    final data = await _api.get('/pqrs', query: {'per_page': 50});
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(PqrsModel.fromJson).toList();
  }

  Future<PqrsModel> show(String id) async {
    final data = await _api.get('/pqrs/$id');
    return PqrsModel.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Crea una PQRS. El backend notifica por correo al cliente y al admin.
  Future<PqrsModel> create({
    required String type,
    required String subject,
    required String message,
  }) async {
    final data = await _api.post('/pqrs', data: {
      'type': type,
      'subject': subject,
      'message': message,
    });
    return PqrsModel.fromJson((data as Map).cast<String, dynamic>());
  }
}

/// Configuración del tenant (límites, comisiones, monedas).
class ConfigRepository {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> config() async {
    final data = await _api.get('/config');
    return (data as Map).cast<String, dynamic>();
  }
}
