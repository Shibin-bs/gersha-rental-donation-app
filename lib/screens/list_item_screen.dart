import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/listing_model.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';

/// Screen for listing a new item (donation or rental)
class ListItemScreen extends StatefulWidget {
  final ListingType type;

  const ListItemScreen({super.key, required this.type});

  @override
  State<ListItemScreen> createState() => _ListItemScreenState();
}

class _ListItemScreenState extends State<ListItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  
  ListingCategory _selectedCategory = ListingCategory.books;
  String _selectedCondition = 'good';
  bool _isFreeRental = false;
  bool _isLoading = false;

  // Categories available based on type
  List<ListingCategory> get availableCategories {
    if (widget.type == ListingType.donation) {
      // Donation categories: Books, Necessities, Tools, Electronics (NO Vehicles)
      return [
        ListingCategory.books,
        ListingCategory.necessities,
        ListingCategory.tools,
        ListingCategory.electronics,
      ];
    } else {
      // Rental categories: Books, Necessities, Tools, Electronics, Vehicles
      return ListingCategory.values;
    }
  }

  // Condition options
  final List<String> _conditions = ['new', 'like_new', 'good', 'fair', 'poor'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  /// Handle form submission
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        
        if (user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User not found. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        // Parse duration (default to 30 days if not provided)
        final duration = int.tryParse(_durationController.text.trim()) ?? 30;

        // Create listing with pending status (needs admin approval)
        final listing = ListingModel(
          itemId: const Uuid().v4(),
          ownerId: user.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          condition: _selectedCondition,
          images: [], // Images can be added later with image picker
          type: widget.type,
          rentalPrice: widget.type == ListingType.rental
              ? (_isFreeRental ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0))
              : 0.0,
          durationAvailable: duration,
          status: ListingStatus.pending,
          createdAt: DateTime.now(),
        );

        // Save listing to Firestore
        final listingProvider = Provider.of<ListingProvider>(context, listen: false);
        final success = await listingProvider.createListing(listing);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.type == ListingType.donation
                      ? 'Item submitted for donation! Waiting for admin approval.'
                      : 'Item submitted for rental! Waiting for admin approval.',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(listingProvider.errorMessage ?? 'Failed to submit listing'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == ListingType.donation
              ? 'Donate Item'
              : 'List for Rent',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: widget.type == ListingType.donation
                    ? Colors.green[50]
                    : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.type == ListingType.donation
                            ? Icons.favorite
                            : Icons.shopping_cart,
                        color: widget.type == ListingType.donation
                            ? Colors.green[700]
                            : Colors.blue[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.type == ListingType.donation
                              ? 'Your item will be listed for free donation after admin approval'
                              : 'Your item will be listed for rental after admin approval',
                          style: TextStyle(
                            color: widget.type == ListingType.donation
                                ? Colors.green[900]
                                : Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Title *',
                  hintText: 'e.g., Physics Textbook, Office Chair',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<ListingCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.toString().split('.').last[0].toUpperCase() +
                          category.toString().split('.').last.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Condition dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items: _conditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(
                      condition.split('_').map((word) => 
                        word[0].toUpperCase() + word.substring(1)
                      ).join(' '),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCondition = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe the item in detail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              // Price field (only for rentals)
              if (widget.type == ListingType.rental) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Free Rental'),
                  value: _isFreeRental,
                  onChanged: (value) {
                    setState(() {
                      _isFreeRental = value ?? false;
                      if (_isFreeRental) {
                        _priceController.clear();
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (!_isFreeRental) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Rental Price per Day (₹) *',
                      hintText: 'e.g., 50.00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (_isFreeRental) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a rental price';
                      }
                      final price = double.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ],
              ],
              const SizedBox(height: 16),

              // Duration available field
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration Available (days)',
                  hintText: 'e.g., 30 (default: 30 days)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  helperText: 'How many days is this item available?',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final duration = int.tryParse(value.trim());
                    if (duration == null || duration <= 0) {
                      return 'Please enter a valid number of days';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.type == ListingType.donation
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
                        widget.type == ListingType.donation
                            ? 'Submit for Donation'
                            : 'Submit for Rental',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
