// lib/screens/listings/add_edit_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';

class AddEditListingScreen extends StatefulWidget {
  final ListingModel? listing; // null = create, non-null = edit

  const AddEditListingScreen({super.key, this.listing});

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  String _selectedCategory = AppConstants.categories[1];
  bool _isLoading = false;

  bool get isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameController = TextEditingController(text: l?.name ?? '');
    _addressController = TextEditingController(text: l?.address ?? '');
    _contactController = TextEditingController(text: l?.contactNumber ?? '');
    _descriptionController = TextEditingController(text: l?.description ?? '');
    _latController = TextEditingController(
        text: l?.latitude.toString() ?? AppConstants.kigaliLat.toString());
    _lngController = TextEditingController(
        text: l?.longitude.toString() ?? AppConstants.kigaliLng.toString());
    _selectedCategory = l?.category ?? AppConstants.categories[1];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<ListingProvider>();

    // Get user info with null safety
    final user = auth.user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }

    final userId = user.uid;
    final userName = user.displayName?.isNotEmpty == true 
        ? user.displayName 
        : (user.email?.split('@').first ?? 'Anonymous');

    try {
      if (isEditing) {
        await provider.updateListing(widget.listing!.id, {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'address': _addressController.text.trim(),
          'contactNumber': _contactController.text.trim(),
          'description': _descriptionController.text.trim(),
          'latitude': double.tryParse(_latController.text) ?? AppConstants.kigaliLat,
          'longitude': double.tryParse(_lngController.text) ?? AppConstants.kigaliLng,
        });
      } else {
        final listing = ListingModel(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          category: _selectedCategory,
          address: _addressController.text.trim(),
          contactNumber: _contactController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: double.tryParse(_latController.text) ?? AppConstants.kigaliLat,
          longitude: double.tryParse(_lngController.text) ?? AppConstants.kigaliLng,
          createdBy: userId,
          createdByName: userName,
          createdAt: DateTime.now(),
        );
        await provider.createListing(listing);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Listing updated successfully!'
                : 'Listing created successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing' : 'Add Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Category selector
            const Text(
              'Category',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDark,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  items: AppConstants.categories
                      .where((c) => c != 'All')
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Text(
                                    AppConstants.categoryIcons[cat] ?? '📍',
                                    style:
                                        const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(cat),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _nameController,
              label: 'Place / Service Name',
              hint: 'e.g. Kimironko Café',
              icon: Icons.store_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _addressController,
              label: 'Address',
              hint: 'e.g. Kimironko, Kigali',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _contactController,
              label: 'Contact Number',
              hint: '+250 788 000 000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Contact number is required' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe this place...',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            // Coordinates
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _latController,
                    label: 'Latitude',
                    hint: '-1.9441',
                    icon: Icons.my_location_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _lngController,
                    label: 'Longitude',
                    hint: '30.0619',
                    icon: Icons.my_location_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Kigali coordinates: Lat ~-1.94, Lng ~30.06',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Listing'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppTheme.textMuted, size: 18)
                : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}