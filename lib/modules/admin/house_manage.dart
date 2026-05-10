import 'dart:io';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/modules/admin/house_details.dart';
import 'package:accommodation/modules/admin/new_house.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HouseManageScreen extends StatefulWidget {
  final bool isSelectionMode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? memberCount;

  final Function(Map<String, dynamic>, BuildContext)? onSelect;

  HouseManageScreen({
    super.key,
    this.isSelectionMode = false,
    this.checkIn,
    this.checkOut,
    this.memberCount,
    this.onSelect,
  });

  @override
  State<HouseManageScreen> createState() => _HouseManageScreenState();
}

class _HouseManageScreenState extends State<HouseManageScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _houses = [];
  bool _isLoading = true;
  final Set<int> _updatingHouseIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHouses();
    });
  }

  Future<void> _fetchHouses() async {
    setState(() => _isLoading = true);
    final viewModel = Provider.of<UserHomeViewModel>(context, listen: false);

    List<Map<String, dynamic>> results;
    if (widget.isSelectionMode) {
      String? checkInStr = widget.checkIn?.toIso8601String().split('T')[0];
      String? checkOutStr = widget.checkOut?.toIso8601String().split('T')[0];
      results = await viewModel.fetchAvailableHouses(
        checkIn: checkInStr,
        checkOut: checkOutStr,
      );
    } else {
      results = await viewModel.fetchAllHouses();
    }

    setState(() {
      // Sort by id descending to show newest first
      results.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return idB.compareTo(idA);
      });
      _houses = results;
      _isLoading = false;
    });
  }

  void _addNewHouse() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewHouseScreen()),
    );

    if (result == true) {
      _fetchHouses(); // Refresh the list
    }
  }

  void _editHouse(int index) async {
    final house = _houses[index];
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NewHouseScreen(houseToEdit: house)),
    );

    if (result == true) {
      _fetchHouses(); // Refresh the list
    }
  }

  void _deleteHouse(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Delete House',
        message:
            'Are you sure you want to delete "${_houses[index]['owner_name'] ?? 'this house'}"?',
        confirmText: 'Delete',
        confirmColor: AppColors.danger,
        icon: Icons.delete_forever_rounded,
        onConfirm: () async {
          final houseId = _houses[index]['id'];
          if (houseId != null) {
            final success = await context.read<UserHomeViewModel>().deleteHouse(
              houseId,
            );
            if (success) {
              setState(() => _houses.removeAt(index));
              if (mounted) {
                AppNotifications.showTopSnackBar(
                  context,
                  'House deleted successfully',
                );
              }
            } else {
              if (mounted) {
                AppNotifications.showTopSnackBar(
                  context,
                  'Failed to delete house. It might have active bookings.',
                  isError: true,
                );
              }
            }
          }
        },
      ),
    );
  }

  Future<void> _launchMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
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
    final filteredHouses = _houses.where((house) {
      final name = (house['owner_name'] ?? '').toString().toLowerCase();
      final contact = (house['contact_number'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || contact.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'House Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.teal,
              size: 28,
            ),
            onPressed: _addNewHouse,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (widget.isSelectionMode) _buildRequestSummary(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : filteredHouses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.other_houses_outlined,
                          size: 48,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isSelectionMode
                              ? 'No houses available for selected dates'
                              : 'No houses found',
                          style: const TextStyle(
                            color: AppColors.labelGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchHouses,
                    color: AppColors.teal,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredHouses.length,
                      itemBuilder: (context, index) {
                        final house = filteredHouses[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHouseCard(
                            context,
                            id: house['id'],
                            name: house['owner_name'] ?? 'Unknown House',
                            owner: house['contact_number'] ?? 'No contact',
                            address: house['address'] ?? 'No address',
                            tot:
                                int.tryParse(
                                  house['capacity']?.toString() ?? '0',
                                ) ??
                                0,
                            rem:
                                int.tryParse(
                                  house['remaining_capacity']?.toString() ??
                                      house['capacity']?.toString() ??
                                      '0',
                                ) ??
                                0,
                            status: house['is_active'] == true
                                ? 'Active'
                                : 'Inactive',
                            statusColor: house['is_active'] == true
                                ? AppColors.teal
                                : AppColors.danger,
                            imagePath: house['image_url'] ?? '',
                            latitude:
                                double.tryParse(
                                  house['latitude']?.toString() ?? '',
                                ) ??
                                0.0,
                            longitude:
                                double.tryParse(
                                  house['longitude']?.toString() ?? '',
                                ) ??
                                0.0,
                            onEdit: () => _editHouse(index),
                            onDelete: () => _deleteHouse(index),
                            onSelect: () async {
                              if (widget.onSelect != null) {
                                await widget.onSelect!(house, context);
                              } else {
                                Navigator.pop(context, house);
                              }
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HouseDetailsScreen(house: house),
                                ),
                              );
                            },
                            onStatusChanged: (val) async {
                              final houseId = house['id'];
                              if (houseId == null) return;

                              setState(() => _updatingHouseIds.add(houseId));
                              final success = await context
                                  .read<UserHomeViewModel>()
                                  .toggleHouseStatus(houseId, val);
                              setState(() {
                                if (success) {
                                  _houses[index]['is_active'] = val;
                                }
                                _updatingHouseIds.remove(houseId);
                              });
                            },
                            isUpdating: _updatingHouseIds.contains(house['id']),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search by house or owner name...',
            hintStyle: const TextStyle(
              color: AppColors.labelGrey,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.labelGrey,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.labelGrey,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSummaryChip(
              Icons.login_rounded,
              'Check-in',
              _formatDate(widget.checkIn),
            ),
            _buildSummaryChip(
              Icons.logout_rounded,
              'Check-out',
              _formatDate(widget.checkOut),
            ),
            _buildSummaryChip(
              Icons.groups_rounded,
              'Members',
              '${widget.memberCount ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.teal),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.labelGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildHouseCard(
    BuildContext context, {
    required int id,
    required String name,
    required String owner,
    required String address,
    required int tot,
    required int rem,
    required String status,
    required Color statusColor,
    required String imagePath,
    required double latitude,
    required double longitude,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSelect,
    required VoidCallback onTap,
    required Function(bool) onStatusChanged,
    bool isUpdating = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imagePath.isNotEmpty
                      ? (imagePath.startsWith('http')
                          ? Image.network(
                              imagePath,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 200,
                                    color: AppColors.bgGrey,
                                    child: const Icon(
                                      Icons.home_rounded,
                                      size: 40,
                                      color: AppColors.border,
                                    ),
                                  ),
                            )
                          : Image.file(
                              File(imagePath),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 200,
                                    color: AppColors.bgGrey,
                                    child: const Icon(
                                      Icons.home_rounded,
                                      size: 40,
                                      color: AppColors.border,
                                    ),
                                  ),
                            ))
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.bgGrey,
                          child: const Icon(
                            Icons.home_work_outlined,
                            size: 40,
                            color: AppColors.border,
                          ),
                        ),
                ),
              if (!widget.isSelectionMode)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      _buildHeaderAction(
                        icon: Icons.edit_rounded,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderAction(
                        icon: Icons.delete_rounded,
                        onTap: onDelete,
                        isDelete: true,
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    isUpdating
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            ),
                          )
                        : Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: status == 'Active',
                              onChanged: onStatusChanged,
                              activeColor: AppColors.white,
                              activeTrackColor: AppColors.teal,
                              inactiveThumbColor: AppColors.white,
                              inactiveTrackColor: Colors.black26,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'Active'
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: AppColors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toLowerCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner: $owner',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.labelGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.labelGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.group_rounded,
                          size: 18,
                          color: AppColors.labelGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total: $tot | Available: $rem',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                    if (widget.isSelectionMode && status == 'Active')
                      ElevatedButton(
                        onPressed: onSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Assign',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => _launchMap(latitude, longitude),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: AppColors.labelGrey,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'View Map',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.labelGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      )
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDelete ? AppColors.danger : AppColors.navy.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
