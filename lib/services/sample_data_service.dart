import '../models/listing_model.dart';
import '../services/firebase_service.dart';
import '../services/listing_service.dart';

/// Service to create sample data in Firestore for testing
/// Populates listings collection with test data on first launch
class SampleDataService {
  static const String _sampleDataKey = 'sample_data_created';

  /// Create sample data if not already created
  /// Checks Firestore to avoid creating duplicate data
  static Future<void> createSampleDataIfNeeded() async {
    try {
      // Check if sample data already exists
      final settingsDoc = await FirebaseService.firestore
          .collection('app_settings')
          .doc('sample_data')
          .get();

      if (settingsDoc.exists && settingsDoc.data()?[_sampleDataKey] == true) {
        // Sample data already created, skip
        return;
      }

      // Create sample listings
      await _createSampleListings();

      // Mark sample data as created
      await FirebaseService.firestore
          .collection('app_settings')
          .doc('sample_data')
          .set({_sampleDataKey: true, 'createdAt': DateTime.now().toIso8601String()});
    } catch (e) {
      // Silently fail - sample data is optional
      print('Failed to create sample data: $e');
    }
  }

  /// Create sample listings in Firestore
  /// Note: These listings will have a dummy ownerId - in production, use real user IDs
  static Future<void> _createSampleListings() async {
    final dummyOwnerId = 'sample_owner_${DateTime.now().millisecondsSinceEpoch}';

    // Sample donation listings
    // Donation categories: Books, Necessities, Tools, Electronics (NO Vehicles)
    final donationListings = [
      ListingModel(
        itemId: 'donation1',
        ownerId: dummyOwnerId,
        title: 'Physics Textbook - Class 12',
        description: 'NCERT Physics textbook in excellent condition, barely used. Perfect for students preparing for board exams.',
        category: ListingCategory.books,
        condition: 'like_new',
        images: [],
        type: ListingType.donation,
        rentalPrice: 0.0,
        durationAvailable: 30,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ListingModel(
        itemId: 'donation2',
        ownerId: dummyOwnerId,
        title: 'Winter Blankets - Set of 5',
        description: '5 warm blankets in good condition. Perfect for families in need during winter season.',
        category: ListingCategory.necessities,
        condition: 'good',
        images: [],
        type: ListingType.donation,
        rentalPrice: 0.0,
        durationAvailable: 60,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ListingModel(
        itemId: 'donation3',
        ownerId: dummyOwnerId,
        title: 'Complete Toolkit Set',
        description: 'Complete toolkit with hammer, screwdriver set, pliers, wrenches, and more. Great for home repairs and DIY projects.',
        category: ListingCategory.tools,
        condition: 'good',
        images: [],
        type: ListingType.donation,
        rentalPrice: 0.0,
        durationAvailable: 45,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ListingModel(
        itemId: 'donation4',
        ownerId: dummyOwnerId,
        title: 'Mobile Phone Charger - Universal',
        description: 'Universal USB charger compatible with most smartphones. Brand new, unused, still in original packaging.',
        category: ListingCategory.electronics,
        condition: 'new',
        images: [],
        type: ListingType.donation,
        rentalPrice: 0.0,
        durationAvailable: 30,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // Sample rental listings
    // Rental categories: Books, Necessities, Tools, Electronics, Vehicles
    final rentalListings = [
      ListingModel(
        itemId: 'rental1',
        ownerId: dummyOwnerId,
        title: 'Novel Collection - 10 Popular Books',
        description: 'Collection of popular fiction novels including bestsellers. Perfect for book lovers. Rent for a week or month.',
        category: ListingCategory.books,
        condition: 'good',
        images: [],
        type: ListingType.rental,
        rentalPrice: 20.0, // 20 INR per day
        durationAvailable: 30,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      ListingModel(
        itemId: 'rental2',
        ownerId: dummyOwnerId,
        title: 'Camera Tripod Stand - Professional',
        description: 'Professional camera tripod, adjustable height up to 150cm. Perfect for photography enthusiasts and content creators.',
        category: ListingCategory.electronics,
        condition: 'like_new',
        images: [],
        type: ListingType.rental,
        rentalPrice: 50.0, // 50 INR per day
        durationAvailable: 60,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ListingModel(
        itemId: 'rental3',
        ownerId: dummyOwnerId,
        title: 'Power Drill Machine with Bits',
        description: 'Electric power drill with multiple drill bits and accessories. Suitable for DIY projects and home repairs.',
        category: ListingCategory.tools,
        condition: 'good',
        images: [],
        type: ListingType.rental,
        rentalPrice: 100.0, // 100 INR per day
        durationAvailable: 45,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ListingModel(
        itemId: 'rental4',
        ownerId: dummyOwnerId,
        title: 'Mountain Bike - Well Maintained',
        description: 'Well-maintained mountain bike with gears, perfect for cycling enthusiasts. Available for daily or weekly rental. Includes helmet.',
        category: ListingCategory.vehicles,
        condition: 'good',
        images: [],
        type: ListingType.rental,
        rentalPrice: 150.0, // 150 INR per day
        durationAvailable: 30,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ListingModel(
        itemId: 'rental5',
        ownerId: dummyOwnerId,
        title: 'Study Table with Drawers',
        description: 'Wooden study table with drawers and storage space. Perfect for students working from home or studying.',
        category: ListingCategory.necessities,
        condition: 'good',
        images: [],
        type: ListingType.rental,
        rentalPrice: 30.0, // 30 INR per day
        durationAvailable: 90,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ListingModel(
        itemId: 'rental6',
        title: 'Bicycle - Free Rental',
        ownerId: dummyOwnerId,
        description: 'Simple bicycle available for free rental. Just return it in good condition. Perfect for short commutes.',
        category: ListingCategory.vehicles,
        condition: 'fair',
        images: [],
        type: ListingType.rental,
        rentalPrice: 0.0, // Free rental
        durationAvailable: 30,
        status: ListingStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];

    // Save all sample listings to Firestore
    for (var listing in donationListings) {
      try {
        await ListingService.createListing(listing);
      } catch (e) {
        print('Failed to create donation listing ${listing.itemId}: $e');
      }
    }

    for (var listing in rentalListings) {
      try {
        await ListingService.createListing(listing);
      } catch (e) {
        print('Failed to create rental listing ${listing.itemId}: $e');
      }
    }
  }
}
