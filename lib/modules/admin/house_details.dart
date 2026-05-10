import 'dart:io';
import 'package:accommodation/core/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:accommodation/core/utils/notifications.dart';

class HouseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> house;

  const HouseDetailsScreen({super.key, required this.house});

  Future<void> _launchMap(BuildContext context, double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppNotifications.showTopSnackBar(
          context,
          'Could not open Google Maps',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (house['owner_name'] ?? 'Unknown House').toString();
    final contact = house['contact_number'] ?? house['phone'] ?? 'N/A';
    final address = house['address'] ?? 'No address provided';
    final capacity = house['capacity']?.toString() ?? '0';
    final remaining = house['remaining_capacity']?.toString() ?? capacity;
    final isActive = house['is_active'] == true;
    final imagePath = house['image_url'] ?? '';
    final lat = double.tryParse(house['latitude']?.toString() ?? '0.0') ?? 0.0;
    final lng = double.tryParse(house['longitude']?.toString() ?? '0.0') ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.navy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagePath.isNotEmpty)
                    imagePath.startsWith('http')
                        ? Image.network(imagePath, fit: BoxFit.cover)
                        : Image.file(File(imagePath), fit: BoxFit.cover)
                  else
                    Container(
                      color: AppColors.bgGrey,
                      child: const Icon(Icons.home_work_outlined, size: 80, color: AppColors.border),
                    ),
                  // Gradient overlay for better text visibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.tealLight : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: isActive ? AppColors.teal : AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Contact Information'),
                  _buildDetailCard([
                    _buildDetailRow(Icons.person_outline_rounded, 'Owner', name),
                    _buildDetailRow(Icons.phone_outlined, 'Phone', contact),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Location'),
                  _buildDetailCard([
                    _buildDetailRow(Icons.location_on_outlined, 'Address', address),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMap(context, lat, lng),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View on Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.teal,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.teal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Capacity'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCapacityItem(
                          Icons.group_outlined,
                          'Total Capacity',
                          capacity,
                          AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCapacityItem(
                          Icons.event_available_outlined,
                          'Available',
                          remaining,
                          AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.labelGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.teal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.labelGrey, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
