import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/views/new_request_view.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_card.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:accommodation/presentation/widgets/app_loading.dart';

class RequestDetailScreen extends StatefulWidget {
  final int requestId;
  final AccommodationRequest initialRequest;
  final bool isHistory;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.initialRequest,
    required this.isHistory,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isBusy = false;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _handleDelete(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Delete Request?',
        message: 'Are you sure you want to permanently delete this request?',
        confirmText: 'Delete',
        confirmColor: AppColors.danger,
        icon: HugeIcons.strokeRoundedDelete01,
        onConfirm: () async {},
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isBusy = true);
      final success = await viewModel.cancelRequest(request.id);
      if (mounted) {
        setState(() => _isBusy = false);
        if (success) {
          Navigator.pop(context); // Go back to Home
          AppNotifications.showTopSnackBar(
            context,
            'Request deleted successfully',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _handleEdit(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewRequestView(
          requestToEdit: request,
          onUpdate: (updatedRequest) async {
            return await viewModel.updateRequestStatus(
              request.id,
              requestName: updatedRequest.requestName,
              status: updatedRequest.status,
              notes: updatedRequest.notes,
              checkIn: updatedRequest.checkIn,
              checkOut: updatedRequest.checkOut,
              members: updatedRequest.members,
            );
          },
        ),
      ),
    );
  }

  Future<bool> _updateStatus(
    UserHomeViewModel viewModel,
    AccommodationRequest request,
    String newStatus, {
    String? customNotes,
  }) async {
    String dbStatus = newStatus;
    String adminNotes = customNotes ?? 'Status updated to $newStatus';

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
      userNotes: request.userNotes,
      adminNotes: adminNotes,
    );

    setState(() => _isBusy = true);
    final success = await viewModel.updateRequestStatus(
      request.id,
      requestName: request.requestName,
      status: dbStatus,
      notes: finalNotes,
      checkIn: request.checkIn,
      checkOut: request.checkOut,
      members: request.members,
    );
    if (mounted) {
      setState(() => _isBusy = false);
    }
    return success;
  }

