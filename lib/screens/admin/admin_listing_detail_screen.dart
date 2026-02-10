import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../services/listing_service.dart';
import 'admin_edit_listing_screen.dart';

/// Admin listing detail screen to approve, reject, or delete listings
class AdminListingDetailScreen extends StatelessWidget {
  final ListingModel listing;

  const AdminListingDetailScreen({super.key, required this.listing});

  /// Handle approve action - updates listing status in Firestore
  Future<void> _handleApprove(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Listing'),
        content: Text('Are you sure you want to approve "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ListingService.updateListingStatus(listing.itemId, ListingStatus.approved);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handle reject action - updates listing status in Firestore
  Future<void> _handleReject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Listing'),
        content: Text('Are you sure you want to reject "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ListingService.updateListingStatus(listing.itemId, ListingStatus.rejected);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handle delete action - deletes listing from Firestore
  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to permanently delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ListingService.deleteListing(listing.itemId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final isPending = listing.status == ListingStatus.pending;
    final isRejected = listing.status == ListingStatus.rejected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: listing.type == ListingType.donation
                    ? Colors.green[100]
                    : Colors.blue[100],
              ),
              child: Center(
                child: Icon(
                  listing.type == ListingType.donation
                      ? Icons.favorite
                      : Icons.shopping_cart,
                  size: 100,
                  color: listing.type == ListingType.donation
                      ? Colors.green[700]
                      : Colors.blue[700],
                ),
              ),
            ),

            // Status badge
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(listing.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(listing.status),
                      style: TextStyle(
                        color: _getStatusColor(listing.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: listing.type == ListingType.donation
                          ? Colors.green[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.type == ListingType.donation
                          ? 'Donation'
                          : 'Rental',
                      style: TextStyle(
                        color: listing.type == ListingType.donation
                            ? Colors.green[900]
                            : Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title and category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        listing.category.toString().split('.').last[0].toUpperCase() +
                            listing.category.toString().split('.').last.substring(1),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price (for rentals)
            if (listing.type == ListingType.rental)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.currency_rupee, color: Colors.blue[900], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rental Price',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                listing.rentalPrice == 0
                                    ? 'Free'
                                    : '₹${listing.rentalPrice.toStringAsFixed(2)} per day',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Condition
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Listing Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Created',
                        dateFormat.format(listing.createdAt),
                      ),
                      _buildInfoRow(
                        Icons.info,
                        'Condition',
                        listing.condition.split('_').map((word) => 
                          word[0].toUpperCase() + word.substring(1)
                        ).join(' '),
                      ),
                      _buildInfoRow(
                        Icons.access_time,
                        'Duration Available',
                        '${listing.durationAvailable} days',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Edit button (always available for admin)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminEditListingScreen(
                            existingListing: listing,
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Listing'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isPending) ...[
                    ElevatedButton.icon(
                      onPressed: () => _handleApprove(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve Listing'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _handleReject(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject Listing'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                  if (isRejected || !isPending) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _handleDelete(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Listing'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
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
}
