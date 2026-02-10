import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/listing_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/transaction_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';

/// Detail screen for receiving/renting an item
class ReceiveRentDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ReceiveRentDetailScreen({super.key, required this.listing});

  @override
  State<ReceiveRentDetailScreen> createState() => _ReceiveRentDetailScreenState();
}

class _ReceiveRentDetailScreenState extends State<ReceiveRentDetailScreen> {
  DateTime? _selectedReturnDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _isLoading = false;

  /// Calculate rental amount based on selected return date
  double? _calculateRentalAmount() {
    if (widget.listing.type == ListingType.donation) return null;
    if (_selectedReturnDate == null) return null;
    
    final days = _selectedReturnDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return null;
    
    return widget.listing.rentalPrice * days;
  }

  /// Handle receive/rent action - creates transaction in Firestore
  Future<void> _handleReceiveOrRent() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fraud-prevention limit: each user can only have at most 2 active items
    // across donations and rentals (e.g., 2 donations, 2 rentals, or 1+1).
    try {
      final activeTransactions =
          await TransactionService.getActiveTransactionsForUser(user.uid);
      // Only count transactions where the user is the receiver (items they've taken)
      final activeAsReceiver = activeTransactions
          .where((t) => t.receiverId == user.uid)
          .toList();

      if (activeAsReceiver.length >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Limit reached: You can only have 2 active items at a time (any mix of donations/rentals).',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to check item limit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // For rentals, require return date
    if (widget.listing.type == ListingType.rental && _selectedReturnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a return date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.listing.type == ListingType.donation
              ? 'Receive Donation'
              : 'Rent Item',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ${widget.listing.type == ListingType.donation ? "receive" : "rent"} "${widget.listing.title}"?'),
            if (widget.listing.type == ListingType.rental && _selectedReturnDate != null) ...[
              const SizedBox(height: 8),
              Text('Return date: ${_dateFormat.format(_selectedReturnDate!)}'),
              if (_calculateRentalAmount() != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Total amount: ₹${_calculateRentalAmount()!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.listing.type == ListingType.donation ? 'Receive' : 'Rent'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Calculate duration in days
        final duration = _selectedReturnDate != null
            ? _selectedReturnDate!.difference(DateTime.now()).inDays
            : 0;

        // Generate transaction ID using UUID format
        final transactionId = 'trans_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 8)}';
        
        // Create transaction in Firestore
        final transaction = TransactionModel(
          transactionId: transactionId,
          listingId: widget.listing.itemId,
          ownerId: widget.listing.ownerId,
          receiverId: user.uid,
          type: widget.listing.type == ListingType.donation
              ? TransactionType.donation
              : TransactionType.rental,
          amount: _calculateRentalAmount() ?? 0.0,
          duration: duration,
          startDate: DateTime.now(),
          endDate: _selectedReturnDate,
          status: TransactionStatus.active,
        );

        // Create transaction in Firestore
        await TransactionService.createTransaction(transaction);
        
        // Update listing status to rented/donated
        final newStatus = widget.listing.type == ListingType.donation
            ? ListingStatus.donated
            : ListingStatus.rented;
        await ListingService.updateListingStatus(widget.listing.itemId, newStatus);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.listing.type == ListingType.donation
                    ? 'Donation received successfully!'
                    : 'Item rented successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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

  /// Select return date (for rentals)
  Future<void> _selectReturnDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Return Date',
    );

    if (picked != null) {
      setState(() {
        _selectedReturnDate = picked;
      });
    }
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rentalAmount = _calculateRentalAmount();
    final isFreeRental = widget.listing.type == ListingType.rental &&
        widget.listing.rentalPrice == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header image/icon
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: widget.listing.type == ListingType.donation
                    ? Colors.green[100]
                    : Colors.blue[100],
              ),
              child: Center(
                child: Icon(
                  widget.listing.type == ListingType.donation
                      ? Icons.favorite
                      : Icons.shopping_cart,
                  size: 100,
                  color: widget.listing.type == ListingType.donation
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
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.listing.type == ListingType.donation
                          ? Colors.green[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.listing.type == ListingType.donation
                          ? 'Donation'
                          : 'Rental',
                      style: TextStyle(
                        color: widget.listing.type == ListingType.donation
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
                    widget.listing.title,
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
                        widget.listing.category.toString().split('.').last[0].toUpperCase() +
                            widget.listing.category.toString().split('.').last.substring(1),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price (for rentals)
            if (widget.listing.type == ListingType.rental)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, color: Colors.blue[900], size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isFreeRental ? 'Free Rental' : 'Rental Price',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    isFreeRental
                                        ? 'No charge'
                                        : '₹${widget.listing.rentalPrice.toStringAsFixed(2)} per day',
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
                        if (!isFreeRental) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _selectReturnDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _selectedReturnDate == null
                                  ? 'Select Return Date'
                                  : 'Return: ${_dateFormat.format(_selectedReturnDate!)}',
                            ),
                          ),
                          if (_selectedReturnDate != null && rentalAmount != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '₹${rentalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
                    widget.listing.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Owner information (fetch from Firestore)
            FutureBuilder<UserModel?>(
              future: UserService.getUser(widget.listing.ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError) {
                  return const SizedBox.shrink(); // Hide on error
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  final owner = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (owner.name != null)
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Name'),
                            subtitle: Text(owner.name!),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyToClipboard(owner.name!, 'Name'),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            tileColor: Colors.grey[100],
                          ),
                        if (owner.email != null || owner.phone != null)
                          ListTile(
                            leading: const Icon(Icons.contact_mail),
                            title: const Text('Contact'),
                            subtitle: Text(owner.email ?? owner.phone ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyToClipboard(
                                owner.email ?? owner.phone ?? '',
                                'Contact',
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            tileColor: Colors.grey[100],
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleReceiveOrRent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.listing.type == ListingType.donation
                      ? Colors.green
                      : Colors.blue,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.listing.type == ListingType.donation
                            ? 'Receive Donation'
                            : (isFreeRental ? 'Rent for Free' : 'Rent Item'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
