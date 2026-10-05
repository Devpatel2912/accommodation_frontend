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
    final lat = double.tryParse(house['latitude']?.toString() ?? '0.0') ?? 0.0;
    final lng = double.tryParse(house['longitude']?.toString() ?? '0.0') ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFEB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0C4C51),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 24, top: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                              const SizedBox(height: 8),
                              Text(capacity, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('Total', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(width: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                              const SizedBox(height: 8),
                              Text(remaining, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const Text('Available', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0C4C51),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF0C4C51) : AppColors.danger,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.check_circle_outline : Icons.error_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('CONTACT INFORMATION'),
                  _buildDetailCard([
                    _buildDetailRow(Icons.person_outline_rounded, 'Owner', name),
                    Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Divider(color: AppColors.border.withOpacity(0.5), height: 1),
                    ),
                    _buildDetailRow(Icons.phone_outlined, 'Phone', contact),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('LOCATION'),
                  _buildDetailCard([
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C4C51).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF0C4C51)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Address', style: TextStyle(fontSize: 12, color: AppColors.labelGrey, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(address, style: const TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMap(context, lat, lng),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('View on Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0C4C51),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF0C4C51)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('CAPACITY'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCapacityItem(
                          Icons.person_outline_rounded,
                          'Total Capacity',
                          capacity,
                          const Color(0xFF0C4C51),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCapacityItem(
                          Icons.event_available_outlined,
                          'Available',
                          remaining,
                          const Color(0xFF0C4C51),
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
          fontSize: 13,
          fontWeight: FontWeight.w800,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C4C51).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0C4C51)),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w700,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
