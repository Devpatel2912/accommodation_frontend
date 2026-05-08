import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/presentation/viewmodels/user_home_viewmodel.dart';
import 'package:accommodation/presentation/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  final Set<int> _loadingRoomIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => _isLoading = true);
    final rooms = await context.read<UserHomeViewModel>().fetchAllRooms();
    setState(() {
      _rooms = rooms;
      _isLoading = false;
    });
  }

  Future<void> _toggleRoom(int roomId, bool currentStatus) async {
    setState(() => _loadingRoomIds.add(roomId));
    
    final viewModel = context.read<UserHomeViewModel>();
    final success = await viewModel.toggleRoomStatus(roomId, !currentStatus);
    
    if (mounted) {
      setState(() => _loadingRoomIds.remove(roomId));
      
      if (success) {
        // Update local state to show change immediately
        setState(() {
          final index = _rooms.indexWhere((r) => r['id'] == roomId);
          if (index != -1) {
            _rooms[index]['is_active'] = !currentStatus;
          }
        });
      } else {
        AppNotifications.showTopSnackBar(context, viewModel.lastRoomError ?? 'Failed to update room status', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        title: const Text('Room Activity', 
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _isLoading
          ? const AppLoading()
          : _rooms.isEmpty
              ? const Center(child: Text('No rooms found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    final bool isActive = room['is_active'] ?? true;
                    final int roomId = room['id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isActive ? AppColors.teal : AppColors.labelGrey).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isActive ? Icons.meeting_room_rounded : Icons.no_meeting_room_rounded,
                            color: isActive ? AppColors.teal : AppColors.labelGrey,
                          ),
                        ),
                        title: Text(
                          'Room ${room['room_number']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        subtitle: Text(
                          'Capacity: ${room['capacity']} Persons',
                          style: const TextStyle(fontSize: 13, color: AppColors.labelGrey),
                        ),
                        trailing: _loadingRoomIds.contains(roomId)
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: AppLoading(size: 20),
                              )
                            : Switch(
                                value: isActive,
                                activeColor: AppColors.teal,
                                onChanged: (val) => _toggleRoom(roomId, isActive),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
