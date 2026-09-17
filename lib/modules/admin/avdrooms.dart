import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/domain/models/room.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/modules/admin/room_management.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class AvdRoomsScreen extends StatefulWidget {
  final bool isSelectionMode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? memberCount;

  final Function(Map<String, dynamic>, BuildContext)? onSelect;

  AvdRoomsScreen({
    super.key,
    this.isSelectionMode = false,
    this.checkIn,
    this.checkOut,
    this.memberCount,
    this.onSelect,
  });

  @override
  State<AvdRoomsScreen> createState() => _AvdRoomsScreenState();
}

class _AvdRoomsScreenState extends State<AvdRoomsScreen> {
  String? get _checkInParam => widget.checkIn?.toIso8601String().split('T')[0];
  String? get _checkOutParam =>
      widget.checkOut?.toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserHomeViewModel>().fetchAvailableRooms(
        checkIn: _checkInParam,
        checkOut: _checkOutParam,
      );
    });
  }

  Future<void> _refreshRooms() {
    return context.read<UserHomeViewModel>().fetchAvailableRooms(
      checkIn: _checkInParam,
      checkOut: _checkOutParam,
    );
  }

  void _showAddRoomDialog() {
    final noCtrl = TextEditingController();
    final capCtrl = TextEditingController();

    AppDialog.show(
      context: context,
      title: 'Add New Room',
      icon: Icons.add_business_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: noCtrl,
            decoration: const InputDecoration(
              labelText: 'Room Number',
              hintText: 'e.g. 305',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: capCtrl,
            decoration: const InputDecoration(
              labelText: 'Capacity (Persons)',
              hintText: 'e.g. 4',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.labelGrey),
          ),
        ),
        SizedBox(
          width: 130,
          child: Consumer<UserHomeViewModel>(
            builder: (context, vm, child) => AppButton(
              text: 'Add Room',
              height: 44,
              isLoading: vm.isUpdating,
              onPressed: () async {
                if (noCtrl.text.isEmpty || capCtrl.text.isEmpty) return;

                final success = await vm.addRoom({
                  'room_number': noCtrl.text,
                  'capacity': int.tryParse(capCtrl.text) ?? 0,
                  'is_active': true,
                });

                if (success && mounted) {
                  Navigator.pop(context);
                  AppNotifications.showTopSnackBar(
                    context,
                    'Room added successfully',
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showEditRoomDialog(dynamic room) {
    final noCtrl = TextEditingController(text: room.roomNumber);
    final capCtrl = TextEditingController(text: room.capacity.toString());

    AppDialog.show(
      context: context,
      title: 'Edit Room ${room.roomNumber}',
      icon: Icons.edit_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: noCtrl,
            decoration: const InputDecoration(labelText: 'Room Number'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: capCtrl,
            decoration: const InputDecoration(labelText: 'Capacity (Persons)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.labelGrey),
          ),
        ),
        SizedBox(
          width: 120,
          child: Consumer<UserHomeViewModel>(
            builder: (context, vm, child) => AppButton(
              text: 'Update',
              height: 44,
              isLoading: vm.isUpdating,
              onPressed: () async {
                final success = await vm.updateRoom(room.id, {
                  'room_number': noCtrl.text,
                  'capacity': int.tryParse(capCtrl.text) ?? 0,
                });

                if (success && mounted) {
                  Navigator.pop(context);
                  AppNotifications.showTopSnackBar(
                    context,
                    'Room updated successfully',
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteRoom(dynamic room) {
    showDialog(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Delete Room',
        message: 'Are you sure you want to delete Room ${room.roomNumber}?',
        confirmText: 'Delete',
        confirmColor: AppColors.danger,
        icon: Icons.delete_forever_rounded,
        onConfirm: () async {
          final viewModel = context.read<UserHomeViewModel>();
          final success = await viewModel.deleteRoom(room.id);
          if (success && mounted) {
            AppNotifications.showTopSnackBar(
              context,
              'Room deleted successfully',
            );
          } else if (mounted) {
            AppNotifications.showTopSnackBar(
              context,
              viewModel.lastRoomError ?? 'Failed to delete room',
              isError: true,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();
    final rooms = viewModel.availableRooms;

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: AppColors.bgGrey,
        elevation: 0,
        title: Text(
          widget.isSelectionMode ? 'Select a Room' : 'AVD Rooms Inventory',
          style: const TextStyle(
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
      ),
      floatingActionButton: widget.isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddRoomDialog,
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Room'),
            ),
      body: viewModel.isLoading && rooms.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : RefreshIndicator(
              onRefresh: _refreshRooms,
              color: AppColors.teal,
              child: CustomScrollView(
                slivers: [
                  if (!widget.isSelectionMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildSummaryGrid(rooms),
                      ),
                    ),
                  if (widget.isSelectionMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: _buildRequestSummary(),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Text(
                        widget.isSelectionMode
                            ? 'Available Rooms'
                            : 'Room Breakdown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  if (rooms.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          widget.isSelectionMode
                              ? 'No rooms available for selected dates'
                              : 'No rooms found in backend',
                          style: const TextStyle(color: AppColors.labelGrey),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final room = rooms[index];
                          final isFull = room.remainingCapacity <= 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.isSelectionMode && !isFull
                                    ? () async {
                                        final roomData = {
                                          'id': room.id,
                                          'no': room.roomNumber,
                                          'capacity': room.capacity.toString(),
                                          'remaining_capacity': room
                                              .remainingCapacity
                                              .toString(),
                                        };

                                        if (widget.onSelect != null) {
                                          await widget.onSelect!(
                                            roomData,
                                            context,
                                          );
                                        } else {
                                          Navigator.pop(context, roomData);
                                        }
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                child: _buildRoomListCard(
                                  room,
                                  room.remainingCapacity > 0
                                      ? AppColors.teal
                                      : AppColors.danger,
                                ),
                              ),
                            ),
                          );
                        }, childCount: rooms.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryGrid(List<Room> rooms) {
    final availableCount = rooms.where((r) => r.remainingCapacity > 0).length;
    final occupiedCount = rooms.where((r) => r.remainingCapacity == 0).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Rooms',
          '${rooms.length}',
          Icons.home_rounded,
          AppColors.textDark,
        ),
        _buildStatCard(
          'Available',
          '$availableCount',
          Icons.check_circle_outline_rounded,
          AppColors.teal,
        ),
        _buildStatCard(
          'Occupied',
          '$occupiedCount',
          Icons.person_outline_rounded,
          AppColors.danger,
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoomManagementScreen()),
            ).then((_) {
              // Refresh available rooms to keep UI in sync
              context.read<UserHomeViewModel>().fetchAvailableRooms();
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: _buildStatCard(
            'Under Maint.',
            'Manage',
            Icons.settings_outlined,
            AppColors.labelGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestSummary() {
    return Container(
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

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.labelGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoomMembersDialog(Room room) {
    AppDialog.show(
      context: context,
      title: 'Room ${room.roomNumber} - Allocated Members',
      icon: Icons.people_alt_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.members.isEmpty)
            const Text(
              'No members are currently allocated to this room.',
              style: TextStyle(color: AppColors.labelGrey),
            )
          else
            ...room.members.map((m) {
              final name = m['name'] ?? 'Unknown';
              final contact = m['contact'] ?? 'No contact';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$name ($contact)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildRoomListCard(Room room, Color statusColor) {
    final String roomNo = room.roomNumber;
    final int rem = room.remainingCapacity;
    final int tot = room.capacity;
    final int occupied = room.currentOccupancy;
    final bool isFull = rem <= 0;

    Color getCapacityColor() {
      if (rem == tot) return const Color(0xFF4CAF50);
      if (rem > 0) return const Color(0xFFFF9800);
      return const Color(0xFFE53935);
    }

    String getStatusText() {
      if (rem == tot) return 'Available';
      if (rem > 0) return 'Partially Filled';
      return 'Full';
    }

    final capacityColor = getCapacityColor();
    final double occupancyPercentage = tot > 0 ? (occupied / tot) : 0.0;

    return InkWell(
      onTap: () {
        if (room.members.isNotEmpty) {
          _showRoomMembersDialog(room);
        } else if (!widget.isSelectionMode) {
          AppNotifications.showTopSnackBar(
            context,
            'No members allocated to this room',
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bed icon in circle
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: capacityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bed_rounded,
                color: capacityColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Right content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Room title + Status pill + 3 dots
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Room $roomNo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: capacityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getStatusText(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: capacityColor,
                          ),
                        ),
                      ),
                      if (!widget.isSelectionMode)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.labelGrey,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ),
                            ],
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showEditRoomDialog(room);
                              } else if (val == 'delete') {
                                _confirmDeleteRoom(room);
                              }
                            },
                          ),
                        )
                      else if (widget.isSelectionMode && !isFull)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            'SELECT',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: Progress bar + percentage
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: occupancyPercentage,
                            backgroundColor: AppColors.border.withOpacity(0.4),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(capacityColor),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(occupancyPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: capacityColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 3: Occupied text
                  Text(
                    '$occupied / $tot Occupied',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.labelGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room, Color statusColor) {
    final String roomNo = room.roomNumber;
    final int rem = room.remainingCapacity;
    final int tot = room.capacity;
    final int occupied = room.currentOccupancy;
    final bool isFull = rem == 0;

    Color getCapacityColor() {
      if (rem == tot) return AppColors.teal; // 100% available
      if (rem > 0) return Colors.orange; // Partially available
      return AppColors.danger; // 0% available
    }

    return InkWell(
      onTap: () {
        if (room.members.isNotEmpty) {
          _showRoomMembersDialog(room);
        } else if (!widget.isSelectionMode) {
          AppNotifications.showTopSnackBar(
            context,
            'No members allocated to this room',
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: getCapacityColor(), width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isFull ? AppColors.danger : AppColors.teal)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Room $roomNo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isFull ? AppColors.danger : AppColors.teal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (!widget.isSelectionMode)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: AppColors.labelGrey,
                    ),
                    padding: EdgeInsets.zero,
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditRoomDialog(room);
                      } else if (val == 'delete') {
                        _confirmDeleteRoom(room);
                      }
                    },
                  ),
                )
              else if (isFull)
                const Icon(
                  Icons.block_flipped,
                  color: AppColors.danger,
                  size: 14,
                )
              else
                const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.teal,
                  size: 14,
                ),
            ],
          ),
          const Spacer(),
          Text(
            isFull ? 'FULL' : 'AVAILABLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isFull ? AppColors.danger : AppColors.teal,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 12,
                  color: AppColors.labelGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '$tot/$rem available${occupied > 0 ? ' | Used: $occupied' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.labelGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isSelectionMode) ...[
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isFull ? AppColors.labelGrey : AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFull ? 'FULL' : 'SELECT',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
      )
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
