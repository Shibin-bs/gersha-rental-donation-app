import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';
import 'receive_rent_detail_screen.dart';

/// Receive/Rent tab screen - browse available items to receive or rent
class ReceiveRentTabScreen extends StatefulWidget {
  const ReceiveRentTabScreen({super.key});

  @override
  State<ReceiveRentTabScreen> createState() => _ReceiveRentTabScreenState();
}

class _ReceiveRentTabScreenState extends State<ReceiveRentTabScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  int _refreshKey = 0; // Key to force StreamBuilder refresh

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Don't refetch on resume - StreamBuilder handles this automatically
    // This prevents refetch loops that cause freezing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.favorite),
                text: 'Donations',
              ),
              Tab(
                icon: Icon(Icons.shopping_cart),
                text: 'Rentals',
              ),
            ],
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDonationView(),
                _buildRentalView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build donation view with approved listings
  Widget _buildDonationView() {
    // Get approved donation listings from Firestore
    // Use refreshKey to force refresh when needed
    return StreamBuilder<List<ListingModel>>(
      key: ValueKey('donations_$_refreshKey'),
      stream: ListingService.getApprovedListings(
        type: ListingType.donation,
      ),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return _buildErrorState(
            'Failed to load donations',
            snapshot.error.toString(),
            () {
              setState(() {
                _refreshKey++;
              });
            },
          );
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle data state
        final donations = snapshot.data ?? [];
        
        // Group by category
        final categories = [
          ListingCategory.books,
          ListingCategory.necessities,
          ListingCategory.tools,
          ListingCategory.electronics,
        ];

        if (donations.isEmpty) {
          return _buildEmptyState(ListingType.donation);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force StreamBuilder to refresh by updating key
            setState(() {
              _refreshKey++;
            });
            // Wait a bit for the stream to emit
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryItems = donations
                  .where((p) => p.category == category)
                  .toList();

              if (categoryItems.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      category.toString().split('.').last[0].toUpperCase() +
                          category.toString().split('.').last.substring(1),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...categoryItems.map((item) => _buildListingCard(item)),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Build rental view with approved listings
  Widget _buildRentalView() {
    // Get approved rental listings from Firestore
    // Use refreshKey to force refresh when needed
    return StreamBuilder<List<ListingModel>>(
      key: ValueKey('rentals_$_refreshKey'),
      stream: ListingService.getApprovedListings(
        type: ListingType.rental,
      ),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return _buildErrorState(
            'Failed to load rentals',
            snapshot.error.toString(),
            () {
              setState(() {
                _refreshKey++;
              });
            },
          );
        }

        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle data state
        final rentals = snapshot.data ?? [];
        
        // Group by category (including vehicles)
        final categories = ListingCategory.values;

        if (rentals.isEmpty) {
          return _buildEmptyState(ListingType.rental);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force StreamBuilder to refresh by updating key
            setState(() {
              _refreshKey++;
            });
            // Wait a bit for the stream to emit
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryItems = rentals
                  .where((p) => p.category == category)
                  .toList();

              if (categoryItems.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      category.toString().split('.').last[0].toUpperCase() +
                          category.toString().split('.').last.substring(1),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...categoryItems.map((item) => _buildListingCard(item)),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Build listing card widget
  Widget _buildListingCard(ListingModel listing) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiveRentDetailScreen(listing: listing),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: listing.type == ListingType.donation
                      ? Colors.green[100]
                      : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  listing.type == ListingType.donation
                      ? Icons.favorite
                      : Icons.shopping_cart,
                  color: listing.type == ListingType.donation
                      ? Colors.green[700]
                      : Colors.blue[700],
                  size: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (listing.type == ListingType.rental)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: listing.rentalPrice == 0
                                  ? Colors.green[50]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listing.rentalPrice == 0
                                  ? 'Free'
                                  : '₹${listing.rentalPrice.toStringAsFixed(2)}/day',
                              style: TextStyle(
                                color: listing.rentalPrice == 0
                                    ? Colors.green[900]
                                    : Colors.blue[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Available',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(ListingType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == ListingType.donation ? Icons.favorite_border : Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${type == ListingType.donation ? "donations" : "rentals"} available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState(String title, String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