  void _showApproveOptions(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request,
  ) {
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
              _buildApprovalSummary(request),
              const SizedBox(height: 24),
              _buildOptionTile(
                context,
                label: 'Forward to AVD (Room Allocation)',
                subtitle: 'SubAdmin AVD will allocate rooms for members',
                icon: Icons.business_rounded,
                onTap: () async {
                  Navigator.of(context).pop(); // Close bottom sheet
                  final success = await _updateStatus(
                    viewModel,
                    request,
                    'APPROVED (AVD)',
                  );
                  if (success && mounted) {
                    AppNotifications.showTopSnackBar(
                      context,
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
                  final success = await _updateStatus(
                    viewModel,
                    request,
                    'APPROVED (ANAND)',
                  );
                  if (success && mounted) {
                    AppNotifications.showTopSnackBar(
                      context,
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

  Widget _buildApprovalSummary(AccommodationRequest request) {
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
            _formatDate(request.checkIn),
          ),
          _buildApprovalSummaryItem(
            Icons.logout_rounded,
            'Check-out',
            _formatDate(request.checkOut),
          ),
          _buildApprovalSummaryItem(
            Icons.groups_rounded,
            'Members',
            '${request.members.length}',
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

  void _handleReject(
    BuildContext context,
    UserHomeViewModel viewModel,
    AccommodationRequest request,
  ) async {
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

    if (result != null && result['confirmed'] == true && mounted) {
      final success = await _updateStatus(
        viewModel,
        request,
        'REJECTED',
        customNotes: result['note'],
      );
      if (success && mounted) {
        AppNotifications.showTopSnackBar(
          context,
          'Request Rejected Successfully',
          isError: true,
        );
      }
    }
  }

  Widget _buildStatusBadge(AccommodationRequest request) {
    Color bgColor;
    Color textColor;

    final String statusUpper = request.status.trim().toUpperCase();
    bool isApproved =
        statusUpper == 'APPROVED' ||
        statusUpper.startsWith('APPROVED') ||
        statusUpper == 'ACCEPTED';

    String label = isApproved && request.hasAnyAllocation
        ? 'APPROVED'
        : (request.status.trim().isEmpty ? 'PENDING' : request.status);

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailRow(
    dynamic iconData,
    String label,
    String value, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: iconData is IconData
              ? Icon(iconData as IconData, size: 16, color: AppColors.labelGrey)
              : HugeIcon(icon: iconData, size: 16, color: AppColors.labelGrey),
        ),
        const SizedBox(width: 10),
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
              const SizedBox(height: 2),
              InkWell(
                onTap: onTap,
                child: Text(
                  value.isEmpty ? 'N/A' : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    decoration: onTap != null ? TextDecoration.underline : null,
                    decorationColor: AppColors.teal.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSectionHeader(String title, dynamic icon) {
    return Row(
      children: [
        icon is IconData
            ? Icon(icon as IconData, size: 20, color: AppColors.teal)
            : HugeIcon(icon: icon, size: 20, color: AppColors.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserHomeViewModel>();
    final isBusy = viewModel.isUpdating || _isBusy;

    // Reactively find latest state from ViewModel, fallback to initialRequest
    final request = viewModel.requests.firstWhere(
      (r) => r.id == widget.requestId,
      orElse: () => widget.initialRequest,
    );

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
            fontSize: 19,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isHistory)
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit01,
                color: AppColors.teal,
                size: 22,
              ),
              onPressed: isBusy
                  ? null
                  : () => _handleEdit(context, viewModel, request),
            ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete01,
              color: AppColors.danger,
              size: 22,
            ),
            onPressed: isBusy
                ? null
                : () => _handleDelete(context, viewModel, request),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top General Card
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          _buildStatusBadge(request),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${request.members.length} Request Members',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.labelGrey,
                        ),
                      ),
                      if (request.requesterPradesh.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              size: 16,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Requester Pradesh: ',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.labelGrey,
                              ),
                            ),
                            Text(
                              request.requesterPradesh,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Dates Card
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.tealLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                color: AppColors.teal,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Check-In',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.labelGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDate(request.checkIn),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 35,
                        width: 1,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 2),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.tealLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                color: AppColors.teal,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Check-Out',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.labelGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDate(request.checkOut),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
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
                ),
                const SizedBox(height: 16),

                // 3. Allocation Card (Room or House)
                if (request.hasAnyAllocation) ...[
                  _buildSectionHeader(
                    'Allocations',
                    HugeIcons.strokeRoundedKey01,
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.hasRoomAllocation) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.tealLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedDoor01,
                                  color: AppColors.teal,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Room Allocation',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.labelGrey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Room Number: ${request.activeRoomAllocation?.roomNumber ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (request.hasHouseAllocation) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.tealLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedHome01,
                                  color: AppColors.teal,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'House Allocation',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.labelGrey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Owner: ${request.activeHouseDetails?.ownerName ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    if (request
                                                .activeHouseDetails
                                                ?.contactNumber !=
                                            null &&
                                        request
                                            .activeHouseDetails!
                                            .contactNumber!
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _detailRow(
                                        HugeIcons.strokeRoundedCall02,
                                        'House Contact',
                                        request
                                            .activeHouseDetails!
                                            .contactNumber!,
                                        onTap: () async {
                                          final cleanPhone = request
                                              .activeHouseDetails!
                                              .contactNumber!
                                              .replaceAll(
                                                RegExp(r'[^0-9+]'),
                                                '',
                                              );
                                          final uri = Uri.parse(
                                            'tel:$cleanPhone',
                                          );
                                          try {
                                            await launchUrl(uri);
                                          } catch (e) {
                                            debugPrint(
                                              'Could not launch call: $e',
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                    if (request.activeHouseDetails?.address !=
                                            null &&
                                        request
                                            .activeHouseDetails!
                                            .address!
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _detailRow(
                                        HugeIcons.strokeRoundedLocation01,
                                        'House Address',
                                        request.activeHouseDetails!.address!,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        const Text(
                          'Member Allocation Mappings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: request.members.length,
                          itemBuilder: (context, index) {
                            final m = request.members[index];
                            final alloc = request.findAllocationForMember(m.id);
                            String mappingText = 'Not Allocated';
                            dynamic mappingIcon =
                                HugeIcons.strokeRoundedCancelCircle;
                            Color mappingColor = AppColors.danger;

                            if (alloc != null) {
                              if (alloc.roomNumber != null) {
                                mappingText = 'Room ${alloc.roomNumber}';
                                mappingIcon = HugeIcons.strokeRoundedDoor01;
                                mappingColor = AppColors.teal;
                              } else if (alloc.houseDetails != null) {
                                mappingText =
                                    'House (${alloc.houseDetails!.ownerName})';
                                mappingIcon = HugeIcons.strokeRoundedHome01;
                                mappingColor = AppColors.teal;
                              } else {
                                mappingText = 'Allocated';
                                mappingIcon =
                                    HugeIcons.strokeRoundedCheckmarkCircle01;
                                mappingColor = AppColors.teal;
                              }
                            } else if (request.hasDirectHouseBooking) {
                              mappingText =
                                  'House (${request.activeHouseDetails?.ownerName ?? 'Allocated'})';
                              mappingIcon = HugeIcons.strokeRoundedHome01;
                              mappingColor = AppColors.teal;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 14,
                                    color: AppColors.labelGrey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      HugeIcon(
                                        icon: mappingIcon,
                                        size: 13,
                                        color: mappingColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mappingText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: mappingColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Notes Section
                if (request.notes.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Request Notes',
                    HugeIcons.strokeRoundedNote01,
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.userNotes.isNotEmpty) ...[
                          const Text(
                            'User Notes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.labelGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.userNotes,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (request.userNotes.isNotEmpty &&
                            request.adminNotes.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                        if (request.adminNotes.isNotEmpty) ...[
                          const Text(
                            'Admin Notes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.adminNotes,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Members List
                _buildSectionHeader(
                  'Members List',
                  HugeIcons.strokeRoundedUserGroup,
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: request.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = request.members[index];
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.teal,
                                ),
                              ),
                              if (m.pradesh.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgGrey,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    m.pradesh,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.labelGrey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _detailRow(
                            HugeIcons.strokeRoundedCall02,
                            'Contact Phone',
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
                          const SizedBox(height: 8),
                          _detailRow(
                            HugeIcons.strokeRoundedMail01,
                            'Email Address',
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
                        ],
                      ),
                    );
                  },
                ),

                // Spacing at the bottom if buttons are visible
                if (!widget.isHistory &&
                    request.status.trim().toUpperCase() == 'PENDING')
                  const SizedBox(height: 100)
                else
                  const SizedBox(height: 40),
              ],
            ),
          ),

          // Action Buttons Fixed at Bottom
          if (!widget.isHistory &&
              request.status.trim().toUpperCase() == 'PENDING')
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Approve',
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: AppColors.teal,
                        onPressed: isBusy
                            ? null
                            : () => _showApproveOptions(
                                context,
                                viewModel,
                                request,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        text: 'Reject',
                        icon: HugeIcons.strokeRoundedCancelCircle,
                        color: AppColors.danger,
                        onPressed: isBusy
                            ? null
                            : () => _handleReject(context, viewModel, request),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isBusy)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: AppLoading()),
            ),
        ],
      ),
    );
  }
}
