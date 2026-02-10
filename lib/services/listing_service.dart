import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'firebase_service.dart';

/// Service to manage listings in Firestore 'listings' collection
/// Handles CRUD operations for listing documents
class ListingService {
  static const String _collectionName = 'listings';

  /// Get Firestore reference to listings collection
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseService.firestore.collection(_collectionName);

  /// Create a new listing
  /// Returns the item ID (document ID in Firestore)
  static Future<String> createListing(ListingModel listing) async {
    try {
      // Use itemId as document ID, or generate one if not provided
      final docId = listing.itemId.isNotEmpty ? listing.itemId : _collection.doc().id;
      
      // Create listing data with the correct itemId
      final listingData = listing.toJson();
      listingData['itemId'] = docId; // Ensure itemId matches doc ID
      
      await _collection.doc(docId).set(listingData);
      return docId;
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  /// Get listing by ID
  static Future<ListingModel?> getListing(String itemId) async {
    try {
      final doc = await _collection.doc(itemId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          try {
            return ListingModel.fromJson(data, doc.id);
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

  /// Update listing status (for admin approval/rejection)
  static Future<void> updateListingStatus(String itemId, ListingStatus status) async {
    try {
      await _collection.doc(itemId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update listing status: $e');
    }
  }

  /// Update listing (general update)
  static Future<void> updateListing(String itemId, Map<String, dynamic> updates) async {
    try {
      await _collection.doc(itemId).update(updates);
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  /// Delete listing (admin only)
  static Future<void> deleteListing(String itemId) async {
    try {
      await _collection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  /// Get all listings (for admin panel)
  static Stream<List<ListingModel>> getAllListings() {
    try {
      return _collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return ListingModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                // Skip invalid documents
                return null;
              }
            })
            .where((listing) => listing != null)
            .cast<ListingModel>()
            .toList();
      }).handleError((error) {
        return <ListingModel>[];
      });
    } catch (e) {
      return Stream.value(<ListingModel>[]);
    }
  }

  /// Get approved listings (for browsing)
  /// Filters by status = 'approved' and optionally by type and category
  /// Note: Firestore requires composite indexes for multiple where clauses
  static Stream<List<ListingModel>> getApprovedListings({
    ListingType? type,
    ListingCategory? category,
  }) {
    try {
      Query<Map<String, dynamic>> query = _collection
          .where('status', isEqualTo: ListingStatus.approved.toString().split('.').last);

      // Apply filters
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      // Add orderBy last (requires composite index if multiple where clauses)
      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return ListingModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                // Skip invalid documents
                return null;
              }
            })
            .where((listing) => listing != null)
            .cast<ListingModel>()
            .toList();
      }).handleError((error) {
        // Return empty list on error (e.g., missing index)
        return <ListingModel>[];
      });
    } catch (e) {
      // Return empty stream on error
      return Stream.value(<ListingModel>[]);
    }
  }

  /// Get listings by owner ID
  /// Note: Requires composite index on (ownerId, createdAt)
  static Stream<List<ListingModel>> getListingsByOwner(String ownerId) {
    try {
      return _collection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return ListingModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((listing) => listing != null)
            .cast<ListingModel>()
            .toList();
      }).handleError((error) {
        // Return empty list if index is missing
        return <ListingModel>[];
      });
    } catch (e) {
      return Stream.value(<ListingModel>[]);
    }
  }

  /// Search listings by title (case-insensitive)
  /// Note: Firestore doesn't support case-insensitive search natively
  /// This is a basic implementation - for production, consider using Algolia or similar
  static Future<List<ListingModel>> searchListings(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) {
        // Return empty list for empty search
        return [];
      }

      // Get all approved listings and filter in memory
      // For better performance, consider using a search service
      final snapshot = await _collection
          .where('status', isEqualTo: ListingStatus.approved.toString().split('.').last)
          .get();

      final queryLower = searchQuery.toLowerCase();
      return snapshot.docs
          .map((doc) {
            try {
              return ListingModel.fromJson(doc.data(), doc.id);
            } catch (e) {
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<ListingModel>()
          .where((listing) =>
              listing.title.toLowerCase().contains(queryLower) ||
              listing.description.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      // Return empty list on error instead of throwing
      return [];
    }
  }

  /// Get pending listings (for admin approval)
  /// Note: Requires composite index on (status, createdAt)
  static Stream<List<ListingModel>> getPendingListings() {
    try {
      return _collection
          .where('status', isEqualTo: ListingStatus.pending.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return ListingModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                return null;
              }
            })
            .where((listing) => listing != null)
            .cast<ListingModel>()
            .toList();
      }).handleError((error) {
        return <ListingModel>[];
      });
    } catch (e) {
      return Stream.value(<ListingModel>[]);
    }
  }
}
