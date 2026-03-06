import 'package:equatable/equatable.dart';

/// Payment status matching backend
enum PaymentStatus { pending, success, failed }

/// eSewa payment initiation response
class PaymentInitiation extends Equatable {
  final String paymentUrl;
  final Map<String, dynamic> params;
  final String paymentId;

  const PaymentInitiation({
    required this.paymentUrl,
    required this.params,
    required this.paymentId,
  });

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      paymentUrl: json['paymentUrl'] as String? ?? '',
      params: json['params'] as Map<String, dynamic>? ?? {},
      paymentId: json['paymentId']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [paymentUrl, paymentId];
}

/// Tournament payment entity
class TournamentPaymentEntity extends Equatable {
  final String id;
  final PaymentTournamentInfo? tournamentId;
  final PaymentPayerInfo? payerId;
  final double amount;
  final String? transactionId;
  final String? refId;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const TournamentPaymentEntity({
    required this.id,
    this.tournamentId,
    this.payerId,
    required this.amount,
    this.transactionId,
    this.refId,
    required this.status,
    this.paidAt,
    this.createdAt,
  });

  factory TournamentPaymentEntity.fromJson(Map<String, dynamic> json) {
    return TournamentPaymentEntity(
      id: json['_id']?.toString() ?? '',
      tournamentId: json['tournamentId'] is Map<String, dynamic>
          ? PaymentTournamentInfo.fromJson(json['tournamentId'])
          : null,
      payerId: json['payerId'] is Map<String, dynamic>
          ? PaymentPayerInfo.fromJson(json['payerId'])
          : null,
      amount: (json['amount'] ?? 0).toDouble(),
      transactionId: json['transactionId'] as String?,
      refId: json['refId'] as String?,
      status: _parseStatus(json['status'] as String?),
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'amount': amount,
        'transactionId': transactionId,
        'refId': refId,
        'status': status.name,
        'paidAt': paidAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  static PaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  List<Object?> get props => [id, amount, status, transactionId];
}

/// Nested tournament info in payment
class PaymentTournamentInfo extends Equatable {
  final String id;
  final String name;
  final double entryFee;

  const PaymentTournamentInfo({
    required this.id,
    required this.name,
    required this.entryFee,
  });

  factory PaymentTournamentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentTournamentInfo(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      entryFee: (json['entryFee'] ?? json['entryAmount'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, entryFee];
}

/// Nested payer info in payment
class PaymentPayerInfo extends Equatable {
  final String id;
  final String fullName;
  final String? email;

  const PaymentPayerInfo({
    required this.id,
    required this.fullName,
    this.email,
  });

  factory PaymentPayerInfo.fromJson(Map<String, dynamic> json) {
    return PaymentPayerInfo(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email];
}

/// Chat access check response
class ChatAccessResult extends Equatable {
  final bool canAccess;
  final String? reason;

  const ChatAccessResult({required this.canAccess, this.reason});

  factory ChatAccessResult.fromJson(Map<String, dynamic> json) {
    final allowed = json['allowed'];
    final canAccess = json['canAccess'];
    return ChatAccessResult(
      canAccess: (canAccess is bool)
          ? canAccess
          : (allowed is bool)
              ? allowed
              : false,
      reason: json['reason'] as String? ?? json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [canAccess, reason];
}
