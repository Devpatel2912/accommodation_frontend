import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/widgets/app_button.dart';
import 'package:accommodation/presentation/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    final vm = context.read<UserHomeViewModel>();
    final members = await vm.fetchAllMembers();
    setState(() {
      _members = members;
      _filteredMembers = members;
      _isLoading = false;
    });
  }

  void _filterMembers(String query) {
    final vm = context.read<UserHomeViewModel>();
    setState(() {
      _filteredMembers = _members
          .where((m) =>
              (m['name']?.toString().toLowerCase() ?? '').contains(query.toLowerCase()) ||
              (m['contact']?.toString().toLowerCase() ?? '').contains(query.toLowerCase()) ||
              (m['email']?.toString().toLowerCase() ?? '').contains(query.toLowerCase()) ||
              (vm.isAdmin && (m['pradesh']?.toString().toLowerCase() ?? '').contains(query.toLowerCase())))
          .toList();
    });
  }

  void _showEditMemberDialog(Map<String, dynamic> member) {
    final vm = context.read<UserHomeViewModel>();
    final nameCtrl = TextEditingController(text: member['name']?.toString());
    final contactCtrl = TextEditingController(text: member['contact']?.toString());
    final emailCtrl = TextEditingController(text: member['email']?.toString());
    final pradeshCtrl = TextEditingController(text: member['pradesh']?.toString());
    
    AppDialog.show(
      context: context,
      title: 'Edit Member Details',
      icon: Icons.edit_note_rounded,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: contactCtrl, 
              decoration: const InputDecoration(labelText: 'Contact', counterText: ""),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            if (vm.isAdmin)
              TextField(controller: pradeshCtrl, decoration: const InputDecoration(labelText: 'Pradesh')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.labelGrey))),
        SizedBox(
          width: 140,
          child: Consumer<UserHomeViewModel>(
            builder: (context, vm, child) => AppButton(
              text: 'Save Changes',
              height: 44,
              borderRadius: 12,
              isLoading: vm.isUpdating,
              onPressed: () async {
                final updateData = {
                  'name': nameCtrl.text,
                  'contact': contactCtrl.text,
                  'email': emailCtrl.text,
                };
                if (vm.isAdmin) {
                  updateData['pradesh'] = pradeshCtrl.text;
                }
                
                final success = await vm.updateMember(member['id'], updateData);
                if (success && mounted) {
                  Navigator.pop(context);
                  _fetchMembers();
                  AppNotifications.showTopSnackBar(context, 'Member updated successfully');
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Delete Member Record?',
        message: 'Are you sure you want to remove the record for ${member['name']}? This won\'t delete their requests but will remove this member entry.',
        confirmText: 'Delete',
        confirmColor: AppColors.danger,
        icon: Icons.delete_outline_rounded,
        onConfirm: () async {
          final vm = context.read<UserHomeViewModel>();
          final success = await vm.deleteMember(member['id']);
          if (success && mounted) {
            _fetchMembers();
            AppNotifications.showTopSnackBar(context, 'Member record deleted');
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
        title: const Text('Member Management', 
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.bgGrey,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterMembers,
              decoration: InputDecoration(
                hintText: 'Search by name, contact, or pradesh...',
                prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _filteredMembers.isEmpty
                    ? const Center(child: Text('No members found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          return _MemberCard(
                            member: member,
                            onEdit: () => _showEditMemberDialog(member),
                            onDelete: () => _confirmDeleteMember(member),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['name']?.toString() ?? 'Unknown';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.teal.withOpacity(0.1),
              child: Text(initials, 
                style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.labelGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          member['contact']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (member['email'] != null && member['email'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 14, color: AppColors.labelGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            member['email'].toString(),
                            style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (context.read<UserHomeViewModel>().isAdmin && 
                      member['pradesh'] != null && member['pradesh'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member['pradesh'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppColors.labelGrey, size: 20),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
              ],
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
