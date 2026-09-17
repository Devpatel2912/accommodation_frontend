import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/presentation/views/login_view.dart';
import 'package:accommodation/presentation/views/new_request_view.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';

import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';

import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:accommodation/data/datasources/request_remote_datasource.dart';
import 'package:accommodation/data/repositories/request_repository_impl.dart';
import 'package:accommodation/data/datasources/auth_remote_datasource.dart';
import 'package:accommodation/data/repositories/auth_repository_impl.dart';
import 'package:accommodation/domain/usecases/get_my_requests_usecase.dart';
import 'package:accommodation/domain/usecases/cancel_request_usecase.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:accommodation/domain/usecases/get_profile_usecase.dart';
import 'package:accommodation/domain/usecases/forward_to_members_usecase.dart';
import 'package:accommodation/domain/usecases/get_all_requests_usecase.dart';
import 'package:accommodation/domain/usecases/update_admin_request_usecase.dart';
import 'package:accommodation/domain/usecases/allocate_member_usecase.dart';

import 'package:accommodation/domain/usecases/get_available_rooms_usecase.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_card.dart';
import 'package:accommodation/presentation/widgets/app_loading.dart';

import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:accommodation/modules/admin/member_management.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UserHomeScreenContent();
  }
}

class _UserHomeScreenContent extends StatefulWidget {
  const _UserHomeScreenContent();

  @override
  State<_UserHomeScreenContent> createState() => _UserHomeScreenContentState();
}

