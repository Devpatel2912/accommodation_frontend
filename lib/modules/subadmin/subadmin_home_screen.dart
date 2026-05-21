import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/presentation/views/login_view.dart';
import 'package:accommodation/modules/admin/avdrooms.dart';
import 'package:accommodation/modules/admin/house_manage.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_card.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:accommodation/presentation/widgets/app_loading.dart';
import 'package:accommodation/modules/admin/request_allocation_screen.dart';

class SubAdminHomeScreen extends StatelessWidget {
  const SubAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SubAdminHomeScreenContent();
  }
}

class _SubAdminHomeScreenContent extends StatefulWidget {
  const _SubAdminHomeScreenContent();

  @override
  State<_SubAdminHomeScreenContent> createState() =>
      _SubAdminHomeScreenContentState();
}

class _SubAdminHomeScreenContentState
    extends State<_SubAdminHomeScreenContent> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<UserHomeViewModel>();

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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgGrey,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.navy,
            unselectedItemColor: AppColors.labelGrey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
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
                label: 'Requests',
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
                    icon: HugeIcons.strokeRoundedUser,
                    color: _currentIndex == 1
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
                _buildApprovedRequests(viewModel),
                _buildProfile(viewModel),
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

  Widget _buildApprovedRequests(UserHomeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    final subAdminType = viewModel.subAdminType ?? 'UNKNOWN';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.bgGrey,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SubAdmin ($subAdminType)',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const TabBar(
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.labelGrey,
            indicatorColor: AppColors.teal,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pending Allocation'),
              Tab(text: 'Allocated'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRequestList(viewModel, isAllocated: false),
                _buildRequestList(viewModel, isAllocated: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(
    UserHomeViewModel viewModel, {
    required bool isAllocated,
  }) {
    final list = viewModel.requests.where((r) {
      final status = r.status.trim().toUpperCase();
      if (status == 'DELETED') return false;

      if (isAllocated) {
        return r.isFullyAllocated;
      } else {
        return !r.isFullyAllocated &&
            status != 'REJECTED' &&
            status != 'CANCELLED';
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: viewModel.fetchRequests,
      color: AppColors.teal,
      child: CustomScrollView(
        slivers: [
          if (list.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAllocated
                          ? Icons.check_circle_outline
                          : Icons.assignment_late_outlined,
                      size: 64,
                      color: AppColors.labelGrey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAllocated
                          ? 'No allocated requests yet'
                          : 'No pending allocations',
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
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final request = list[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SubAdminRequestCard(
                      request: request,
                      subAdminType: viewModel.subAdminType ?? '',
                      onAllocate: () => _openAllocation(context, request),
                    ),
                  );
                }, childCount: list.length),
              ),
            ),
        ],
      ),
    );
  }

  void _openAllocation(BuildContext context, AccommodationRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestAllocationScreen(request: request),
      ),
    ).then((_) {
      // Refresh after coming back from allocation
      context.read<UserHomeViewModel>().fetchRequests();
    });
  }

  Widget _buildProfile(UserHomeViewModel viewModel) {
    if (viewModel.isProfileLoading && viewModel.userData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.teal.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                (viewModel.userData?['name'] ?? 'S')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            viewModel.userData?['name'] ?? 'SubAdmin',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SubAdmin (${viewModel.subAdminType ?? ""})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.teal,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileItem(
            HugeIcons.strokeRoundedUser,
            'Full Name',
            trailing: viewModel.userData?['name'] ?? 'N/A',
          ),
          _buildProfileItem(
            HugeIcons.strokeRoundedMail01,
            'Email Address',
            trailing: viewModel.userData?['email'] ?? 'N/A',
          ),
          _buildProfileItem(
            HugeIcons.strokeRoundedShield01,
            'Role',
            trailing: 'SubAdmin (${viewModel.subAdminType ?? "N/A"})',
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
                    ],
                  ],
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.border,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for SubAdmin showing approved request with allocation button
class _SubAdminRequestCard extends StatelessWidget {
  final AccommodationRequest request;
  final String subAdminType;
  final VoidCallback onAllocate;

  const _SubAdminRequestCard({
    required this.request,
    required this.subAdminType,
    required this.onAllocate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.subtitle,
            style: const TextStyle(
              color: AppColors.labelGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                size: 14,
                color: AppColors.teal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatDate(request.checkIn)} - ${_formatDate(request.checkOut)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (request.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 15,
                  color: AppColors.labelGrey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notes: ${request.notes}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.labelGrey,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Show member info
          const SizedBox(height: 8),
          _buildMemberChips(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          if (!request.isFullyAllocated)
            SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: onAllocate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.teal.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.teal.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        size: 16,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subAdminType == 'AVD'
                            ? 'Allocate Room'
                            : 'Allocate House',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.tealLight.withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'APPROVED',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: onAllocate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.teal.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.teal.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSlidersHorizontal,
                            size: 16,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMemberChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: request.members.map((m) {
        final isAllocated = request.activeAllocatedMemberIds.contains(m.id);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isAllocated
                ? AppColors.teal.withOpacity(0.1)
                : AppColors.bgGrey,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isAllocated
                  ? AppColors.teal.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAllocated)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 10,
                    color: AppColors.teal,
                  ),
                ),
              Text(
                m.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isAllocated ? AppColors.teal : AppColors.labelGrey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;

    if (request.isFullyAllocated) {
      bgColor = AppColors.tealLight;
      textColor = AppColors.teal;
      label = 'APPROVED';
    } else if (request.isPartiallyAllocated) {
      bgColor = AppColors.tealLight;
      textColor = AppColors.teal;
      label = 'APPROVED';
    } else {
      bgColor = AppColors.pendingBg;
      textColor = AppColors.pendingText;
      label = 'Awaiting Allocation';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
