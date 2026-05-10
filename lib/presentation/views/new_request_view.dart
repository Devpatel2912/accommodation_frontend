import 'dart:async';

import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/presentation/viewmodels/new_request_viewmodel.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/prefs.dart';
import '../../data/datasources/request_remote_datasource.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../domain/usecases/create_request_usecase.dart';

import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';

import '../widgets/app_card.dart';
import '../widgets/app_dialog.dart';

class NewRequestView extends StatelessWidget {
  final AccommodationRequest? requestToEdit;
  final Future<bool> Function(AccommodationRequest)? onUpdate;

  const NewRequestView({super.key, this.requestToEdit, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.watch<UserHomeViewModel>();
    final isAdmin = homeViewModel.isAdmin;
    final userPradesh = isAdmin && requestToEdit != null
        ? (requestToEdit!.members.isNotEmpty
              ? requestToEdit!.members.first.pradesh
              : '')
        : homeViewModel.userData?['pradesh']?.toString() ?? '';

    return ChangeNotifierProvider(
      create: (_) {
        final client = http.Client();
        final remote = RequestRemoteDataSource(client);
        final repo = RequestRepositoryImpl(remote);
        final usecase = CreateRequestUseCase(repo);
        final vm = NewRequestViewModel(usecase, remote);

        // 1. Initialize immediately with local data to show form cards instantly
        vm.init(requestToEdit, pradesh: userPradesh, adminRole: isAdmin);

        // 2. Load dynamic data in background
        Prefs.getToken().then((token) {
          if (token != null) {
            remote.getPradeshList(token).then((list) {
              vm.init(
                requestToEdit,
                pradesh: userPradesh,
                adminRole: isAdmin,
                allPradesh: list,
              );
            });
          }
        });

        return vm;
      },
      child: _NewRequestScreenContent(onUpdate: onUpdate),
    );
  }
}

class _NewRequestScreenContent extends StatefulWidget {
  final Future<bool> Function(AccommodationRequest)? onUpdate;

  const _NewRequestScreenContent({this.onUpdate});

