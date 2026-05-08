import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/api/api_config.dart';

import '../../core/utils/notifications.dart';

class LocationPickerView extends StatefulWidget {
  final LatLng? initialLocation;
  const LocationPickerView({super.key, this.initialLocation});

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  LatLng _selectedLocation = const LatLng(23.0225, 72.5714); // Ahmedabad Default
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _updateMarker(_selectedLocation);
    }
    _latController.text = _selectedLocation.latitude.toStringAsFixed(6);
    _lngController.text = _selectedLocation.longitude.toStringAsFixed(6);
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected-location'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            _updateMarker(newPosition);
          },
        ),
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppNotifications.showTopSnackBar(context, 'Location services are disabled.', isError: true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppNotifications.showTopSnackBar(context, 'Location permissions are denied', isError: true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppNotifications.showTopSnackBar(context, 'Location permissions are permanently denied.', isError: true);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    _updateMarker(latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  Future<List<Map<String, String>>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=${ApiConfig.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
          return predictions.map((p) {
            return {
              'description': p['description'] as String,
              'place_id': p['place_id'] as String,
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Autocomplete Error: $e');
    }
    return [];
  }

  Future<void> _searchLocation([String? query, String? placeId]) async {
    final searchQuery = query ?? _searchController.text;
    if (searchQuery.isEmpty && placeId == null) return;

    setState(() => _isSearching = true);
    try {
      if (placeId != null) {
        // Fetch coordinates from Google Places Details API
        final url =
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${ApiConfig.googleMapsApiKey}';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final location = data['result']['geometry']['location'];
            final latLng = LatLng(location['lat'], location['lng']);
            _updateMarker(latLng);
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
            // ignore: use_build_context_synchronously
            FocusScope.of(context).unfocus();
            return;
          }
        }
      }

      // Fallback to geocoding if no placeId or details fetch failed
      List<Location> locations = await locationFromAddress(searchQuery);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        _updateMarker(latLng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        // ignore: use_build_context_synchronously
        FocusScope.of(context).unfocus();
      } else {
        throw Exception('Location not found');
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      // ignore: use_build_context_synchronously
      AppNotifications.showTopSnackBar(context, 'Location not found. Try a more specific address.', isError: true);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _updateMarker,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildCoordField('Latitude', _latController),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCoordField('Longitude', _lngController),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedLocation);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TypeAheadField<Map<String, String>>(
          controller: _searchController,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (_) => _searchLocation(),
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            return await _getSuggestions(pattern);
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.teal),
              title: Text(suggestion['description']!),
            );
          },
          onSelected: (suggestion) {
            _searchController.text = suggestion['description']!;
            _searchLocation(suggestion['description'], suggestion['place_id']);
          },
        ),
      ),
    );
  }

  Widget _buildCoordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.labelGrey),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