class _UserHomeScreenContentState extends State<_UserHomeScreenContent> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<UserHomeViewModel>();

    // Listen for real-time notifications
    _notificationSubscription = viewModel.uiNotificationStream.listen((n) {
      if (mounted) {
        AppNotifications.showTopSnackBar(
          context,
          n.message,
          isError: n.isError,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchRequests();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _openNewRequest() async {
    final viewModel = context.read<UserHomeViewModel>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewRequestView()),
    );

    if (result == null) return;
    viewModel.fetchRequests(); // Refresh list from server
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgGrey,
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: _openNewRequest,
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.white,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: AppColors.white,
                  ),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.navy,
            unselectedItemColor: AppColors.labelGrey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0
                        ? AppColors.navy.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedTaskDaily01,
                    color: _currentIndex == 0
                        ? AppColors.navy
                        : AppColors.labelGrey,
                  ),
                ),
                label: 'Request',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1
                        ? AppColors.navy.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    color: _currentIndex == 1
                        ? AppColors.navy
                        : AppColors.labelGrey,
                  ),
                ),
                label: 'Members',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2
                        ? AppColors.navy.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    color: _currentIndex == 2
                        ? AppColors.navy
                        : AppColors.labelGrey,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildRequestList(viewModel),
                const MemberManagementScreen(),
                _buildProfileView(viewModel),
              ],
            ),
          ),
        ),
        if (viewModel.isUpdating)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: AppLoading()),
          ),
      ],
    );
  }

  Widget _buildRequestList(UserHomeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.requests.isEmpty) {
      return const AppLoading(message: 'Loading your requests...');
    }

    return RefreshIndicator(
      onRefresh: viewModel.fetchRequests,
      color: AppColors.teal,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.isAdmin ? 'All Requests' : 'My Requests',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.isAdmin
                              ? 'Overview of all accommodation applications'
                              : 'Track your accommodation applications',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (viewModel.groupedRequests.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedTaskDaily01,
                      size: 64,
                      color: AppColors.labelGrey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.isAdmin
                          ? 'No requests found'
                          : 'No requests yet',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final batch = viewModel.groupedRequests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _GroupedDateSummaryCard(
                      batch: batch,
                      onCancel: () => viewModel.fetchRequests(),
                    ),
                  );
                }, childCount: viewModel.groupedRequests.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileView(UserHomeViewModel viewModel) {
    if (viewModel.isProfileLoading && viewModel.userData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    final name = viewModel.userData?['name'] ?? 'User';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // const SizedBox(height: 16),
          // Text(
          //   viewModel.userData?['name'] ?? 'Loading...',
          //   style: const TextStyle(
          //     fontSize: 22,
          //     fontWeight: FontWeight.w700,
          //     color: AppColors.textDark,
          //   ),
          // ),
          const SizedBox(height: 8),
          const SizedBox(height: 32),
          _buildProfileItem(
            HugeIcons.strokeRoundedUser,
            'Name',
            trailing: viewModel.userData?['name'] ?? 'N/A',
          ),
          _buildProfileItem(
            HugeIcons.strokeRoundedSmartPhone01,
            'Phone Number',
            trailing: viewModel.userData?['phone'] ?? 'N/A',
          ),
          _buildProfileItem(
            HugeIcons.strokeRoundedMail01,
            'Email Address',
            trailing: viewModel.userData?['email'] ?? 'N/A',
          ),
          _buildProfileItem(
            HugeIcons.strokeRoundedShield01,
            'Role',
            trailing: viewModel.userData?['role'] ?? 'N/A',
          ),
          const SizedBox(height: 24),
          _buildProfileItem(
            HugeIcons.strokeRoundedLogout01,
            'Logout',
            isDestructive: true,
            onTap: () async {
              final logout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AppConfirmDialog(
                  title: 'Logout',
                  message: 'Are you sure you want to logout?',
                  confirmText: 'Logout',
                  confirmColor: AppColors.danger,
                  icon: HugeIcons.strokeRoundedLogout01,
                  onConfirm: () async {
                    viewModel.clearData();
                    await Prefs.clear();
                  },
                ),
              );

              if (logout == true && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    dynamic icon,
    String label, {
    String? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? AppColors.danger : AppColors.textDark;
    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              HugeIcon(icon: icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.labelGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        trailing,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ] else if (!isDestructive) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to view',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.hintGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null || trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDestructive
                      ? AppColors.danger.withOpacity(0.5)
                      : AppColors.hintGrey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestDetailsScreen extends StatelessWidget {
  final AccommodationRequest request;

  const RequestDetailsScreen({super.key, required this.request});

  bool get _isProcessedStatus {
    final status = request.status.trim().toUpperCase();
    return status == 'ACCEPTED' || status.startsWith('APPROVED');
  }

  String get _statusDisplayLabel {
    final status = request.status.trim().toUpperCase();
    // Hide internal routing status from users — show PENDING until SubAdmin allocates
    if ((status.startsWith('APPROVED (')) && request.isWaitingForAllocation) {
      return 'PENDING';
    }
    if (_isProcessedStatus && request.hasAnyAllocation) {
      return 'APPROVED';
    }
    return request.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: AppColors.bgGrey,
        elevation: 0,
        title: const Text(
          'Request Details',
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
          if (request.status.trim().toUpperCase() == "PENDING")
            Consumer<UserHomeViewModel>(
              builder: (context, viewModel, child) => IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.teal),
                onPressed: viewModel.isUpdating
                    ? null
                    : () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewRequestView(
                              requestToEdit: request,
                              onUpdate: viewModel.updateMyPendingRequest,
                            ),
                          ),
                        );

                        if (!context.mounted) return;
                        if (updated == true) {
                          Navigator.pop(context, true);
                        }
                      },
              ),
            ),
          if (_isProcessedStatus && request.isFullyAllocated)
            Consumer<UserHomeViewModel>(
              builder: (context, viewModel, child) => viewModel.isForwarding
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.teal,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: AppColors.teal,
                      ),
                      onPressed: () async {
                        final sb = StringBuffer();
                        sb.writeln('Accommodation Request Details');
                        sb.writeln('Status: ${request.status}');
                        sb.writeln('Check-in: ${_formatDate(request.checkIn)}');
                        sb.writeln('Check-out: ${_formatDate(request.checkOut)}');
                        
                        if (request.hasAnyAllocation) {
                          sb.writeln('');
                          sb.writeln('Allocation Status: ${request.allocationStatusLabel}');
                          if (request.hasRoomAllocation) {
                            sb.writeln('Room Number: ${request.activeRoomAllocation?.roomNumber ?? ""}');
                          }
                          if (request.hasHouseAllocation) {
                            sb.writeln('House: ${request.activeHouseDetails?.ownerName ?? ""}');
                          }
                        }
                        
                        sb.writeln('');
                        sb.writeln('Members:');
                        for (final member in request.members) {
                          final allocation = request.findAllocationForMember(member.id);
                          String label = '';
                          if (allocation?.roomNumber != null) {
                            label = ' - Room ${allocation!.roomNumber}';
                          } else if (allocation?.houseName != null) {
                            label = ' - ${allocation!.houseName}';
                          } else if (request.hasDirectHouseBooking && request.houseName != null) {
                            label = ' - ${request.houseName}';
                          }
                          sb.writeln('• ${member.name}$label');
                        }
                        
                        await Share.share(sb.toString());
                      },
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildInfoSection(context),
            if (request.hasAnyAllocation) ...[
              const SizedBox(height: 20),
              _buildAllocationSection(),
            ],
            const SizedBox(height: 20),
            _buildMembersList(),
            if (request.userNotes.isNotEmpty ||
                request.adminNotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildNotesSection(),
            ],
            if ((request.status.trim().toUpperCase() == 'PENDING' &&
                 !request.notes.contains('[SENT_TO_ADMIN]')) ||
                request.status.trim().toUpperCase() == 'CANCELLED' ||
                request.status.trim().toUpperCase() == 'REJECTED') ...[
              const SizedBox(height: 12),
              _buildSendToAdminButton(context),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSendToAdminButton(BuildContext context) {
    return Consumer<UserHomeViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: viewModel.isUpdating ? 'Sending...' : 'Send to Admin',
            icon: Icons.send_rounded,
            isLoading: viewModel.isUpdating,
            onPressed: () async {
              final success = await viewModel.sendToAdmin(request.id);
              if (success && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppSecondaryButton(
        text: 'Cancel Request',
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
        onPressed: () => _showCancelConfirmation(context),
      ),
    );
  }

  Future<void> _showCancelConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Cancel Request?',
        message:
            'Are you sure you want to cancel this accommodation request? This action cannot be undone.',
        confirmText: 'Yes',
        cancelText: 'No, Keep It',
        confirmColor: AppColors.danger,
        icon: Icons.cancel_outlined,
        onConfirm: () async {
          await context.read<UserHomeViewModel>().cancelRequest(request.id);
        },
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context);
      AppNotifications.showTopSnackBar(
        context,
        'Request cancelled successfully',
      );
    }
  }

  Widget _buildStatusCard() {
    final isAllocatedApproved = _isProcessedStatus && request.hasAnyAllocation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAllocatedApproved || _isProcessedStatus
                  ? AppColors.tealLight
                  : AppColors.pendingBg,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isAllocatedApproved || _isProcessedStatus
                    ? AppColors.teal.withOpacity(0.2)
                    : AppColors.pendingBorder,
              ),
            ),
            child: Text(
              _statusDisplayLabel,
              style: TextStyle(
                color: isAllocatedApproved || _isProcessedStatus
                    ? AppColors.teal
                    : AppColors.pendingText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAllocatedApproved
                ? 'Approved'
                : _isProcessedStatus
                ? (request.isWaitingForAllocation
                      ? 'Allocation in Progress'
                      : request.allocationStatusLabel)
                : 'Under Review',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAllocatedApproved
                ? 'Your allocation details are available'
                : _isProcessedStatus
                ? (request.isWaitingForAllocation
                      ? 'Room allocation is pending for this request'
                      : 'Your allocation details are available')
                : 'Management will update the status soon',
            style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Check-in',
            _formatDate(request.checkIn),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          _buildInfoRow(
            Icons.calendar_month_rounded,
            'Check-out',
            _formatDate(request.checkOut),
          ),
          if (request.notifyEmail.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
            _buildInfoRow(
              Icons.mail_outline_rounded,
              'Notify',
              request.notifyEmail,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllocationSection() {
    final house = request.activeHouseDetails;
    final roomAllocation = request.activeRoomAllocation;
    final allocationDate =
        house?.allocationDate ?? roomAllocation?.allocationDate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (house?.imageUrl?.isNotEmpty ?? false) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                house!.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.bgGrey,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.hintGrey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoRow(
            Icons.verified_rounded,
            'Allocation Status',
            request.allocationStatusLabel,
          ),
          if (house?.ownerName?.isNotEmpty ?? false) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
            _buildInfoRow(Icons.home_work_rounded, 'Owner', house!.ownerName!),
          ],
          if (house?.contactNumber?.isNotEmpty ?? false) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
            _buildInfoRow(
              Icons.phone_rounded,
              'Owner Number',
              house!.contactNumber!,
            ),
          ],
          if (house?.address?.isNotEmpty ?? false) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
            _buildInfoRow(
              Icons.location_on_rounded,
              'Owner Address',
              house!.address!,
            ),
          ],
          if (roomAllocation?.roomNumber != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
            _buildInfoRow(
              Icons.meeting_room_rounded,
              'Room Number',
              roomAllocation!.roomNumber!,
            ),
          ],
          if (allocationDate != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
            _buildInfoRow(
              Icons.event_available_rounded,
              'Allocation Date',
              _formatDate(allocationDate),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.labelGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Members',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...request.members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.labelGrey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (member.email.isNotEmpty && member.email != 'N/A')
                          Text(
                            member.email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.teal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Row(
                          children: [
                            if (member.contact.isNotEmpty &&
                                member.contact != 'N/A')
                              Text(
                                member.contact,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.labelGrey,
                                ),
                              ),
                            if (member.contact.isNotEmpty &&
                                member.contact != 'N/A' &&
                                member.pradesh.isNotEmpty)
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.labelGrey,
                                ),
                              ),
                            if (member.pradesh.isNotEmpty)
                              Text(
                                member.pradesh,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.labelGrey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isProcessedStatus)
                    Builder(
                      builder: (context) {
                        final allocation = request.findAllocationForMember(
                          member.id,
                        );
                        final isAllocated =
                            allocation != null || request.hasDirectHouseBooking;

                        String label = 'Room Not Allocated';
                        if (allocation?.roomNumber != null) {
                          label = 'Room ${allocation!.roomNumber}';
                        } else if (allocation?.houseName != null) {
                          label = allocation!.houseName!;
                        } else if (request.hasDirectHouseBooking &&
                            request.houseName != null) {
                          label = request.houseName!;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAllocated
                                ? AppColors.tealLight
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isAllocated
                                  ? AppColors.teal
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request.userNotes.isNotEmpty)
                _buildNoteBlock('User Notes', request.userNotes),
              if (request.userNotes.isNotEmpty && request.adminNotes.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),
              if (request.adminNotes.isNotEmpty)
                _buildNoteBlock('Admin Notes', request.adminNotes),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.labelGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _RequestSummaryCard extends StatelessWidget {
  final AccommodationRequest request;
  final VoidCallback onCancel;

  const _RequestSummaryCard({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = request.status.trim().toUpperCase();
    final isProcessedStatus =
        status == 'ACCEPTED' || status.startsWith('APPROVED');
    // Hide internal routing status from users — show PENDING until SubAdmin allocates
    final isInternalRouting =
        status.startsWith('APPROVED (') && request.isWaitingForAllocation;
    final isAllocatedApproved = isProcessedStatus && request.hasAnyAllocation;
    final statusDisplayLabel = isInternalRouting
        ? 'PENDING'
        : isAllocatedApproved
        ? 'APPROVED'
        : request.status;

    return InkWell(
      onTap: () async {
        final cancelled = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailsScreen(request: request),
          ),
        );

        if (cancelled == true) {
          onCancel();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.labelGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isInternalRouting
                        ? AppColors.pendingBg
                        : isProcessedStatus
                        ? AppColors.tealLight
                        : AppColors.pendingBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isInternalRouting
                          ? AppColors.pendingBorder
                          : isProcessedStatus
                          ? AppColors.teal.withOpacity(0.2)
                          : AppColors.pendingBorder,
                    ),
                  ),
                  child: Text(
                    statusDisplayLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isInternalRouting
                          ? AppColors.pendingText
                          : isProcessedStatus
                          ? AppColors.teal
                          : AppColors.pendingText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: _RequestDateBlock(
                      label: 'CHECK-IN',
                      value: _formatLongDate(request.checkIn),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.labelGrey,
                    ),
                  ),
                  Expanded(
                    child: _RequestDateBlock(
                      label: 'CHECK-OUT',
                      value: _formatLongDate(request.checkOut),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            if (isProcessedStatus &&
                (request.isWaitingForAllocation ||
                    request.isPartiallyAllocated)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pendingBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.pendingBorder.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.pendingText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.isPartiallyAllocated
                            ? 'Some members are still waiting for allocation'
                            : 'Room allocation is pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.pendingText.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatLongDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _RequestDateBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _RequestDateBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.labelGrey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _GroupedDateSummaryCard extends StatelessWidget {
  final GroupedDateBatch batch;
  final VoidCallback onCancel;

  const _GroupedDateSummaryCard({required this.batch, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final cancelled = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GroupedDateDetailsScreen(batch: batch, onCancel: onCancel),
          ),
        );

        if (cancelled == true) {
          onCancel();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.teal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatLongDate(batch.checkIn)} - ${_formatLongDate(batch.checkOut)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${batch.totalMembers} Members • ${batch.requests.length} Requests',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.labelGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.labelGrey),
          ],
        ),
      ),
    );
  }

  static String _formatLongDate(DateTime date) {
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class GroupedDateDetailsScreen extends StatelessWidget {
  final GroupedDateBatch batch;
  final VoidCallback onCancel;

  const GroupedDateDetailsScreen({
    super.key,
    required this.batch,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: AppColors.bgGrey,
        elevation: 0,
        title: Text(
          '${_GroupedDateSummaryCard._formatLongDate(batch.checkIn)} - ${_GroupedDateSummaryCard._formatLongDate(batch.checkOut)}',
          style: const TextStyle(
            fontSize: 16,
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
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: batch.requests.length,
        itemBuilder: (context, index) {
          final request = batch.requests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RequestSummaryCard(request: request, onCancel: onCancel),
          );
        },
      ),
    );
  }
}
