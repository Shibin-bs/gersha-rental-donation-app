import 'package:flutter/material.dart';
import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import 'admin_listing_detail_screen.dart';
import 'admin_edit_listing_screen.dart';

/// Admin listings screen to view and manage all listings
class AdminListingsScreen extends StatefulWidget {
  final ListingStatus? initialFilter;

  const AdminListingsScreen({super.key, this.initialFilter});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen>
    with WidgetsBindingObserver {
  ListingStatus? _selectedFilter;
  int _refreshKey = 0; // Key to force StreamBuilder refresh

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      appBar: AppBar(
        title: const Text('All Listings'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminEditListingScreen(),
            ),
          );
          if (result == true) {
            setState(() {
              _refreshKey++;
            });
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildFilterChip(null, 'All'),
                  _buildFilterChip(ListingStatus.pending, 'Pending'),
                  _buildFilterChip(ListingStatus.approved, 'Approved'),
                  _buildFilterChip(ListingStatus.rejected, 'Rejected'),
                  _buildFilterChip(ListingStatus.rented, 'Rented'),
                  _buildFilterChip(ListingStatus.donated, 'Donated'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Listings list from Firestore
          Expanded(
            child: StreamBuilder<List<ListingModel>>(
              key: ValueKey('admin_listings_$_refreshKey'),
              stream: ListingService.getAllListings(),
              builder: (context, snapshot) {
                // Handle error state
                if (snapshot.hasError) {
                  return _buildErrorState(
                    'Failed to load listings',
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
                var listings = snapshot.data ?? [];

                // Apply filter if selected
                if (_selectedFilter != null) {
                  listings = listings.where((p) => p.status == _selectedFilter).toList();
                }

                // Sort by creation date (newest first)
                listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No listings found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
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
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(listing.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              listing.type == ListingType.donation
                                  ? Icons.favorite
                                  : Icons.shopping_cart,
                              color: _getStatusColor(listing.status),
                            ),
                          ),
                          title: Text(
                            listing.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${listing.type.toString().split('.').last.toUpperCase()} - ${listing.category.toString().split('.').last}',
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(listing.status).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(listing.status),
                                      style: TextStyle(
                                        color: _getStatusColor(listing.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (listing.type == ListingType.rental) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      listing.rentalPrice == 0
                                          ? 'Free'
                                          : '₹${listing.rentalPrice.toStringAsFixed(2)}/day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminListingDetailScreen(listing: listing),
                              ),
                            );
                            if (result == true) {
                              setState(() {});
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ListingStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? status : null;
          });
        },
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.pending:
        return Colors.orange;
      case ListingStatus.approved:
        return Colors.green;
      case ListingStatus.rejected:
        return Colors.red;
      case ListingStatus.rented:
      case ListingStatus.donated:
        return Colors.blue;
    }
  }

  String _getStatusLabel(ListingStatus status) {
    switch (status) {
      case ListingStatus.pending:
        return 'Pending';
      case ListingStatus.approved:
        return 'Approved';
      case ListingStatus.rejected:
        return 'Rejected';
      case ListingStatus.rented:
        return 'Rented';
      case ListingStatus.donated:
        return 'Donated';
    }
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
