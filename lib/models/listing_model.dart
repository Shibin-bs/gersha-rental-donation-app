/// Listing model for items that can be donated or rented
/// Fields: itemId, ownerId, title, description, category, condition, images, type, rentalPrice, durationAvailable, status, createdAt
class ListingModel {
  final String itemId; // Unique item ID
  final String ownerId; // Firebase Auth UID of the owner
  final String title;
  final String description;
  final ListingCategory category; // Books, Necessities, Tools, Electronics, Vehicles
  final String condition; // e.g., 'new', 'like_new', 'good', 'fair', 'poor'
  final List<String> images; // CDN or hosted image URLs
  final ListingType type; // 'donation' or 'rental'
  final double rentalPrice; // In INR, 0 allowed for free rentals or donations
  final int durationAvailable; // Duration in days
  final ListingStatus status; // 'pending', 'approved', 'rejected', 'rented', 'donated'
  final DateTime createdAt;

  ListingModel({
    required this.itemId,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    this.images = const [],
    required this.type,
    this.rentalPrice = 0.0,
    required this.durationAvailable,
    this.status = ListingStatus.pending,
    required this.createdAt,
  });

  /// Convert ListingModel to Map for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'condition': condition,
      'images': images,
      'type': type.toString().split('.').last,
      'rentalPrice': rentalPrice,
      'durationAvailable': durationAvailable,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create ListingModel from Firestore document
  factory ListingModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ListingModel(
      itemId: json['itemId'] as String? ?? documentId,
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: ListingCategory.values.firstWhere(
        (e) => e.toString().split('.').last == (json['category'] as String? ?? 'books'),
        orElse: () => ListingCategory.books,
      ),
      condition: json['condition'] as String? ?? 'good',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      type: ListingType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] as String? ?? 'donation'),
        orElse: () => ListingType.donation,
      ),
      rentalPrice: (json['rentalPrice'] as num?)?.toDouble() ?? 0.0,
      durationAvailable: json['durationAvailable'] as int? ?? 30,
      status: ListingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String? ?? 'pending'),
        orElse: () => ListingStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  ListingModel copyWith({
    String? itemId,
    String? ownerId,
    String? title,
    String? description,
    ListingCategory? category,
    String? condition,
    List<String>? images,
    ListingType? type,
    double? rentalPrice,
    int? durationAvailable,
    ListingStatus? status,
    DateTime? createdAt,
  }) {
    return ListingModel(
      itemId: itemId ?? this.itemId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      type: type ?? this.type,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      durationAvailable: durationAvailable ?? this.durationAvailable,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Listing type enum - donation or rental
enum ListingType {
  donation, // Free donation
  rental, // Rental (can be free or paid)
}

/// Listing category enum
/// Donation categories: Books, Necessities, Tools, Electronics
/// Rental categories: Books, Necessities, Tools, Electronics, Vehicles
enum ListingCategory {
  books,
  necessities,
  tools,
  electronics,
  vehicles, // Only for rentals, NOT for donations
}

/// Listing status enum
enum ListingStatus {
  pending, // Waiting for admin approval
  approved, // Approved by admin, ready to be listed
  rejected, // Rejected by admin
  rented, // Currently rented out
  donated, // Donated/received by someone
}
