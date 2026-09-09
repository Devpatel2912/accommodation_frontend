import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_card.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:accommodation/presentation/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/notifications.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<String> _pradeshList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    context.read<UserHomeViewModel>().fetchPradeshList();
    await _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await context.read<UserHomeViewModel>().fetchAllUsers();
    setState(() {
      // Filter and sort by id descending to show newest first
      final filtered = users.where((u) => u['role'] != 'ADMIN').toList();
      filtered.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return idB.compareTo(idA);
      });
      _users = filtered;
      _isLoading = false;
    });
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pradeshCtrl = TextEditingController();
    String selectedRole = 'USER';
    String? selectedSubAdminType;

    AppDialog.show(
      context: context,
      title: 'Add New User',
      icon: Icons.person_add_rounded,
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Full Name',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter email';
                    if (!RegExp(
                      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                    ).hasMatch(val)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '10 digit number',
                    counterText: "",
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter phone';
                    if (val.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Consumer<UserHomeViewModel>(
                  builder:
                      (context, vm, child) => DropdownButtonFormField<String>(
                        value: null,
                        items:
                            vm.pradeshList.isEmpty
                                ? [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text("Loading Pradesh..."),
                                  ),
                                ]
                                : vm.pradeshList
                                    .map(
                                      (p) => DropdownMenuItem<String>(
                                        value: p['id']?.toString(),
                                        child: Text(p['name']?.toString() ?? ''),
                                      ),
                                    )
                                    .toList(),
                        onChanged:
                            vm.pradeshList.isEmpty
                                ? null
                                : (val) {
                                    final selected = vm.pradeshList.firstWhere(
                                      (p) => p['id']?.toString() == val,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    pradeshCtrl.text = selected['name']?.toString() ?? '';
                                  },
                        decoration: const InputDecoration(
                          labelText: 'Pradesh',
                          hintText: 'Select Pradesh',
                        ),
                        validator:
                            (val) => val == null ? 'Select a pradesh' : null,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['USER', 'ADMIN', 'SUBADMIN']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedRole = val!;
                      if (val != 'SUBADMIN') selectedSubAdminType = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                if (selectedRole == 'SUBADMIN') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSubAdminType,
                    items: ['AVD', 'ANAND']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedSubAdminType = val),
                    decoration: const InputDecoration(
                      labelText: 'SubAdmin Type',
                      hintText: 'Select AVD or ANAND',
                    ),
                    validator: (val) => selectedRole == 'SUBADMIN' && val == null
                        ? 'Select SubAdmin type'
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
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
              text: 'Add User',
              height: 44,
              borderRadius: 12,
              isLoading: vm.isUpdating,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                // Find pradesh_id based on name in pradeshCtrl
                final selectedPradesh = vm.pradeshList.firstWhere(
                  (p) => p['name'] == pradeshCtrl.text.trim(),
                  orElse: () => <String, dynamic>{},
                );

                final userData = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': selectedRole,
                  'pradesh': pradeshCtrl.text.trim(),
                  if (selectedPradesh.containsKey('id'))
                    'pradesh_id': selectedPradesh['id'],
                  if (selectedRole == 'SUBADMIN' && selectedSubAdminType != null)
                    'sub_admin_type': selectedSubAdminType,
                };

                final success = await vm.addUser(userData);
                if (success) {
                  Navigator.pop(context);
                  _fetchUsers();
                  AppNotifications.showTopSnackBar(context, 'User added successfully');
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);
    final phoneCtrl = TextEditingController(text: user['phone']);
    final pradeshCtrl = TextEditingController(text: user['pradesh']);
    String selectedRole = user['role'] ?? 'USER';
    String? selectedSubAdminType = user['sub_admin_type'];

    AppDialog.show(
      context: context,
      title: 'Edit User',
      icon: Icons.edit_rounded,
      content: StatefulBuilder(
        builder: (context, setDialogState) => SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter email';
                    if (!RegExp(
                      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                    ).hasMatch(val)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    counterText: "",
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter phone';
                    if (val.length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Consumer<UserHomeViewModel>(
                  builder:
                      (context, vm, child) {
                        final selectedPradeshId = vm.pradeshList.firstWhere(
                          (p) => p['name'] == user['pradesh'],
                          orElse: () => <String, dynamic>{},
                        )['id']?.toString();
                        return DropdownButtonFormField<String>(
                        value: selectedPradeshId,
                        items:
                            vm.pradeshList.isEmpty
                                ? [
                                  DropdownMenuItem<String>(
                                    value: selectedPradeshId,
                                    child: Text(user['pradesh'] ?? "Loading..."),
                                  ),
                                ]
                                : vm.pradeshList
                                    .map(
                                      (p) => DropdownMenuItem<String>(
                                        value: p['id']?.toString(),
                                        child: Text(p['name']?.toString() ?? ''),
                                      ),
                                    )
                                    .toList(),
                        onChanged:
                            vm.pradeshList.isEmpty
                                ? null
                                : (val) {
                                    final selected = vm.pradeshList.firstWhere(
                                      (p) => p['id']?.toString() == val,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    pradeshCtrl.text = selected['name']?.toString() ?? '';
                                  },
                        decoration: const InputDecoration(
                          labelText: 'Pradesh',
                          hintText: 'Select Pradesh',
                        ),
                        validator:
                            (val) => val == null ? 'Select a pradesh' : null,
                      );
                      },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole.toUpperCase(),
                  items: ['USER', 'ADMIN', 'SUBADMIN']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedRole = val!;
                      if (val != 'SUBADMIN') selectedSubAdminType = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                if (selectedRole.toUpperCase() == 'SUBADMIN') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSubAdminType?.toUpperCase(),
                    items: ['AVD', 'ANAND']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedSubAdminType = val),
                    decoration: const InputDecoration(
                      labelText: 'SubAdmin Type',
                      hintText: 'Select AVD or ANAND',
                    ),
                    validator: (val) =>
                        selectedRole.toUpperCase() == 'SUBADMIN' && val == null
                            ? 'Select SubAdmin type'
                            : null,
                  ),
                ],
              ],
            ),
          ),
        ),
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
          width: 110,
          child: Consumer<UserHomeViewModel>(
            builder: (context, vm, child) => AppButton(
              text: 'Update',
              height: 44,
              borderRadius: 12,
              isLoading: vm.isUpdating,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final selectedPradesh = vm.pradeshList.firstWhere(
                  (p) => p['name'] == pradeshCtrl.text.trim(),
                  orElse: () => <String, dynamic>{},
                );

                final updatedData = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': selectedRole,
                  'pradesh': pradeshCtrl.text.trim(),
                  if (selectedPradesh.containsKey('id'))
                    'pradesh_id': selectedPradesh['id'],
                  if (selectedRole.toUpperCase() == 'SUBADMIN' &&
                      selectedSubAdminType != null)
                    'sub_admin_type': selectedSubAdminType,
                };
                final success = await vm.updateUserInfo(
                  user['id'].toString(),
                  updatedData,
                );
                if (success) {
                  Navigator.pop(context);
                  _fetchUsers();
                  AppNotifications.showTopSnackBar(context, 'User updated successfully');
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: 'Delete User',
        message: 'Are you sure you want to delete ${user['name']}?',
        confirmText: 'Delete',
        confirmColor: AppColors.danger,
        icon: Icons.delete_forever_rounded,
        onConfirm: () async {
          final success = await context
              .read<UserHomeViewModel>()
              .removeUser(user['id'].toString());
          if (success) {
            _fetchUsers();
            AppNotifications.showTopSnackBar(context, 'User deleted successfully');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.bgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const AppLoading(message: 'Fetching users...')
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final initials =
                      user['name']
                          ?.split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join('')
                          .toUpperCase() ??
                      '??';

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showUserMembers(user),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.tealLight,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (user['pradesh_id'] != null && user['pradesh_id'].toString().isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          user['pradesh_id'].toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.labelGrey,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user['role'] == 'ADMIN'
                                              ? AppColors.teal.withOpacity(0.12)
                                              : user['role'] == 'SUBADMIN'
                                                  ? const Color(0xFFFFF3E0)
                                                  : AppColors.border.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          user['role'] == 'SUBADMIN'
                                              ? 'SUBADMIN (${user['sub_admin_type'] ?? ''})'
                                              : (user['role'] ?? 'USER'),
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: user['role'] == 'ADMIN'
                                                ? AppColors.teal
                                                : user['role'] == 'SUBADMIN'
                                                    ? const Color(0xFFE65100)
                                                    : AppColors.labelGrey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    user['email'] ?? 'No email',
                                    style: const TextStyle(
                                      color: AppColors.labelGrey,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.labelGrey,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditUserDialog(user);
                                } else if (value == 'delete') {
                                  _confirmDelete(user);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: AppColors.teal),
                                      SizedBox(width: 10),
                                      Text('Edit User', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                      SizedBox(width: 10),
                                      Text('Delete', style: TextStyle(fontSize: 14, color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showUserMembers(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UserMembersSheet(user: user),
    );
  }
}

class _UserMembersSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const _UserMembersSheet({required this.user});

  @override
  State<_UserMembersSheet> createState() => _UserMembersSheetState();
}

class _UserMembersSheetState extends State<_UserMembersSheet> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    final members = await context.read<UserHomeViewModel>().fetchUserMembers(
      widget.user['id'].toString(),
    );
    if (mounted) {
      setState(() {
        _members = members;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.tealLight,
                  child: Text(
                    widget.user['name']?[0]?.toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'All associated members',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : _members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: AppColors.labelGrey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No members found',
                          style: TextStyle(
                            color: AppColors.labelGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _members.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 12,
                                        color: AppColors.labelGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          member['contact'] ?? 'No contact',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.labelGrey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (member['email'] != null &&
                                      member['email']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.email_outlined,
                                          size: 12,
                                          color: AppColors.labelGrey,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            member['email'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.labelGrey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (member['pradesh'] != null && member['pradesh'].toString().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  member['pradesh'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ),
                          ],
                      ]
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
