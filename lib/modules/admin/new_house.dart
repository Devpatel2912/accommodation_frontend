import 'dart:io';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/views/location_picker_view.dart';
import 'package:flutter/material.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../presentation/widgets/app_button.dart';

class NewHouseScreen extends StatefulWidget {
  final Map<String, dynamic>? houseToEdit;
  const NewHouseScreen({super.key, this.houseToEdit});

  @override
  State<NewHouseScreen> createState() => _NewHouseScreenState();
}

class _NewHouseScreenState extends State<NewHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  
  File? _image;
  final _picker = ImagePicker();
  bool _isUploading = false;
  String? _imageUrl;
  double _latitude = 23.0225; // Default Ahmedabad
  double _longitude = 72.5714;

  @override
  void initState() {
    super.initState();
    if (widget.houseToEdit != null) {
      _ownerCtrl.text = widget.houseToEdit!['owner_name'] ?? '';
      _contactCtrl.text = widget.houseToEdit!['contact_number'] ?? widget.houseToEdit!['phone'] ?? '';
      _addressCtrl.text = widget.houseToEdit!['address'] ?? '';
      _capacityCtrl.text = widget.houseToEdit!['capacity']?.toString() ?? '';
      _imageUrl = widget.houseToEdit!['image_url'];
      _latitude = double.tryParse(widget.houseToEdit!['latitude']?.toString() ?? '') ?? 23.0225;
      _longitude = double.tryParse(widget.houseToEdit!['longitude']?.toString() ?? '') ?? 72.5714;
      _locationCtrl.text = '$_latitude, $_longitude';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Add New House',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Property Information'),
              _buildTextField(_ownerCtrl, 'Owner Name', Icons.person_outline_rounded, 'e.g. John Doe'),
              _buildTextField(
                _contactCtrl,
                'Contact Number',
                Icons.phone_outlined,
                'e.g. 9876543210',
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Contact number is required';
                  if (value.length != 10) return 'Contact number must be exactly 10 digits';
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Enter digits only';
                  return null;
                },
              ),
              _buildTextField(
                _capacityCtrl,
                'Capacity (Guests)',
                Icons.group_outlined,
                'e.g. 10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Capacity is required';
                  final n = int.tryParse(value);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Capacity must be a positive number';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Location Details'),
              _buildTextField(_addressCtrl, 'Full Address', Icons.location_on_outlined, 'Street, City, State'),
              _buildTextField(
                _locationCtrl,
                'Map Coordinates',
                Icons.map_outlined,
                'Tap to select on map',
                readOnly: true,
                onTap: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerView(
                        initialLocation: LatLng(_latitude, _longitude),
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _latitude = result.latitude;
                      _longitude = result.longitude;
                      _locationCtrl.text = '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}';
                    });
                  }
                },
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Property Images (Optional)'),
              _buildImagePicker(),
              
              const SizedBox(height: 40),
              AppButton(
                text: 'Save Property',
                height: 56,
                borderRadius: 16,
                isLoading: _isUploading,
                onPressed: _submitForm,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.teal, size: 20),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(color: AppColors.labelGrey, fontSize: 13.5),
          floatingLabelStyle: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.border, fontSize: 13.5),
          counterText: "",
          errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11.5, height: 1.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),
        validator: validator ?? (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        clipBehavior: Clip.antiAlias,
        child: _image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_image!, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () => setState(() => _image = null),
                      ),
                    ),
                  ),
                ],
              )
            : _imageUrl != null && _imageUrl!.isNotEmpty
                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate_outlined, color: AppColors.teal, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Upload Property Photos',
                        style: TextStyle(color: AppColors.labelGrey, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'PNG, JPG up to 10MB',
                        style: TextStyle(color: AppColors.border, fontSize: 11),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      
      String? finalImageUrl = _imageUrl;
      
      if (_image != null) {
        final viewModel = Provider.of<UserHomeViewModel>(context, listen: false);
        final uploadedUrl = await viewModel.uploadImage(_image!.path);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          setState(() => _isUploading = false);
          AppNotifications.showTopSnackBar(context, 'Failed to upload image. Saving without image.', isError: true);
        }
      }

      final data = {
        'owner_name': _ownerCtrl.text,
        'contact_number': _contactCtrl.text,
        'address': _addressCtrl.text,
        'capacity': int.tryParse(_capacityCtrl.text) ?? 0,
        'is_active': true,
        'image_url': finalImageUrl,
        'latitude': _latitude, 
        'longitude': _longitude,
      };
      
      final viewModel = Provider.of<UserHomeViewModel>(context, listen: false);
      bool success;
      
      if (widget.houseToEdit != null) {
        success = await viewModel.updateHouse(widget.houseToEdit!['id'], data);
      } else {
        success = await viewModel.addHouse(data);
      }

      setState(() => _isUploading = false);
      
      if (success) {
        Navigator.pop(context, true); // Return true to signal success
      } else {
        AppNotifications.showTopSnackBar(context, 'Failed to save property details', isError: true);
      }
    }
  }
}
