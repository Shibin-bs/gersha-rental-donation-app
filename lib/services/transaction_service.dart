import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';

/// Service to manage transactions in Firestore 'transactions' collection
/// Handles CRUD operations for transaction documents
class TransactionService {
  static const String _collectionName = 'transactions';

  /// Get Firestore reference to transactions collection
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseService.firestore.collection(_collectionName);

  /// Create a new transaction (when item is received/rented)
  /// Returns the transaction ID (document ID in Firestore)
  static Future<String> createTransaction(TransactionModel transaction) async {
    try {
      // Use transactionId as document ID, or generate one if not provided
      final docId = transaction.transactionId.isNotEmpty
          ? transaction.transactionId
          : _collection.doc().id;

      // Create transaction data with the correct transactionId
      final transactionData = transaction.toJson();
      transactionData['transactionId'] = docId; // Ensure transactionId matches doc ID

      await _collection.doc(docId).set(transactionData);
      return docId;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Get transaction by ID
  static Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final doc = await _collection.doc(transactionId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          try {
            return TransactionModel.fromJson(data, doc.id);
          } catch (e) {
            // Invalid document data
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      // Return null on error instead of throwing
      return null;
    }
  }

  /// Update transaction status
  static Future<void> updateTransactionStatus(
      String transactionId, TransactionStatus status) async {
    try {
      await _collection.doc(transactionId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }

  /// Update transaction end date
  static Future<void> updateTransactionEndDate(
      String transactionId, DateTime endDate) async {
    try {
      await _collection.doc(transactionId).update({
        'endDate': endDate.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update transaction end date: $e');
    }
  }

  /// Get all transactions (for admin panel)
  static Stream<List<TransactionModel>> getAllTransactions() {
    try {
      return _collection
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return TransactionModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<TransactionModel>()
            .toList();
      }).handleError((error) {
        return <TransactionModel>[];
      });
    } catch (e) {
      return Stream.value(<TransactionModel>[]);
    }
  }

  /// Get transactions by owner ID (items given/rented out)
  /// Note: Requires composite index on (ownerId, startDate)
  static Stream<List<TransactionModel>> getTransactionsByOwner(String ownerId) {
    try {
      return _collection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return TransactionModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<TransactionModel>()
            .toList();
      }).handleError((error) {
        // Return empty list if index is missing
        return <TransactionModel>[];
      });
    } catch (e) {
      return Stream.value(<TransactionModel>[]);
    }
  }

  /// Get transactions by receiver ID (items received/rented)
  /// Note: Requires composite index on (receiverId, startDate)
  static Stream<List<TransactionModel>> getTransactionsByReceiver(String receiverId) {
    try {
      return _collection
          .where('receiverId', isEqualTo: receiverId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return TransactionModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<TransactionModel>()
            .toList();
      }).handleError((error) {
        // Return empty list if index is missing
        return <TransactionModel>[];
      });
    } catch (e) {
      return Stream.value(<TransactionModel>[]);
    }
  }

  /// Get transactions by listing ID
  /// Note: Requires composite index on (listingId, startDate)
  static Stream<List<TransactionModel>> getTransactionsByListing(String listingId) {
    try {
      return _collection
          .where('listingId', isEqualTo: listingId)
          .orderBy('startDate', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return TransactionModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<TransactionModel>()
            .toList();
      }).handleError((error) {
        return <TransactionModel>[];
      });
    } catch (e) {
      return Stream.value(<TransactionModel>[]);
    }
  }

  /// Get active transactions for a user (as owner or receiver)
  /// Note: Requires composite indexes for multiple where clauses
  static Future<List<TransactionModel>> getActiveTransactionsForUser(String userId) async {
    try {
      final ownerSnapshot = await _collection
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: TransactionStatus.active.toString().split('.').last)
          .get();

      final receiverSnapshot = await _collection
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: TransactionStatus.active.toString().split('.').last)
          .get();

      final transactions = <TransactionModel>[];
      
      // Add owner transactions
      transactions.addAll(
        ownerSnapshot.docs
            .map((doc) {
              try {
                return TransactionModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<TransactionModel>(),
      );
      
      // Add receiver transactions
      transactions.addAll(
        receiverSnapshot.docs
            .map((doc) {
              try {
                return TransactionModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<TransactionModel>(),
      );

      return transactions;
    } catch (e) {
      // Return empty list on error (e.g., missing index)
      return [];
    }
  }
}
