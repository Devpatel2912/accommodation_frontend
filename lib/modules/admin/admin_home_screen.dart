import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/presentation/views/login_view.dart';
import 'package:accommodation/presentation/views/new_request_view.dart';
import 'package:accommodation/modules/user/userhomescreen.dart';
import 'package:accommodation/modules/admin/avdrooms.dart';
import 'package:accommodation/modules/admin/house_manage.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:accommodation/data/datasources/request_remote_datasource.dart';
import 'package:accommodation/data/repositories/request_repository_impl.dart';
import 'package:accommodation/data/datasources/auth_remote_datasource.dart';
import 'package:accommodation/data/repositories/auth_repository_impl.dart';
import 'package:accommodation/domain/usecases/get_my_requests_usecase.dart';
import 'package:accommodation/domain/usecases/cancel_request_usecase.dart';
import 'package:accommodation/domain/usecases/get_profile_usecase.dart';
import 'package:accommodation/domain/usecases/forward_to_members_usecase.dart';
import 'package:accommodation/domain/usecases/get_all_requests_usecase.dart';
import 'package:accommodation/domain/usecases/update_admin_request_usecase.dart';
import 'package:accommodation/domain/usecases/allocate_member_usecase.dart';
import 'package:accommodation/domain/usecases/get_available_rooms_usecase.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/modules/admin/request_allocation_screen.dart';
import 'package:accommodation/modules/admin/request_detail_screen.dart';
import 'package:accommodation/modules/admin/user_management.dart';
import 'package:accommodation/modules/admin/member_management.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_card.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:accommodation/presentation/widgets/app_loading.dart';

import '../../core/services/push_notification_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminHomeScreenContent();
  }
}

class _AdminHomeScreenContent extends StatefulWidget {
  const _AdminHomeScreenContent({super.key});

  @override
  State<_AdminHomeScreenContent> createState() =>
      _AdminHomeScreenContentState();
}

class _AdminHomeScreenContentState extends State<_AdminHomeScreenContent> {
  int _currentIndex = 1;

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

