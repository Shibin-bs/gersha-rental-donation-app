import 'package:flutter/foundation.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

/// Listing Provider for managing listings state
class ListingProvider with ChangeNotifier {
  List<ListingModel> _listings = [];
  List<ListingModel> _myListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ListingModel> get listings => _listings;
  List<ListingModel> get myListings => _myListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load approved listings (for browsing)
  void loadApprovedListings({
    ListingType? type,
    ListingCategory? category,
  }) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ListingService.getApprovedListings(type: type, category: category).listen(
      (listings) {
        _listings = listings;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Load my listings (by owner ID)
  void loadMyListings(String ownerId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ListingService.getListingsByOwner(ownerId).listen(
      (listings) {
        _myListings = listings;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Search listings
  Future<void> searchListings(String query) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _listings = await ListingService.searchListings(query);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a new listing
  Future<bool> createListing(ListingModel listing) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await ListingService.createListing(listing);
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
