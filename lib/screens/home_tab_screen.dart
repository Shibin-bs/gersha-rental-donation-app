import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/transaction_service.dart';
import '../services/listing_service.dart';
import '../models/transaction_model.dart';
import '../models/listing_model.dart';

/// Home tab screen showing donation and rental history
/// Displays items donated, items rented out, items received, and items rented
/// Shows duration and rental amount for transactions
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with WidgetsBindingObserver {
  int _refreshKey = 0; // Key to force StreamBuilder refresh

  @override
  void initState() {
    super.initState();
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
  
  /// Refresh transactions (for RefreshIndicator)
  Future<void> _refreshTransactions() async {
    // Force StreamBuilder to refresh by updating key
    setState(() {
      _refreshKey++;
    });
    // Wait a bit for the streams to emit
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    // Use nested StreamBuilders to combine both streams
    return StreamBuilder<List<TransactionModel>>(
      key: ValueKey('owner_transactions_$_refreshKey'),
      stream: TransactionService.getTransactionsByOwner(user.uid),
      builder: (context, ownerSnapshot) {
        return StreamBuilder<List<TransactionModel>>(
          key: ValueKey('receiver_transactions_$_refreshKey'),
          stream: TransactionService.getTransactionsByReceiver(user.uid),
          builder: (context, receiverSnapshot) {
            // Handle error states
            if (ownerSnapshot.hasError || receiverSnapshot.hasError) {
              return _buildErrorState(
                'Failed to load transactions',
                ownerSnapshot.hasError 
                    ? ownerSnapshot.error.toString()
                    : receiverSnapshot.error.toString(),
                _refreshTransactions,
              );
            }

            // Handle loading state
            if ((ownerSnapshot.connectionState == ConnectionState.waiting && !ownerSnapshot.hasData) ||
                (receiverSnapshot.connectionState == ConnectionState.waiting && !receiverSnapshot.hasData)) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle data state
            final transactionsAsOwner = ownerSnapshot.data ?? [];
            final transactionsAsReceiver = receiverSnapshot.data ?? [];

            final donatedItems = transactionsAsOwner
                .where((t) => t.type == TransactionType.donation)
                .toList();
            final rentedOutItems = transactionsAsOwner
                .where((t) => t.type == TransactionType.rental)
                .toList();
            final receivedItems = transactionsAsReceiver
                .where((t) => t.type == TransactionType.donation)
                .toList();
            final rentedItems = transactionsAsReceiver
                .where((t) => t.type == TransactionType.rental)
                .toList();

    return RefreshIndicator(
      onRefresh: _refreshTransactions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.name ?? user.email ?? user.phone ?? 'User',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Donated',
                    donatedItems.length.toString(),
                    Icons.favorite,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Rented Out',
                    rentedOutItems.length.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Received',
                    receivedItems.length.toString(),
                    Icons.inbox,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Rented',
                    rentedItems.length.toString(),
                    Icons.shopping_bag,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Donated Items Section
            if (donatedItems.isNotEmpty) ...[
              _buildSectionHeader('Items You Donated', Icons.favorite),
              const SizedBox(height: 12),
              ...donatedItems.map((transaction) => _buildTransactionCard(transaction, true)),
              const SizedBox(height: 24),
            ],

            // Rented Out Items Section
            if (rentedOutItems.isNotEmpty) ...[
              _buildSectionHeader('Items You Rented Out', Icons.shopping_cart),
              const SizedBox(height: 12),
              ...rentedOutItems.map((transaction) => _buildTransactionCard(transaction, true)),
              const SizedBox(height: 24),
            ],

            // Received Items Section
            if (receivedItems.isNotEmpty) ...[
              _buildSectionHeader('Items You Received', Icons.inbox),
              const SizedBox(height: 12),
              ...receivedItems.map((transaction) => _buildTransactionCard(transaction, false)),
              const SizedBox(height: 24),
            ],

            // Rented Items Section
            if (rentedItems.isNotEmpty) ...[
              _buildSectionHeader('Items You Rented', Icons.shopping_bag),
              const SizedBox(height: 12),
              ...rentedItems.map((transaction) => _buildTransactionCard(transaction, false)),
              const SizedBox(height: 24),
            ],

            // Empty state
            if (donatedItems.isEmpty &&
                rentedOutItems.isEmpty &&
                receivedItems.isEmpty &&
                rentedItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by listing items or receiving items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
          },
        );
      },
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

  /// Build summary card widget
  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  /// Build transaction card with listing details
  Widget _buildTransactionCard(TransactionModel transaction, bool isMyItem) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return FutureBuilder<ListingModel?>(
      future: ListingService.getListing(transaction.listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading listing: ${snapshot.error}'),
            ),
          );
        }
        
        final listing = snapshot.data;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: transaction.type == TransactionType.donation
                            ? Colors.green[100]
                            : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        transaction.type == TransactionType.donation
                            ? Icons.favorite
                            : Icons.shopping_cart,
                        color: transaction.type == TransactionType.donation
                            ? Colors.green[700]
                            : Colors.blue[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing?.title ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (listing != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              listing.category.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${isMyItem ? (transaction.type == TransactionType.donation ? "Donated" : "Rented out") : (transaction.type == TransactionType.donation ? "Received" : "Rented")} on ${dateFormat.format(transaction.startDate)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                if (transaction.duration > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ${transaction.duration} days',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
                if (transaction.endDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'End date: ${dateFormat.format(transaction.endDate!)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
                if (transaction.amount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Amount: ₹${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
