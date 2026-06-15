// Modelos que mapean exactamente las respuestas de la API BankOS.

/// Banco (tenant) del selector público.
class Bank {
  final String id;
  final String name;
  Bank({required this.id, required this.name});
  factory Bank.fromJson(Map<String, dynamic> j) =>
      Bank(id: j['id'].toString(), name: (j['name'] ?? j['id']).toString());
}

/// Usuario autenticado (rol cliente).
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'].toString(),
        name: (j['name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        role: (j['role'] ?? 'cliente').toString(),
      );
  bool get isClient => role == 'cliente';
}

/// Cuenta bancaria.
class Account {
  final String id;
  final String accountNumber;
  final double balance;
  final String currency;
  final String status;

  Account({
    required this.id,
    required this.accountNumber,
    required this.balance,
    required this.currency,
    required this.status,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'].toString(),
        accountNumber: (j['account_number'] ?? '').toString(),
        balance: (j['balance'] is num)
            ? (j['balance'] as num).toDouble()
            : double.tryParse('${j['balance']}') ?? 0,
        currency: (j['currency'] ?? 'COP').toString(),
        status: (j['status'] ?? 'active').toString(),
      );

  bool get isActive => status == 'active';
}

/// Transacción (depósito, retiro o transferencia).
class TxModel {
  final String id;
  final String type;
  final String status;
  final String accountId;
  final String? destinationAccountId;
  final double amount;
  final double? convertedAmount;
  final String currency;
  final String? destinationCurrency;
  final double fee;
  final double balanceAfter;
  final String? description;
  final DateTime? createdAt;

  TxModel({
    required this.id,
    required this.type,
    required this.status,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.fee,
    required this.balanceAfter,
    this.destinationAccountId,
    this.convertedAmount,
    this.destinationCurrency,
    this.description,
    this.createdAt,
  });

  factory TxModel.fromJson(Map<String, dynamic> j) => TxModel(
        id: j['id'].toString(),
        type: (j['type'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        accountId: (j['account_id'] ?? '').toString(),
        destinationAccountId: j['destination_account_id']?.toString(),
        amount: _d(j['amount']),
        convertedAmount:
            j['converted_amount'] == null ? null : _d(j['converted_amount']),
        currency: (j['currency'] ?? 'COP').toString(),
        destinationCurrency: j['destination_currency']?.toString(),
        fee: _d(j['fee']),
        balanceAfter: _d(j['balance_after']),
        description: j['description']?.toString(),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  static double _d(dynamic v) => v is num
      ? v.toDouble()
      : double.tryParse('${v ?? 0}') ?? 0;
}

/// PQRS (Petición, Queja, Reclamo, Sugerencia).
class PqrsModel {
  final String id;
  final String type;
  final String subject;
  final String message;
  final String status;
  final String? adminResponse;
  final DateTime? createdAt;

  PqrsModel({
    required this.id,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    this.adminResponse,
    this.createdAt,
  });

  factory PqrsModel.fromJson(Map<String, dynamic> j) => PqrsModel(
        id: j['id'].toString(),
        type: (j['type'] ?? 'pregunta').toString(),
        subject: (j['subject'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        status: (j['status'] ?? 'pendiente').toString(),
        adminResponse: j['admin_response']?.toString(),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );
}

/// Payload del QR que devuelve el endpoint /accounts/{id}/qr.
class QrPayload {
  final String accountId;
  final String accountNumber;
  final String tenantId;
  final String currency;
  final String ownerName;

  QrPayload({
    required this.accountId,
    required this.accountNumber,
    required this.tenantId,
    required this.currency,
    required this.ownerName,
  });

  factory QrPayload.fromJson(Map<String, dynamic> j) => QrPayload(
        accountId: (j['account_id'] ?? '').toString(),
        accountNumber: (j['account_number'] ?? '').toString(),
        tenantId: (j['tenant_id'] ?? '').toString(),
        currency: (j['currency'] ?? '').toString(),
        ownerName: (j['owner_name'] ?? '').toString(),
      );
}