    // Fetch once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchRequests();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _addNewRequest() async {
    final viewModel = context.read<UserHomeViewModel>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewRequestView()),
    );
    if (result != null) {
      viewModel.fetchRequests();
      AppNotifications.showTopSnackBar(
        context,
        'New request added successfully!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgGrey,
          floatingActionButton:
              _currentIndex ==
                  1 // Request tab
              ? FloatingActionButton(
                  onPressed: _addNewRequest,
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
                    icon: HugeIcons.strokeRoundedHome01,
                    color: _currentIndex == 0
                        ? AppColors.navy
                        : AppColors.labelGrey,
                  ),
                ),
                label: 'Home',
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
                    icon: HugeIcons.strokeRoundedTaskDaily01,
                    color: _currentIndex == 1
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
                _buildUsersList(),
                _buildAllRequests(viewModel),
                _buildAdminProfile(viewModel),
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

  Widget _buildUsersList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification01,
                        color: AppColors.teal,
                      ),
                      onPressed: () {
                        PushNotificationService().triggerNotification(
                          topic: 'admins',
                          title: 'Test Notification',
                          body: 'If you see this, FCM is working perfectly!',
                        );
                        AppNotifications.showTopSnackBar(
                          context,
                          'Test notification sent to "admins" topic',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage users and their requests.',
                  style: TextStyle(fontSize: 14, color: AppColors.labelGrey),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildGridItem(
                title: 'Manage Room',
                icon: HugeIcons.strokeRoundedBed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AvdRoomsScreen()),
                ),
              ),
              _buildGridItem(
                title: 'Manage House',
                icon: HugeIcons.strokeRoundedHome03,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HouseManageScreen()),
                ),
              ),
              _buildGridItem(
                title: 'Manage User',
                icon: HugeIcons.strokeRoundedUserGroup,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                ),
              ),
              _buildGridItem(
                title: 'Manage Member',
                icon: HugeIcons.strokeRoundedUserMultiple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemberManagementScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required String title,
    // required String subtitle,
    required dynamic icon,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tealLight.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: icon, color: AppColors.teal, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   subtitle,
              //   textAlign: TextAlign.center,
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              //   style: const TextStyle(
              //     color: AppColors.labelGrey,
              //     fontSize: 11,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProfile(UserHomeViewModel viewModel) {
    if (viewModel.isProfileLoading && viewModel.userData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    final name = viewModel.userData?['name'] ?? 'Admin User';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            viewModel.userData?['name'] ?? 'Administrator',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildAllRequests(UserHomeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.bgGrey,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (val) => viewModel.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: const TextStyle(
                          color: AppColors.hintGrey,
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: AppColors.labelGrey.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(viewModel),
              ],
            ),
          ),
          if (viewModel.filterPradesh != null ||
              viewModel.filterStartDate != null)
            _buildActiveFiltersRow(viewModel),
          const TabBar(
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.labelGrey,
            indicatorColor: AppColors.teal,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'New Requests'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredRequestList(viewModel, isHistory: false),
                _buildFilteredRequestList(viewModel, isHistory: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredRequestList(
    UserHomeViewModel viewModel, {
    required bool isHistory,
  }) {
    List<AccommodationRequest> displayList;
    final query = viewModel.searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      displayList = viewModel.requests.where((r) {
        final status = r.status.trim().toUpperCase();
        final notes = (r.notes ?? "").toUpperCase();
        if (status == 'DELETED' || notes.contains('[DELETED]')) return false;

        // Apply filters even in search
        if (viewModel.filterPradesh != null) {
          if (!r.members.any((m) => m.pradesh == viewModel.filterPradesh))
            return false;
        }
        if (viewModel.filterStartDate != null &&
            viewModel.filterEndDate != null) {
          if (r.checkIn.isBefore(viewModel.filterStartDate!) ||
              r.checkOut.isAfter(viewModel.filterEndDate!))
            return false;
        }

        final matchesName = r.members.any(
          (m) => m.name.toLowerCase().contains(query),
        );
        final matchesId = r.id.toString().contains(query);
        final matchesStatus = r.status.toLowerCase().contains(query);
        return matchesName || matchesId || matchesStatus;
      }).toList();
    } else {
      displayList = viewModel.requests.where((r) {
        final status = r.status.trim().toUpperCase();
        final notes = (r.notes ?? "").toUpperCase();
        if (status == 'DELETED' || notes.contains('[DELETED]'))
          return false; // Hide if status is DELETED or notes contain [DELETED]

        // Apply Pradesh filter
        if (viewModel.filterPradesh != null) {
          if (!r.members.any((m) => m.pradesh == viewModel.filterPradesh))
            return false;
        }

        // Apply Date filter (Find requests fully within range)
        if (viewModel.filterStartDate != null &&
            viewModel.filterEndDate != null) {
          if (r.checkIn.isBefore(viewModel.filterStartDate!) ||
              r.checkOut.isAfter(viewModel.filterEndDate!))
            return false;
        }

        bool show;
        if (isHistory) {
          show =
              r.isFullyAllocated ||
              status == 'REJECTED' ||
              status == 'CANCELLED' ||
              ((status == 'ACCEPTED' || status == 'APPROVED') &&
                  r.isFullyAllocated);
        } else {
          show =
              !r.isFullyAllocated &&
              status != 'REJECTED' &&
              status != 'CANCELLED';
        }

        if (status == 'PENDING') {
          print(
            "DEBUG: Request ${r.id} status is PENDING. isHistory: $isHistory, show: $show",
          );
        }

        return show;
      }).toList();
    }

    return _buildRequestList(
      viewModel,
      displayList,
      query.isEmpty
          ? (isHistory ? 'No historical requests' : 'No new requests')
          : 'No matches found',
      isHistory: isHistory,
    );
  }

  Widget _buildRequestList(
    UserHomeViewModel viewModel,
    List<AccommodationRequest> list,
    String emptyMsg, {
    required bool isHistory,
  }) {
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
                      Icons.assignment_late_outlined,
                      size: 64,
                      color: AppColors.labelGrey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyMsg,
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
                    child: AdminRequestCard(
                      request: request,
                      parentContext: context,
                      isHistory: isHistory,
                      onDelete: () async {
                        showDialog(
                          context: context,
                          builder: (ctx) => AppConfirmDialog(
                            title: 'Delete Request',
                            message: 'Are you sure you want to delete this request?',
                            confirmText: 'Delete',
                            confirmColor: AppColors.danger,
                            icon: HugeIcons.strokeRoundedDelete01,
                            onConfirm: () async {
                              final success = await viewModel.cancelRequest(
                                request.id,
                              );
                              if (success && context.mounted) {
                                AppNotifications.showTopSnackBar(
                                  context,
                                  'Request deleted',
                                  isError: true,
                                );
                              }
                            },
                          ),
                        );
                      },
                      onUpdate: (updatedRequest) async {
                        final success = await viewModel.updateRequestStatus(
                          request.id,
                          requestName: updatedRequest.requestName,
                          status: updatedRequest.status,
                          notes: updatedRequest.notes,
                          checkIn: updatedRequest.checkIn,
                          checkOut: updatedRequest.checkOut,
                          members: updatedRequest.members,
                        );
                        return success;
                      },
                    ),
                  );
                }, childCount: list.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(UserHomeViewModel viewModel) {
    final hasFilters =
        viewModel.filterPradesh != null || viewModel.filterStartDate != null;
    return Container(
      decoration: BoxDecoration(
        color: hasFilters ? AppColors.teal : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFilters ? AppColors.teal : AppColors.border,
        ),
      ),
      child: IconButton(
        onPressed: () => _showFilterDialog(viewModel),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedFilter,
          color: hasFilters ? AppColors.white : AppColors.teal,
          size: 20,
        ),
        tooltip: 'Filter Requests',
      ),
    );
  }

  Widget _buildActiveFiltersRow(UserHomeViewModel viewModel) {
    final filteredCount = viewModel.requests.where((r) {
      final status = r.status.trim().toUpperCase();
      final notes = (r.notes ?? "").toUpperCase();
      if (status == 'DELETED' || notes.contains('[DELETED]')) return false;

      if (viewModel.filterPradesh != null) {
        if (!r.members.any((m) => m.pradesh == viewModel.filterPradesh))
          return false;
      }
      if (viewModel.filterStartDate != null &&
          viewModel.filterEndDate != null) {
        if (r.checkIn.isBefore(viewModel.filterStartDate!) ||
            r.checkOut.isAfter(viewModel.filterEndDate!))
          return false;
      }
      return true;
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppColors.bgGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (viewModel.filterPradesh != null)
                  _buildFilterChip(
                    'Pradesh: ${viewModel.filterPradesh}',
                    () => viewModel.setFilterPradesh(null),
                  ),
                if (viewModel.filterStartDate != null)
                  _buildFilterChip(
                    'Dates: ${viewModel.filterStartDate!.day}/${viewModel.filterStartDate!.month} - ${viewModel.filterEndDate!.day}/${viewModel.filterEndDate!.month}',
                    () => viewModel.setFilterDates(null, null),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$filteredCount result${filteredCount == 1 ? '' : 's'} found',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.labelGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: viewModel.clearFilters,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeleted,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: 14,
              color: AppColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(UserHomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        String? tempPradesh = viewModel.filterPradesh;
        DateTime? tempStart = viewModel.filterStartDate;
        DateTime? tempEnd = viewModel.filterEndDate;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Filter Requests',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pradesh',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempPradesh,
                        hint: const Text('Select Pradesh'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Pradesh'),
                          ),
                          ...viewModel.availablePradeshFilters.map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => tempPradesh = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2027),
                              initialDateRange:
                                  tempStart != null && tempEnd != null
                                  ? DateTimeRange(
                                      start: tempStart!,
                                      end: tempEnd!,
                                    )
                                  : null,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                tempStart = picked.start;
                                tempEnd = picked.end;
                              });
                            }
                          },
                          child: Text(
                            tempStart == null
                                ? 'Select Dates'
                                : '${tempStart!.day}/${tempStart!.month} - ${tempEnd!.day}/${tempEnd!.month}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    viewModel.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    viewModel.setFilterPradesh(tempPradesh);
                    viewModel.setFilterDates(tempStart, tempEnd);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, String> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.tealLight,
            child: Text(
              user['initials']!,
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  user['email']!,
                  style: const TextStyle(
                    color: AppColors.labelGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user['role']!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.labelGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminRequestCard extends StatefulWidget {
  final AccommodationRequest request;
  final VoidCallback onDelete;
  final Future<bool> Function(AccommodationRequest) onUpdate;
  final BuildContext parentContext;
  final bool isHistory;

  const AdminRequestCard({
    super.key,
    required this.request,
    required this.onDelete,
    required this.onUpdate,
    required this.parentContext,
    this.isHistory = false,
  });

  @override
  State<AdminRequestCard> createState() => _AdminRequestCardState();
}

class _AdminRequestCardState extends State<AdminRequestCard> {
  bool _isExpanded = false;

  void _showMemberDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Request Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.request.members.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 10, color: AppColors.border),
                itemBuilder: (context, index) {
                  final m = widget.request.members[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _detailRow(
                        HugeIcons.strokeRoundedCall02,
                        m.contact,
                        onTap: () async {
                          final cleanPhone = m.contact.replaceAll(
                            RegExp(r'[^0-9+]'),
                            '',
                          );
                          final uri = Uri.parse('tel:$cleanPhone');
                          try {
                            await launchUrl(uri);
                          } catch (e) {
                            debugPrint('Could not launch call: $e');
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedCall02,
                                size: 18,
                                color: AppColors.teal,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final cleanPhone = m.contact.replaceAll(
                                  RegExp(r'[^0-9+]'),
                                  '',
                                );
                                final uri = Uri.parse('tel:$cleanPhone');
                                try {
                                  await launchUrl(uri);
                                } catch (e) {
                                  debugPrint('Could not launch call: $e');
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedChat01,
                                size: 18,
                                color: Colors.green,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final cleanPhone = m.contact.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                final uri = Uri.parse(
                                  'https://wa.me/$cleanPhone',
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      _detailRow(
                        HugeIcons.strokeRoundedMail01,
                        m.email,
                        trailing: IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCopy01,
                            size: 16,
                            color: AppColors.labelGrey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: m.email));
                            AppNotifications.showTopSnackBar(
                              context,
                              'Email copied to clipboard',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                      _detailRow(
                        HugeIcons.strokeRoundedLocation01,
                        'Pradesh: ${m.pradesh}',
                      ),
                      Builder(
                        builder: (context) {
                          final alloc = widget.request.findAllocationForMember(
                            m.id,
                          );
                          if (alloc != null) {
                            String allocationText = 'Allocated';
                            dynamic allocIcon =
                                HugeIcons.strokeRoundedCheckmarkCircle01;

                            if (alloc.roomNumber != null) {
                              allocationText = 'Room: ${alloc.roomNumber}';
                              allocIcon = HugeIcons.strokeRoundedDoor01;
                            } else if (alloc.houseDetails != null) {
                              allocationText =
                                  'House: ${alloc.houseDetails!.ownerName}';
                              allocIcon = HugeIcons.strokeRoundedHome01;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: _detailRow(
                                allocIcon,
                                'Allocation: $allocationText',
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    dynamic iconData,
    String value, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Row(
      children: [
        HugeIcon(icon: iconData, size: 16, color: AppColors.labelGrey),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                decoration: onTap != null ? TextDecoration.underline : null,
                decorationColor: AppColors.teal.withOpacity(0.5),
              ),
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();
    final bool isBusy = viewModel.isUpdating;
    final request = widget.request;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(
              requestId: request.id ?? 0,
              initialRequest: request,
              isHistory: widget.isHistory,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                Row(
                  children: [
                    if (!widget.isHistory)
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedEdit01,
                          color: AppColors.teal,
                          size: 20,
                        ),
                        onPressed: isBusy ? null : () => _handleUpdate(context),
                      ),
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete01,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      onPressed: isBusy ? null : widget.onDelete,
                    ),
                  ],
                ),
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
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ),
            if (request.status.contains('(') || request.hasAnyAllocation) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  HugeIcon(
                    icon: request.hasRoomAllocation
                        ? HugeIcons.strokeRoundedDoor01
                        : (request.hasHouseAllocation
                              ? HugeIcons.strokeRoundedHome01
                              : HugeIcons.strokeRoundedLocation01),
                    size: 14,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.hasRoomAllocation
                          ? 'Room: ${request.activeRoomAllocation?.roomNumber ?? ''}'
                          : (request.hasHouseAllocation
                                ? 'House: ${request.activeHouseDetails?.ownerName ?? ''}'
                                : 'Location: ${_extractLocation(request.status)}'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes: ${request.notes}',
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.labelGrey,
                          ),
                        ),
                        if (request.notes.length > 50)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _isExpanded ? 'less' : 'more',
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (!widget.isHistory) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Approve',
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      color: AppColors.teal,
                      onTap: () => _showApproveOptions(context),
                      isActive:
                          widget.request.status.trim().toUpperCase() ==
                              'PENDING' &&
                          !isBusy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'Reject',
                      icon: HugeIcons.strokeRoundedCancelCircle,
                      color: AppColors.danger,
                      onTap: () => _handleReject(context),
                      isActive:
                          widget.request.status.trim().toUpperCase() ==
                              'PENDING' &&
                          !isBusy,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAllocation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestAllocationScreen(request: widget.request),
      ),
    );
  }

  String _extractLocation(String status) {
    if (status.contains('(') && status.contains(')')) {
      return status.split('(').last.replaceAll(')', '');
    }
    return '';
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;

    final String statusUpper = widget.request.status.trim().toUpperCase();
    bool isApproved =
        statusUpper == 'APPROVED' ||
        statusUpper.startsWith('APPROVED') ||
        statusUpper == 'ACCEPTED';

    String label = isApproved && widget.request.hasAnyAllocation
        ? 'APPROVED'
        : (widget.request.status.trim().isEmpty
              ? 'PENDING'
              : widget.request.status);

    if (isApproved) {
      bgColor = AppColors.tealLight;
      textColor = AppColors.teal;
    } else if (statusUpper == 'REJECTED') {
      bgColor = AppColors.danger.withOpacity(0.1);
      textColor = AppColors.danger;
      label = 'REJECTED';
    } else {
      bgColor = AppColors.pendingBg;
      textColor = AppColors.pendingText;
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

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: isActive ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? color.withOpacity(0.5) : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isActive ? color.withOpacity(0.05) : AppColors.bgGrey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 16,
                color: isActive ? color : AppColors.labelGrey,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? color : AppColors.labelGrey,
                  ),
                ),
              ),
              if (isActive && context.read<UserHomeViewModel>().isUpdating) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Approval Authority',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Approve and forward to the responsible SubAdmin',
                style: TextStyle(fontSize: 14, color: AppColors.labelGrey),
              ),
              const SizedBox(height: 20),
              _buildApprovalSummary(),
              const SizedBox(height: 24),
              _buildOptionTile(
                context,
                label: 'Forward to AVD (Room Allocation)',
                subtitle: 'SubAdmin AVD will allocate rooms for members',
                icon: Icons.business_rounded,
                onTap: () async {
                  Navigator.of(context).pop(); // Close bottom sheet
                  final viewModel = widget.parentContext
                      .read<UserHomeViewModel>();

                  // Only update the status — no allocation at this step
                  final success = await _updateStatus('APPROVED (AVD)');
                  if (success && widget.parentContext.mounted) {
                    AppNotifications.showTopSnackBar(
                      widget.parentContext,
                      'Request approved and forwarded to SubAdmin (AVD) for room allocation.',
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                context,
                label: 'Forward to Anand (House Allocation)',
                subtitle:
                    'SubAdmin Anand will allocate a house for this request',
                icon: Icons.home_work_rounded,
                onTap: () async {
                  Navigator.of(context).pop(); // Close bottom sheet
                  final viewModel = widget.parentContext
                      .read<UserHomeViewModel>();

                  // Only update the status — no allocation at this step
                  final success = await _updateStatus('APPROVED (ANAND)');
                  if (success && widget.parentContext.mounted) {
                    AppNotifications.showTopSnackBar(
                      widget.parentContext,
                      'Request approved and forwarded to SubAdmin (Anand) for house allocation.',
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildApprovalSummaryItem(
            Icons.login_rounded,
            'Check-in',
            _formatDate(widget.request.checkIn),
          ),
          _buildApprovalSummaryItem(
            Icons.logout_rounded,
            'Check-out',
            _formatDate(widget.request.checkOut),
          ),
          _buildApprovalSummaryItem(
            Icons.groups_rounded,
            'Members',
            '${widget.request.members.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSummaryItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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

  Widget _buildOptionTile(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.teal, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.labelGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.labelGrey,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>?> _showMemberSelectionDialog(
    BuildContext context,
    List<AddedMember> members, {
    required int roomCapacity,
    required String roomNo,
  }) {
    List<int> selectedIds = [];
    print("DEBUG: Calling showDialog for Member Selection");

    return AppDialog.show<List<int>>(
      context: context,
      title: 'Select Members',
      icon: Icons.groups_rounded,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final bool isOverCapacity = selectedIds.length > roomCapacity;

          return SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOverCapacity)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Room capacity is $roomCapacity. You can only allocate $roomCapacity members.',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final bool isSelected = selectedIds.contains(member.id);
                      return CheckboxListTile(
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          member.contact,
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: isSelected,
                        activeColor: AppColors.teal,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedIds.add(member.id!);
                            } else {
                              selectedIds.remove(member.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.labelGrey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: AppButton(
                        text: 'Allocate Selected',
                        height: 44,
                        borderRadius: 12,
                        onPressed:
                            selectedIds.isEmpty ||
                                selectedIds.length > roomCapacity
                            ? null
                            : () => Navigator.pop(context, selectedIds),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: content,
        confirmText: 'Yes',
        cancelText: 'No',
        icon: Icons.check_circle_outline_rounded,
        onConfirm: () async {}, // Handled by showDialog result if needed
      ),
    ).then((val) => val); // Ensure it returns bool
  }

  Future<bool> _updateStatus(String newStatus, {String? customNotes}) async {
    String dbStatus = newStatus;
    String adminNotes = customNotes ?? 'Status updated to $newStatus';

    // Map custom display statuses to valid DB ENUM values
    if (newStatus.startsWith('APPROVED')) {
      dbStatus = 'ACCEPTED';
      adminNotes = customNotes ?? 'Approved: $newStatus';
    } else if (newStatus == 'REJECTED') {
      dbStatus = 'CANCELLED';
      adminNotes = customNotes == null || customNotes.trim().isEmpty
          ? 'Rejected'
          : 'Rejected: ${customNotes.trim()}';
    }

    final finalNotes = AccommodationRequest.composeNotes(
      userNotes: widget.request.userNotes,
      adminNotes: adminNotes,
    );

    return await widget.onUpdate(
      AccommodationRequest(
        id: widget.request.id,
        requestName: widget.request.requestName,
        status: dbStatus,
        notes: finalNotes,
        checkIn: widget.request.checkIn,
        checkOut: widget.request.checkOut,
        members: widget.request.members,
        notifyEmail: widget.request.notifyEmail,
      ),
    );
  }

  void _handleReject(BuildContext context) async {
    final TextEditingController noteController = TextEditingController();

    final result = await AppDialog.show<Map<String, dynamic>>(
      context: context,
      title: 'Reject Request?',
      icon: Icons.cancel_outlined,
      iconColor: AppColors.danger,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please provide a reason for rejection. This will be sent to the user via email.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.labelGrey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter rejection reason...',
              filled: true,
              fillColor: AppColors.bgGrey,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.danger,
                  width: 1.5,
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.labelGrey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 4),
        AppButton(
          text: 'Reject Now',
          color: AppColors.danger,
          height: 40,
          width: 110,
          borderRadius: 12,
          onPressed: () {
            if (noteController.text.trim().isEmpty) {
              AppNotifications.showTopSnackBar(
                context,
                'Please enter a rejection reason',
                isError: true,
              );
              return;
            }
            Navigator.pop(context, {
              'confirmed': true,
              'note': noteController.text,
            });
          },
        ),
      ],
    );

    if (result != null && result['confirmed'] == true) {
      final success = await _updateStatus(
        'REJECTED',
        customNotes: result['note'],
      );
      if (success && context.mounted) {
        AppNotifications.showTopSnackBar(
          context,
          'Request Rejected Successfully',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleUpdate(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRequestView(
          requestToEdit: widget.request,
          onUpdate: widget.onUpdate,
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
