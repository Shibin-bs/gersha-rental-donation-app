/// Transaction model for tracking donations and rentals
/// Fields: transactionId, listingId, ownerId, receiverId, type, amount, duration, startDate, endDate, status
class TransactionModel {
  final String transactionId; // Unique transaction ID
  final String listingId; // ID of the listing/item
  final String ownerId; // Firebase Auth UID of the item owner
  final String receiverId; // Firebase Auth UID of the receiver/renter
  final TransactionType type; // 'donation' or 'rental'
  final double amount; // In INR, 0 for donations
  final int duration; // Duration in days
  final DateTime startDate; // When transaction started
  final DateTime? endDate; // When transaction ended (return date for rentals)
  final TransactionStatus status; // 'active', 'completed', 'cancelled'

  TransactionModel({
    required this.transactionId,
    required this.listingId,
    required this.ownerId,
    required this.receiverId,
    required this.type,
    this.amount = 0.0,
    required this.duration,
    required this.startDate,
    this.endDate,
    this.status = TransactionStatus.active,
  });

  /// Convert TransactionModel to Map for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'listingId': listingId,
      'ownerId': ownerId,
      'receiverId': receiverId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'duration': duration,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  /// Create TransactionModel from Firestore document
  factory TransactionModel.fromJson(Map<String, dynamic> json, String documentId) {
    return TransactionModel(
      transactionId: json['transactionId'] as String? ?? documentId,
      listingId: json['listingId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] as String? ?? 'donation'),
        orElse: () => TransactionType.donation,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as int? ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String? ?? 'active'),
        orElse: () => TransactionStatus.active,
      ),
    );
  }

  /// Create a copy with updated fields
  TransactionModel copyWith({
    String? transactionId,
    String? listingId,
    String? ownerId,
    String? receiverId,
    TransactionType? type,
    double? amount,
    int? duration,
    DateTime? startDate,
    DateTime? endDate,
    TransactionStatus? status,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      listingId: listingId ?? this.listingId,
      ownerId: ownerId ?? this.ownerId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}

/// Transaction type enum
enum TransactionType {
  donation, // Free donation
  rental, // Rental transaction
}

/// Transaction status enum
enum TransactionStatus {
  active, // Transaction is active
  completed, // Transaction completed
  cancelled, // Transaction cancelled
}