  @override
  State<_NewRequestScreenContent> createState() =>
      _NewRequestScreenContentState();
}

class _NewRequestScreenContentState extends State<_NewRequestScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<NewRequestViewModel>();
    _notificationSubscription = viewModel.uiNotificationStream.listen((n) {
      if (mounted) {
        AppNotifications.showTopSnackBar(
          context,
          n.message,
          isError: n.isError,
        );
      }
    });

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final viewModel = context.read<NewRequestViewModel>();
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final checkInFirstDate = tomorrow;
    final checkOutFirstDate = viewModel.checkIn ?? tomorrow;
    final firstDate = isCheckIn ? checkInFirstDate : checkOutFirstDate;
    final selectedDate = isCheckIn ? viewModel.checkIn : viewModel.checkOut;
    final fallbackDate = isCheckIn
        ? tomorrow
        : (viewModel.checkIn ?? tomorrow).add(const Duration(days: 1));
    final initialDate =
        selectedDate != null && !selectedDate.isBefore(firstDate)
        ? selectedDate
        : fallbackDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: AppColors.white,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isCheckIn) {
      viewModel.setCheckIn(picked);
    } else {
      viewModel.setCheckOut(picked);
    }
  }

  void _submit(BuildContext context) async {
    final viewModel = context.read<NewRequestViewModel>();

    if (viewModel.isLoading) return;

    final request = viewModel.submit();

    if (request == null) {
      String error = 'Please fill all required fields.';

      if (viewModel.requestNameCtrl.text.trim().isEmpty) {
        error = 'Please enter a request name or purpose.';
      } else if (viewModel.checkIn == null || viewModel.checkOut == null) {
        error = 'Please select check-in and check-out dates.';
      } else if (!viewModel.isCheckInAllowed) {
        error = 'Please select tomorrow or a later date for check-in.';
      } else if (!viewModel.isCheckOutAllowed) {
        error = 'Please select check-out on or after check-in.';
      } else {
        error = 'Please add at least one member.';
      }

      AppNotifications.showTopSnackBar(context, error, isError: true);
      return;
    }

    if (viewModel.isEditing) {
      if (!viewModel.isAdmin && !viewModel.canEditAsUser) {
        AppNotifications.showTopSnackBar(
          context,
          'Only pending requests can be edited',
          isError: true,
        );
        return;
      }

      if (widget.onUpdate == null) {
        Navigator.pop(context, request);
        return;
      }

      final success = await viewModel.updateExistingRequest(
        request,
        widget.onUpdate!,
      );

      if (!context.mounted) return;

      if (success) {
        AppNotifications.showTopSnackBar(
          context,
          'Request updated successfully',
        );
        Navigator.pop(context, true);
      } else {
        AppNotifications.showTopSnackBar(
          context,
          'Failed to update request',
          isError: true,
        );
      }
      return;
    }

    final success = await viewModel.createRequest(request);

    if (success) {
      AppNotifications.showTopSnackBar(context, 'Request Created Successfully');

      Navigator.pop(context, true);
    } else {
      AppNotifications.showTopSnackBar(
        context,
        'Failed to create request',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NewRequestViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: AppColors.textDark,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    viewModel.isEditing
                                        ? 'Edit Request'
                                        : 'New Request',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    viewModel.isEditing
                                        ? 'Update request details and members.'
                                        : 'Fill in details to request staff accommodation.',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('REQUEST NAME / PURPOSE'),
                        const SizedBox(height: 7),
                        _Field(
                          controller: viewModel.requestNameCtrl,
                          hint: 'e.g. Official Visit, Guest, etc.',
                        ),
                      ],
                    ),
                  ).animateEntrance(0),
                ),
                _sectionCard(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        Icons.calendar_today_rounded,
                        'Select Dates',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DateTile(
                              label: 'CHECK-IN',
                              value: viewModel.checkIn,
                              onTap: () => _pickDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateTile(
                              label: 'CHECK-OUT',
                              value: viewModel.checkOut,
                              onTap: () => _pickDate(context, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  animationIndex: 1,
                ),
                _sectionCard(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle(
                            Icons.person_outline_rounded,
                            'Add Members',
                          ),
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await AppDialog.show<bool>(
                                    context: context,
                                    title: 'Import Format',
                                    icon: Icons.info_outline_rounded,
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Please ensure your Excel file (.xlsx) follows this column order:',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildFormatItem(
                                          '1',
                                          'Full Name',
                                          Icons.person,
                                        ),
                                        _buildFormatItem(
                                          '2',
                                          'Contact Number',
                                          Icons.phone,
                                        ),
                                        _buildFormatItem(
                                          '3',
                                          'Email Address',
                                          Icons.email,
                                        ),
                                        _buildFormatItem(
                                          '4',
                                          'Pradesh (Optional)',
                                          Icons.location_on,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Note: The first row is treated as a header and will be skipped.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.labelGrey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      AppButton(
                                        text: 'Select Excel File',
                                        width: 180,
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                      ),
                                    ],
                                  );

                                  if (confirm != true) return;

                                  try {
                                    await viewModel.importMembersFromExcel();
                                    if (context.mounted &&
                                        viewModel.members.length > 1) {
                                      AppNotifications.showTopSnackBar(
                                        context,
                                        'Members imported successfully!',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppNotifications.showTopSnackBar(
                                        context,
                                        'Failed to import Excel. Please check the file format.',
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (viewModel.isLoading)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.teal,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.upload_file_rounded,
                                        size: 14,
                                        color: AppColors.teal,
                                      ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Import Excel',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.teal,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: viewModel.addMember,
                                child: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Column(
                        children: List.generate(
                          viewModel.members.length,
                          (index) => AppCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _MemberForm(
                              key: ValueKey(viewModel.members[index].tempKey),
                              member: viewModel.members[index],
                              index: index,
                              suggestions: viewModel.suggested,
                              showDivider: false,
                              onCheckDuplicate: (val, type) {
                                for (
                                  int i = 0;
                                  i < viewModel.members.length;
                                  i++
                                ) {
                                  if (i == index) continue;
                                  final m = viewModel.members[i];
                                  bool isDup = false;
                                  if (type == 'name' &&
                                      val.isNotEmpty &&
                                      m.name.toLowerCase() == val.toLowerCase())
                                    isDup = true;
                                  if (type == 'contact' &&
                                      val.isNotEmpty &&
                                      m.contact == val)
                                    isDup = true;
                                  if (type == 'email' &&
                                      val.isNotEmpty &&
                                      m.email.toLowerCase() ==
                                          val.toLowerCase())
                                    isDup = true;

                                  if (isDup) {
                                    AppNotifications.showTopSnackBar(
                                      context,
                                      'Member already entered ($val)',
                                      isError: true,
                                    );
                                    return true;
                                  }
                                }
                                return false;
                              },
                              onRemove: () => viewModel.removeMember(index),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  animationIndex: 2,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('OPTIONAL NOTES'),
                        const SizedBox(height: 7),
                        _Field(
                          controller: viewModel.notesCtrl,
                          hint: 'Add any note for this request...',
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ).animateEntrance(3),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Consumer<NewRequestViewModel>(
                        builder: (context, vm, child) => AppButton(
                          text: vm.isLoading
                              ? 'Submitting...'
                              : (vm.isEditing
                                    ? 'Update Request'
                                    : 'Submit Request'),
                          onPressed: vm.isLoading
                              ? null
                              : () => _submit(context),
                          isLoading: vm.isLoading,
                          icon: vm.isLoading ? null : Icons.send_rounded,
                        ),
                      ),
                    ),
                  ).animateEntrance(4),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: Text(
                        viewModel.isEditing
                            ? 'Changes will be visible after the request is updated.'
                            : 'Request will be reviewed by management within 24 hours.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.labelGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    required EdgeInsets margin,
    int? animationIndex,
  }) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );

    if (animationIndex != null) {
      card = card.animateEntrance(animationIndex);
    }

    return SliverToBoxAdapter(child: card);
  }

  Widget _buildFormatItem(String num, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: AppColors.labelGrey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.teal),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _MemberForm extends StatefulWidget {
  final AddedMember member;
  final int index;
  final List<SuggestedMember> suggestions;
  final bool showDivider;
  final bool Function(String, String) onCheckDuplicate;
  final VoidCallback? onRemove;

  const _MemberForm({
    super.key,
    required this.member,
    required this.index,
    required this.suggestions,
    required this.showDivider,
    required this.onCheckDuplicate,
    this.onRemove,
  });

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _pradeshCtrl;
  List<SuggestedMember> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
    _contactCtrl = TextEditingController(text: widget.member.contact);
    _emailCtrl = TextEditingController(text: widget.member.email);
    _pradeshCtrl = TextEditingController(text: widget.member.pradesh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _pradeshCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MemberForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member.name != _nameCtrl.text) {
      _nameCtrl.text = widget.member.name;
    }
    if (widget.member.contact != _contactCtrl.text) {
      _contactCtrl.text = widget.member.contact;
    }
    if (widget.member.email != _emailCtrl.text) {
      _emailCtrl.text = widget.member.email;
    }
    if (widget.member.pradesh != _pradeshCtrl.text) {
      _pradeshCtrl.text = widget.member.pradesh;
    }
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSuggestions = []);
      return;
    }
    setState(() {
      final lockedPradesh =
          context.read<NewRequestViewModel>().shouldLockPradeshToRequester
          ? context.read<NewRequestViewModel>().userPradesh
          : '';
      _filteredSuggestions = widget.suggestions
          .where(
            (s) =>
                s.name.toLowerCase().contains(query.toLowerCase()) &&
                (lockedPradesh.isEmpty || s.pradesh == lockedPradesh),
          )
          .toList();
    });
  }

  Widget _buildSuggestionsList() {
    final vm = context.read<NewRequestViewModel>();
    final lockPradesh = vm.isAdmin && vm.isEditing;

    return Container(
      color: Colors.white,
      child: Column(
        children: _filteredSuggestions.map((s) {
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.tealLight,
              child: Text(
                s.initials,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              s.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              s.pradesh,
              style: const TextStyle(fontSize: 11, color: AppColors.labelGrey),
            ),
            onTap: () {
              if (widget.onCheckDuplicate(s.name, 'name')) return;

              setState(() {
                _nameCtrl.text = s.name;
                widget.member.name = s.name;
                _contactCtrl.text = s.contact;
                widget.member.contact = s.contact;
                _emailCtrl.text = s.email;
                widget.member.email = s.email;
                if (lockPradesh) {
                  _pradeshCtrl.text = vm.userPradesh;
                  widget.member.pradesh = vm.userPradesh;
                } else {
                  _pradeshCtrl.text = s.pradesh;
                  widget.member.pradesh = s.pradesh;
                }
                _filteredSuggestions = [];
              });
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewRequestViewModel>();
    final lockPradesh = vm.isAdmin && vm.isEditing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (context.read<NewRequestViewModel>().members.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Member ${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.labelGrey,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 17,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const _Label('FULL NAME'),
        const SizedBox(height: 6),
        _Field(
          controller: _nameCtrl,
          hint: 'e.g. John Smith',
          onChanged: (value) {
            if (widget.onCheckDuplicate(value, 'name')) {
              _nameCtrl.clear();
              widget.member.name = '';
              return;
            }
            widget.member.name = value;
            _filterSuggestions(value);
          },
        ),
        if (_filteredSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(child: _buildSuggestionsList()),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('CONTACT NUMBER'),
                  const SizedBox(height: 6),
                  _Field(
                    controller: _contactCtrl,
                    hint: '+91 1234567890',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (widget.onCheckDuplicate(value, 'contact')) {
                        _contactCtrl.clear();
                        widget.member.contact = '';
                        return;
                      }
                      widget.member.contact = value;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('EMAIL ADDRESS'),
                  const SizedBox(height: 6),
                  _Field(
                    controller: _emailCtrl,
                    hint: 'john@company.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      if (widget.onCheckDuplicate(value, 'email')) {
                        _emailCtrl.clear();
                        widget.member.email = '';
                        return;
                      }
                      widget.member.email = value;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.isAdmin) ...[
          const _Label('PRADESH'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: lockPradesh ? AppColors.bgGrey : AppColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border, width: 1.4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: widget.member.pradesh.isEmpty
                    ? null
                    : widget.member.pradesh,
                hint: const Text(
                  'Select Pradesh',
                  style: TextStyle(fontSize: 13.5, color: AppColors.hintGrey),
                ),
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                disabledHint: Text(
                  lockPradesh
                      ? (widget.member.pradesh.isEmpty
                            ? 'Select Pradesh'
                            : widget.member.pradesh)
                      : 'Loading Pradesh...',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.hintGrey,
                  ),
                ),
                items: vm.availablePradesh
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: lockPradesh
                                ? AppColors.labelGrey
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: lockPradesh
                    ? null
                    : (val) {
                        setState(() {
                          widget.member.pradesh = val ?? '';
                          _pradeshCtrl.text = val ?? '';
                        });
                      },
              ),
            ),
          ),
        ],
        if (widget.showDivider) ...[
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, thickness: 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  String get _text {
    if (value == null) return 'dd/mm/yyyy';
    return '${value!.day.toString().padLeft(2, '0')}/'
        '${value!.month.toString().padLeft(2, '0')}/'
        '${value!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border, width: 1.3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _text,
                    style: TextStyle(
                      fontSize: 13,
                      color: value == null
                          ? AppColors.hintGrey
                          : AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 14,
                  color: AppColors.hintGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppColors.labelGrey,
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefix,
    this.onChanged,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.prefix != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: widget.prefix,
                )
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: const TextStyle(color: AppColors.hintGrey, fontSize: 13.5),
          counterText: "",
          errorStyle: const TextStyle(
            color: AppColors.danger,
            fontSize: 11,
            height: 1.2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }
}

extension _AnimateExtension on Widget {
  Widget animateEntrance(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: this,
    );
  }
}
