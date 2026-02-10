import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/listing_service.dart';

/// Admin screen to add or edit a listing
/// - If [existingListing] is null → create mode
/// - If [existingListing] is provided → edit mode
class AdminEditListingScreen extends StatefulWidget {
  final ListingModel? existingListing;

  const AdminEditListingScreen({super.key, this.existingListing});

  bool get isEdit => existingListing != null;

  @override
  State<AdminEditListingScreen> createState() => _AdminEditListingScreenState();
}

class _AdminEditListingScreenState extends State<AdminEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  ListingType _selectedType = ListingType.donation;
  ListingCategory _selectedCategory = ListingCategory.books;
  String _selectedCondition = 'good';
  bool _isFreeRental = false;
  bool _isLoading = false;

  // Condition options
  final List<String> _conditions = ['new', 'like_new', 'good', 'fair', 'poor'];

  List<ListingCategory> get _availableCategories {
    if (_selectedType == ListingType.donation) {
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

  @override
  void initState() {
    super.initState();
    final listing = widget.existingListing;
    if (listing != null) {
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      _selectedType = listing.type;
      _selectedCategory = listing.category;
      _selectedCondition = listing.condition;
      _durationController.text = listing.durationAvailable.toString();
      if (listing.type == ListingType.rental) {
        if (listing.rentalPrice == 0) {
          _isFreeRental = true;
        } else {
          _priceController.text = listing.rentalPrice.toStringAsFixed(2);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      // Admin can create listings even if currentUser is null,
      // but we still try to attribute ownerId to the admin when possible.
      final ownerId = widget.existingListing?.ownerId ?? (currentUser?.uid ?? '');

      // Parse duration (default to 30 days if not provided)
      final duration = int.tryParse(_durationController.text.trim()) ?? 30;

      final now = DateTime.now();

      final itemId = widget.existingListing?.itemId ?? const Uuid().v4();

      final listing = ListingModel(
        itemId: itemId,
        ownerId: ownerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
        images: widget.existingListing?.images ?? const [],
        type: _selectedType,
        rentalPrice: _selectedType == ListingType.rental
            ? (_isFreeRental ? 0.0 : (double.tryParse(_priceController.text.trim()) ?? 0.0))
            : 0.0,
        durationAvailable: duration,
        // When admin edits, keep existing status; on create, default to approved.
        status: widget.existingListing?.status ?? ListingStatus.approved,
        createdAt: widget.existingListing?.createdAt ?? now,
      );

      if (widget.isEdit) {
        await ListingService.updateListing(listing.itemId, listing.toJson());
      } else {
        await ListingService.createListing(listing);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Listing updated successfully' : 'Listing created successfully'),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Listing' : 'Add Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isEdit
                        ? 'Update item details. Changes take effect immediately.'
                        : 'Create a new listing that will be immediately available (approved) for users.',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Type selector (donation / rental)
              ToggleButtons(
                isSelected: [
                  _selectedType == ListingType.donation,
                  _selectedType == ListingType.rental,
                ],
                onPressed: (index) {
                  setState(() {
                    _selectedType =
                        index == 0 ? ListingType.donation : ListingType.rental;
                    // Reset rental-specific state when switching
                    if (_selectedType == ListingType.donation) {
                      _isFreeRental = false;
                      _priceController.clear();
                    }
                    // Ensure category is valid for selected type
                    if (!_availableCategories.contains(_selectedCategory)) {
                      _selectedCategory = _availableCategories.first;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Donation'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Rental'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Item Title *',
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

              // Category
              DropdownButtonFormField<ListingCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _availableCategories.map((category) {
                  final name = category.toString().split('.').last;
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      '${name[0].toUpperCase()}${name.substring(1)}',
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

              // Condition
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items: _conditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(
                      condition
                          .split('_')
                          .map((word) =>
                              '${word[0].toUpperCase()}${word.substring(1)}')
                          .join(' '),
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

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
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

              // Rental-specific fields
              if (_selectedType == ListingType.rental) ...[
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
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Rental Price per Day (₹) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
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

              // Duration available
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration Available (days)',
                  hintText: 'e.g., 30 (default: 30 days)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
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

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : 'Create Listing',
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

