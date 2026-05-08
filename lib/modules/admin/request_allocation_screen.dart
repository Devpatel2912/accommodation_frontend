import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/modules/admin/avdrooms.dart';
import 'package:accommodation/modules/admin/house_manage.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/widgets/app_card.dart';
import '../../presentation/widgets/app_dialog.dart';

class RequestAllocationScreen extends StatefulWidget {
  final AccommodationRequest request;
  const RequestAllocationScreen({super.key, required this.request});

  @override
  State<RequestAllocationScreen> createState() =>
      _RequestAllocationScreenState();
}

class _RequestAllocationScreenState extends State<RequestAllocationScreen> {
  final Set<int> selectedMemberIds = {};
  final Set<int> releasingMemberIds = {};
  String? _selectionSyncKey;

  @override
  void initState() {
    super.initState();
    _syncSelectedMembers(widget.request);
  }

  void _syncSelectedMembers(AccommodationRequest request) {
    final key =
        '${request.id}:${request.activeAllocatedMemberIds.toList()..sort()}';
    if (_selectionSyncKey == key) return;
    selectedMemberIds
      ..clear()
      ..addAll(request.activeAllocatedMemberIds);
    if (selectedMemberIds.isEmpty &&
        request.members.length == 1 &&
        request.members.first.id != null) {
      selectedMemberIds.add(request.members.first.id!);
    }
    _selectionSyncKey = key;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();

    // Always find the freshest version of this request from the viewModel
    final currentRequest = viewModel.requests.firstWhere(
      (r) => r.id == widget.request.id,
      orElse: () => widget.request,
    );
    _syncSelectedMembers(currentRequest);
    final canModifyAllocation = _canModifyAllocation(currentRequest);

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        title: const Text('Manage Allocation'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildRequestHeader(currentRequest),
          if (!canModifyAllocation) _buildLockedAllocationBanner(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'Select Members to Move / Allocate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: currentRequest.members.length,
              itemBuilder: (context, index) {
                final member = currentRequest.members[index];
                final bool isAllocated = currentRequest.activeAllocatedMemberIds
                    .contains(member.id);
                final bool isSelected = selectedMemberIds.contains(member.id);

                return AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.zero,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.teal
                        : AppColors.border.withOpacity(0.5),
                  ),
                  child: InkWell(
                    onTap: !canModifyAllocation
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                selectedMemberIds.remove(member.id);
                              } else {
                                if (member.id != null)
                                  selectedMemberIds.add(member.id!);
                              }
                            });
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.bgGrey,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.labelGrey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      member.contact,
                                      style: const TextStyle(
                                        color: AppColors.labelGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (member.contact.isNotEmpty &&
                                        member.pradesh.isNotEmpty)
                                      const Text(
                                        ' • ',
                                        style: TextStyle(
                                          color: AppColors.labelGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (member.pradesh.isNotEmpty)
                                      Text(
                                        member.pradesh,
                                        style: const TextStyle(
                                          color: AppColors.labelGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                if (member.email.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      member.email,
                                      style: const TextStyle(
                                        color: AppColors.labelGrey,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (isAllocated) ...[
                                  const SizedBox(height: 6),
                                  Builder(
                                    builder: (context) {
                                      final alloc = currentRequest
                                          .findAllocationForMember(member.id);
                                      String locationText = 'Allocated';
                                      if (alloc != null) {
                                        if (alloc.roomNumber != null) {
                                          locationText =
                                              'AVD Room ${alloc.roomNumber}';
                                        } else if (alloc.houseName != null) {
                                          locationText =
                                              'House: ${alloc.houseName}';
                                        }
                                      } else if (currentRequest
                                              .hasDirectHouseBooking &&
                                          currentRequest.houseName != null) {
                                        locationText =
                                            'House: ${currentRequest.houseName}';
                                      }
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.teal.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              size: 10,
                                              color: AppColors.teal,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              locationText,
                                              style: const TextStyle(
                                                color: AppColors.teal,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (alloc != null) ...[
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: canModifyAllocation
                                                    ? () => _releaseMember(
                                                        context,
                                                        viewModel,
                                                        widget.request.id!,
                                                        member.id!,
                                                      )
                                                    : null,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: AppColors.danger,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child:
                                                      releasingMemberIds
                                                          .contains(member.id)
                                                      ? const SizedBox(
                                                          width: 8,
                                                          height: 8,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 1,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons.close,
                                                          size: 8,
                                                          color: Colors.white,
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: canModifyAllocation
                                ? (val) {
                                    setState(() {
                                      if (val == true) {
                                        if (member.id != null) {
                                          selectedMemberIds.add(member.id!);
                                        }
                                      } else {
                                        selectedMemberIds.remove(member.id);
                                      }
                                    });
                                  }
                                : null,
                            activeColor: AppColors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildAllocationOptions(
            context,
            viewModel,
            currentRequest,
            canModifyAllocation: canModifyAllocation,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(AccommodationRequest request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: request.isWaitingForAllocation
                      ? const Color(0xFFFFF3E0)
                      : AppColors.tealLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.isPartiallyAllocated
                      ? 'Partial Pending'
                      : request.isWaitingForAllocation
                      ? request.status
                      : request.allocationStatusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: request.isWaitingForAllocation
                        ? const Color(0xFFE65100)
                        : AppColors.teal,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${request.members.length} Members',
                style: const TextStyle(
                  color: AppColors.labelGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Dates: ${_formatDate(request.checkIn)} - ${_formatDate(request.checkOut)}',
            style: const TextStyle(color: AppColors.labelGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedAllocationBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_rounded, color: Color(0xFFE65100), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Allocation can be changed only before the check-in date.',
              style: TextStyle(
                color: Color(0xFFE65100),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationOptions(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request, {
    required bool canModifyAllocation,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAllocationButton(
                  label: 'Allocate to AVD Room',
                  icon: Icons.meeting_room_rounded,
                  onTap: selectedMemberIds.isEmpty || !canModifyAllocation
                      ? null
                      : () => _allocateToRoom(context, viewModel, request),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAllocationButton(
                  label: 'Allocate to House',
                  icon: Icons.other_houses_rounded,
                  onTap: selectedMemberIds.isEmpty || !canModifyAllocation
                      ? null
                      : () => _allocateToHouse(context, viewModel, request),
                ),
              ),
            ],
          ),
          if (viewModel.isUpdating)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(color: AppColors.teal),
            ),
        ],
      ),
    );
  }

  Widget _buildAllocationButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? AppColors.teal : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(16),
            color: isEnabled
                ? AppColors.tealLight.withOpacity(0.3)
                : AppColors.bgGrey,
          ),
          child: Column(
            children: [
              if (isEnabled && context.watch<UserHomeViewModel>().isUpdating)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.teal,
                  ),
                )
              else ...[
                Icon(
                  icon,
                  color: isEnabled ? AppColors.teal : AppColors.labelGrey,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? AppColors.teal : AppColors.labelGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _allocateToRoom(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request,
  ) async {
    if (!_canModifyAllocation(request)) {
      AppNotifications.showTopSnackBar(
        context,
        'Allocation can be changed only before the check-in date.',
        isError: true,
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AvdRoomsScreen(
          isSelectionMode: true,
          checkIn: request.checkIn,
          checkOut: request.checkOut,
          memberCount: request.members.length,
        ),
      ),
    );

    if (result != null && mounted) {
      final success = await viewModel.syncRequestAllocation(
        request.id,
        memberIds: selectedMemberIds.toList(),
        roomId: result['id'],
      );

      if (success && mounted) {
        AppNotifications.showTopSnackBar(
          context,
          'Selected members allocated successfully!',
        );
      }
    }
  }

  Future<void> _allocateToHouse(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request,
  ) async {
    if (!_canModifyAllocation(request)) {
      AppNotifications.showTopSnackBar(
        context,
        'Allocation can be changed only before the check-in date.',
        isError: true,
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => HouseManageScreen(
          isSelectionMode: true,
          checkIn: request.checkIn,
          checkOut: request.checkOut,
          memberCount: request.members.length,
        ),
      ),
    );

    if (result != null && mounted) {
      final success = await viewModel.syncRequestAllocation(
        request.id,
        memberIds: selectedMemberIds.toList(),
        houseId: result['id'],
      );

      if (success && mounted) {
        AppNotifications.showTopSnackBar(
          context,
          'Selected members allocated successfully!',
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _canModifyAllocation(AccommodationRequest request) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkIn = DateTime(
      request.checkIn.year,
      request.checkIn.month,
      request.checkIn.day,
    );
    return checkIn.isAfter(today);
  }

  Future<void> _releaseMember(
    BuildContext context,
    UserHomeViewModel viewModel,
    int requestId,
    int memberId,
  ) async {
    final currentRequest = context
        .read<UserHomeViewModel>()
        .requests
        .firstWhere((r) => r.id == requestId, orElse: () => widget.request);
    if (!_canModifyAllocation(currentRequest)) {
      AppNotifications.showTopSnackBar(
        context,
        'Allocation can be changed only before the check-in date.',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Release Allocation?',
        message:
            'This will remove the current room assignment for this member.',
        confirmText: 'Release',
        confirmColor: AppColors.danger,
        icon: Icons.close_rounded,
        onConfirm: () async {
          setState(() => releasingMemberIds.add(memberId));
          final success = await viewModel.releaseMemberAllocation(
            requestId,
            memberId,
          );
          if (mounted) {
            setState(() => releasingMemberIds.remove(memberId));
          }
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Allocation released successfully')),
            );
          }
        },
      ),
    );
  }
}
