import 'package:accommodation/core/services/notification_service.dart';
import 'package:accommodation/core/services/push_notification_service.dart';
import 'package:accommodation/data/datasources/request_remote_datasource.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/domain/models/room.dart';
import 'package:accommodation/domain/usecases/get_my_requests_usecase.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/domain/usecases/cancel_request_usecase.dart';
import 'package:accommodation/domain/usecases/get_profile_usecase.dart';
import 'package:accommodation/domain/usecases/forward_to_members_usecase.dart';
import 'package:accommodation/domain/usecases/get_all_requests_usecase.dart';
import 'package:accommodation/domain/usecases/update_admin_request_usecase.dart';
import 'package:accommodation/domain/usecases/allocate_member_usecase.dart';
import 'package:accommodation/domain/usecases/get_available_rooms_usecase.dart';
import 'package:accommodation/core/utils/notifications.dart';

class UserHomeViewModel extends ChangeNotifier {
  final _uiNotificationController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get uiNotificationStream =>
      _uiNotificationController.stream;

  void notify(String message, {bool isError = false}) {
    _uiNotificationController.add(AppNotification(message, isError: isError));
  }

  final GetMyRequestsUseCase getMyRequestsUseCase;
  final CancelRequestUseCase cancelRequestUseCase;
  final GetProfileUseCase getProfileUseCase;
  final ForwardToMembersUseCase forwardToMembersUseCase;
  final GetAllRequestsUseCase getAllRequestsUseCase;
  final UpdateAdminRequestUseCase updateAdminRequestUseCase;
  final AllocateMemberUseCase allocateMemberUseCase;
  final GetAvailableRoomsUseCase getAvailableRoomsUseCase;
  final RequestRemoteDataSource remoteDataSource;

  UserHomeViewModel(
    this.getMyRequestsUseCase,
    this.cancelRequestUseCase,
    this.getProfileUseCase,
    this.forwardToMembersUseCase,
    this.getAllRequestsUseCase,
    this.updateAdminRequestUseCase,
    this.allocateMemberUseCase,
    this.getAvailableRoomsUseCase,
    this.remoteDataSource,
  );

  List<AccommodationRequest> requests = [];
  List<Room> availableRooms = [];
  Map<String, dynamic>? userData;
  bool isLoading = false;
  bool isProfileLoading = false;
  bool isForwarding = false;
  bool isUpdating = false;
  String searchQuery = '';
  String? filterPradesh;
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String? lastAllocationError;
  String? lastRoomError;
  List<String> pradeshList = [];

  Future<void> fetchPradeshList() async {
    final token = await Prefs.getToken();
    if (token == null) return;
    pradeshList = await remoteDataSource.getPradeshList(token);
    print("DEBUG: Fetched ${pradeshList.length} pradesh names");
    notifyListeners();
  }

  List<String> get availablePradeshFilters {
    final set = <String>{};
    for (var r in requests) {
      for (var m in r.members) {
        if (m.pradesh.isNotEmpty) set.add(m.pradesh);
      }
    }
    return set.toList()..sort();
  }

  void setFilterPradesh(String? value) {
    filterPradesh = value;
    notifyListeners();
  }

  void setFilterDates(DateTime? start, DateTime? end) {
    filterStartDate = start;
    filterEndDate = end;
    notifyListeners();
  }

  void clearFilters() {
    filterPradesh = null;
    filterStartDate = null;
    filterEndDate = null;
    notifyListeners();
  }

  bool get isAdmin => userData?['role']?.toString().toUpperCase() == 'ADMIN';

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchRequests() async {
    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return;

    if (userData == null) {
      await fetchProfile();
    }

    // Only show loading if we have no data yet (first time)
    if (requests.isEmpty) {
      isLoading = true;
      notifyListeners();
    }

    print("DEBUG: fetchRequests called. isAdmin: $isAdmin");

    List<AccommodationRequest> fetched;
    if (isAdmin) {
      print("DEBUG: Calling getAllRequestsUseCase");
      fetched = await getAllRequestsUseCase.execute(token);
    } else {
      print("DEBUG: Calling getMyRequestsUseCase");
      fetched = await getMyRequestsUseCase.execute(token);
    }

    // Filter out soft-deleted requests locally to avoid DB enum issues
    requests = fetched.where((r) {
      final status = r.status.trim().toUpperCase();
      final notes = (r.notes ?? "").toUpperCase();
      return status != 'DELETED' && !notes.contains('[DELETED]');
    }).toList();

    print(
      "DEBUG: Fetched ${requests.length} requests for ${isAdmin ? 'ADMIN' : 'USER'}",
    );
    for (var r in requests) {
      if (r.status.toUpperCase() == 'PENDING') {
        print("DEBUG: Found PENDING request: ${r.id}");
      }
    }

    // Sort by ID descending (newest first) if ID exists
    requests.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return;

    isProfileLoading = true;
    notifyListeners();

    userData = await getProfileUseCase.execute(token);
    print("DEBUG: Fetched user profile: $userData");

    isProfileLoading = false;
    notifyListeners();

    // --- SETUP REAL-TIME NOTIFICATIONS ---
    _setupNotifications();
  }

  void _setupNotifications() async {
    // 1. Setup FCM Topic Subscriptions
    final pushService = PushNotificationService();
    final userId = userData?['id']?.toString();
    
    if (userId != null) {
      await pushService.subscribeToUserTopics(
        isAdmin: isAdmin,
        // You can add houseId and roomId here if you have them in userData
      );
      // Also subscribe to specific user topic for personal notifications
      await pushService.subscribeToTopic('user_$userId');
    }

    // 2. Setup Supabase Real-time (Optional/Legacy)
    final ns = NotificationService();
    ns.unsubscribe(); // Clean up old subscriptions

    if (isAdmin) {
      ns.subscribeToAdminNotifications();
      ns.adminNotifications.listen((payload) {
        print(
          "🔔 REAL-TIME: Admin received new request notification. Payload: $payload",
        );
        // fetchRequests(); // Removed auto-refresh on notification

        // Check for nested payload
        final actualData =
            payload['payload'] != null && payload['payload'] is Map
            ? payload['payload'] as Map<String, dynamic>
            : payload;

        final userName =
            actualData['userName'] ?? actualData['user_name'] ?? 'A user';
        notify("New accommodation request received from $userName.");
      });
    } else {
      final userId = userData?['id']?.toString();
      if (userId != null) {
        ns.subscribeToUserNotifications(userId);
        ns.userNotifications.listen((payload) {
          print(
            "🔔 REAL-TIME: User received status update notification. Payload: $payload",
          );
          // fetchRequests(); // Removed auto-refresh on notification

          // Check for nested payload (sometimes happens in certain client versions)
          final actualData =
              payload['payload'] != null && payload['payload'] is Map
              ? payload['payload'] as Map<String, dynamic>
              : payload;

          final reqName =
              actualData['requestName'] ??
              actualData['request_name'] ??
              'Accommodation Request';
          final status = actualData['status'] ?? 'Updated';

          notify("Your request '$reqName' has been $status.");
        });
      }
    }
  }

  Future<bool> cancelRequest(int? requestId) async {
    if (requestId == null) return false;

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    // Get request details before cancellation to know who to notify
    AccommodationRequest? requestToNotify;
    try {
      requestToNotify = requests.firstWhere((r) => r.id == requestId);
    } catch (_) {}

    final success = await cancelRequestUseCase.execute(requestId, token);
    if (success) {
      // If admin cancelled, notify the user
      if (isAdmin && requestToNotify != null && requestToNotify.userId != null) {
        PushNotificationService().triggerNotification(
          topic: 'user_${requestToNotify.userId}',
          title: 'Request Cancelled',
          body: 'Your accommodation request "${requestToNotify.title}" has been cancelled by the admin.',
          data: {
            'type': 'STATUS_UPDATE',
            'requestId': requestId.toString(),
            'status': 'CANCELLED',
          },
        );

        // Real-time notification
        NotificationService().sendUserNotification(
          requestToNotify.userId!.toString(),
          {'message': 'Your request "${requestToNotify.title}" has been cancelled.'},
        );
      }
      await fetchRequests(); // Refresh list
    }
    return success;
  }

  Future<bool> forwardToMembers(int? requestId, List<int> memberIds) async {
    if (requestId == null || memberIds.isEmpty) return false;

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    isForwarding = true;
    notifyListeners();

    final success = await forwardToMembersUseCase.execute(
      requestId,
      memberIds,
      token,
    );

    isForwarding = false;
    notifyListeners();

    return success;
  }

  Future<bool> updateRequestStatus(
    int? requestId, {
    String? requestName,
    String? status,
    String? notes,
    DateTime? checkIn,
    DateTime? checkOut,
    List<AddedMember>? members,
  }) async {
    if (requestId == null) return false;

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    isUpdating = true;
    notifyListeners();

    final success = await updateAdminRequestUseCase.execute(
      requestId,
      token,
      requestName: requestName,
      status: status,
      notes: notes,
      checkIn: checkIn,
      checkOut: checkOut,
      members: members,
    );

    if (success) {
      // If admin updated status, notify the user
      if (isAdmin && status != null) {
        // Find the request to get user ID
        AccommodationRequest? req;
        try {
          req = requests.firstWhere((r) => r.id == requestId);
        } catch (_) {}

        if (req != null && req.userId != null) {
          PushNotificationService().triggerNotification(
            topic: 'user_${req.userId}',
            title: 'Status Updated',
            body: 'Your request "${req.title}" status is now: $status',
            data: {
              'type': 'STATUS_UPDATE',
              'requestId': requestId.toString(),
              'status': status,
            },
          );

          // Real-time notification
          NotificationService().sendUserNotification(
            req.userId!.toString(),
            {'message': 'Your request "${req.title}" status is now: $status'},
          );
        }
      }
      await fetchRequests();
    }

    isUpdating = false;
    notifyListeners();

    return success;
  }

  Future<bool> updateMyPendingRequest(AccommodationRequest request) async {
    if (request.id == null) return false;
    if (request.status.trim().toUpperCase() != 'PENDING') {
      return false;
    }

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    isUpdating = true;
    notifyListeners();

    final data = {
      "request_name": request.requestName,
      "check_in": request.checkIn.toIso8601String().split('T').first,
      "check_out": request.checkOut.toIso8601String().split('T').first,
      "total_people": request.members.length,
      "notes": request.notes,
      "members": request.members
          .map(
            (m) => {
              "name": m.name,
              "contact": m.contact,
              "pradesh": m.pradesh,
              "email": m.email,
            },
          )
          .toList(),
    };

    final success = await remoteDataSource.updateMyRequest(
      request.id!,
      data,
      token,
    );

    if (success) {
      await fetchRequests();
    }

    isUpdating = false;
    notifyListeners();

    return success;
  }

  Future<bool> allocateMember(
    int? requestId, {
    required int memberId,
    int? roomId,
    int? houseId,
  }) async {
    if (requestId == null) return false;

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    isUpdating = true;
    notifyListeners();

    final (success, error) = await allocateMemberUseCase.execute(
      requestId,
      token,
      memberId: memberId,
      roomId: roomId,
      houseId: houseId,
    );

    if (success) {
      // Notify the user about room allocation
      AccommodationRequest? req;
      try {
        req = requests.firstWhere((r) => r.id == requestId);
      } catch (_) {}

      if (req != null && req.userId != null) {
        PushNotificationService().triggerNotification(
          topic: 'user_${req.userId}',
          title: 'Room Allocated!',
          body: 'A member has been allocated a room for your request: ${req.title}',
          data: {
            'type': 'ALLOCATION',
            'requestId': requestId.toString(),
            'status': 'ALLOCATED',
          },
        );

        // Real-time notification
        NotificationService().sendUserNotification(
          req.userId!.toString(),
          {'message': 'A member has been allocated a room for your request: ${req.title}'},
        );
      }
      await fetchRequests();
    } else {
      lastAllocationError = error;
      notify(error ?? "Failed to allocate member", isError: true);
    }

    isUpdating = false;
    notifyListeners();

    return success;
  }

  Future<bool> allocateAllMembers(
    int? requestId, {
    required List<int> memberIds,
    int? roomId,
    int? houseId,
  }) async {
    print(
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
    );
    print(
      "[ANTIGRAVITY-v2] STARTING ALLOCATION PROCESS for Request: $requestId",
    );

    if (requestId == null || memberIds.isEmpty) return false;

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    isUpdating = true;
    lastAllocationError = null;
    notifyListeners();

    bool allSuccess = true;
    for (final memberId in memberIds) {
      final (success, error) = await allocateMemberUseCase.execute(
        requestId,
        token,
        memberId: memberId,
        roomId: roomId,
        houseId: houseId,
        assignedCapacity: memberIds.length,
      );

      if (!success) {
        allSuccess = false;
        lastAllocationError = error;
        notify(
          error ?? "Allocation failed for one or more members",
          isError: true,
        );
        break; // Stop on first error to avoid multiple snacks
      }
    }

    await fetchRequests();
    isUpdating = false;
    notifyListeners();

    return allSuccess;
  }

  Future<bool> releaseMemberAllocation(int? requestId, int memberId) async {
    if (requestId == null) return false;

    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    notifyListeners();

    // Find the request and the member allocation record for this member.
    final request = requests.firstWhere((r) => r.id == requestId);
    final memberAllocationId = request.findMemberAllocationId(memberId);

    if (memberAllocationId == null) {
      isUpdating = false;
      notify(
        "Could not find allocation details for this member",
        isError: true,
      );
      notifyListeners();
      return false;
    }

    final success = await remoteDataSource.deleteMemberAllocation(
      memberAllocationId,
      token,
    );

    if (success) {
      await fetchRequests();
    }

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> syncRequestAllocation(
    int? requestId, {
    required List<int> memberIds,
    int? roomId,
    int? houseId,
  }) async {
    if (requestId == null) return false;

    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return false;

    isUpdating = true;
    lastAllocationError = null;
    notifyListeners();

    final (success, error) = await remoteDataSource.syncRequestAllocation(
      requestId,
      token,
      memberIds: memberIds,
      roomId: roomId,
      houseId: houseId,
    );

    if (success) {
      await fetchRequests();
    } else {
      lastAllocationError = error;
      notify(error ?? "Failed to sync allocation", isError: true);
    }

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<void> fetchAvailableRooms({String? checkIn, String? checkOut}) async {
    final token = await Prefs.getToken();
    if (token == null || token.isEmpty) return;

    isLoading = true;
    notifyListeners();

    availableRooms = await getAvailableRoomsUseCase.execute(
      token,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    isLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchAvailableHouses({
    String? checkIn,
    String? checkOut,
  }) async {
    final token = await Prefs.getToken();
    if (token == null) return [];
    return await remoteDataSource.getAvailableHouses(
      token,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllHouses() async {
    final token = await Prefs.getToken();
    if (token == null) return [];
    return await remoteDataSource.getAllHouses(token);
  }

  Future<bool> allocateHouse(
    int requestId,
    int houseId, {
    String? checkIn,
    String? checkOut,
  }) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    lastAllocationError = null;
    notifyListeners();

    final (success, error) = await remoteDataSource.allocateHouse(
      requestId,
      houseId,
      token,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    if (success) {
      // Notify user about house allocation
      AccommodationRequest? req;
      try {
        req = requests.firstWhere((r) => r.id == requestId);
      } catch (_) {}

      if (req != null && req.userId != null) {
        PushNotificationService().triggerNotification(
          topic: 'user_${req.userId}',
          title: 'House Allocated!',
          body: 'An entire house has been allocated for your request: ${req.title}',
          data: {
            'type': 'ALLOCATION',
            'requestId': requestId.toString(),
            'status': 'HOUSE_ALLOCATED',
          },
        );

        // Real-time notification
        NotificationService().sendUserNotification(
          req.userId!.toString(),
          {'message': 'An entire house has been allocated for your request: ${req.title}'},
        );
      }
    } else {
      lastAllocationError = error;
    }

    await fetchRequests();
    isUpdating = false;
    notifyListeners();
    return success;
  }

  void addRequestLocally(AccommodationRequest request) {
    requests.insert(0, request);
    notifyListeners();
  }

  Future<bool> addRoom(Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    lastRoomError = null;
    notifyListeners();

    final success = await remoteDataSource.addRoom(data, token);
    if (success) {
      await fetchAvailableRooms();
      notify("Room added successfully");
    } else {
      lastRoomError = "Failed to add room";
      notify(lastRoomError!, isError: true);
    }

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateRoom(int roomId, Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    lastRoomError = null;
    notifyListeners();

    final success = await remoteDataSource.updateRoom(roomId, data, token);
    if (success) {
      await fetchAvailableRooms();
      notify("Room updated successfully");
    } else {
      lastRoomError = "Failed to update room";
      notify(lastRoomError!, isError: true);
    }

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteRoom(int roomId) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    lastRoomError = null;
    notifyListeners();

    // Use a modified version of the call that returns the message if needed,
    // or just handle it here. For now, we'll keep it simple but you could update
    // the data source to return (bool, String?).
    final success = await remoteDataSource.deleteRoom(roomId, token);
    if (success) {
      await fetchAvailableRooms();
      notify("Room deleted successfully");
    } else {
      lastRoomError = "Cannot delete. Room might be occupied";
      notify(lastRoomError!, isError: true);
    }

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> addHouse(Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    notifyListeners();

    final success = await remoteDataSource.addHouse(data, token);

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateHouse(int houseId, Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    notifyListeners();

    final success = await remoteDataSource.updateHouse(houseId, data, token);

    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final token = await Prefs.getToken();
    if (token == null) return [];
    return await remoteDataSource.getAllUsers(token);
  }

  Future<bool> updateUserInfo(String id, Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;
    isUpdating = true;
    notifyListeners();
    final success = await remoteDataSource.updateUser(id, data, token);
    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> removeUser(String id) async {
    final token = await Prefs.getToken();
    if (token == null) return false;
    isUpdating = true;
    notifyListeners();
    final success = await remoteDataSource.deleteUser(id, token);
    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> addUser(Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;
    isUpdating = true;
    notifyListeners();
    final success = await remoteDataSource.addUser(data, token);
    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<List<Map<String, dynamic>>> fetchUserMembers(String userId) async {
    final token = await Prefs.getToken();
    if (token == null) return [];
    return await remoteDataSource.getUserMembers(userId, token);
  }

  Future<List<Map<String, dynamic>>> fetchAllMembers() async {
    final token = await Prefs.getToken();
    if (token == null) return [];
    if (isAdmin) {
      return await remoteDataSource.getAdminMembers(token);
    } else {
      return await remoteDataSource.getMyMembers(token);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllRooms() async {
    final token = await Prefs.getToken();
    if (token == null) return [];
    return await remoteDataSource.getAllRooms(token);
  }

  Future<bool> toggleRoomStatus(int roomId, bool isActive) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    lastRoomError = null;
    final success = await remoteDataSource.updateRoomStatus(
      roomId,
      isActive,
      token,
    );

    if (success) {
      fetchAvailableRooms();
      notify("Room status updated");
    } else {
      lastRoomError = "Cannot change status. Room might be occupied.";
      notify(lastRoomError!, isError: true);
    }
    notifyListeners();
    return success;
  }

  Future<bool> toggleHouseStatus(int houseId, bool isActive) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    final success = await remoteDataSource.updateHouseStatus(
      houseId,
      isActive,
      token,
    );
    notifyListeners();
    return success;
  }

  Future<bool> updateMember(int memberId, Map<String, dynamic> data) async {
    final token = await Prefs.getToken();
    if (token == null) return false;
    isUpdating = true;
    notifyListeners();
    bool success;
    if (isAdmin) {
      success = await remoteDataSource.updateMember(memberId, data, token);
    } else {
      success = await remoteDataSource.updateMyMember(memberId, data, token);
    }
    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteMember(int memberId) async {
    final token = await Prefs.getToken();
    if (token == null) return false;
    isUpdating = true;
    notifyListeners();
    bool success;
    if (isAdmin) {
      success = await remoteDataSource.deleteMember(memberId, token);
    } else {
      success = await remoteDataSource.deleteMyMember(memberId, token);
    }
    isUpdating = false;
    notifyListeners();
    return success;
  }

  Future<String?> uploadImage(String filePath) async {
    final token = await Prefs.getToken();
    if (token == null) return null;
    return await remoteDataSource.uploadImage(filePath, token);
  }

  Future<bool> deleteHouse(int houseId) async {
    final token = await Prefs.getToken();
    if (token == null) return false;

    isUpdating = true;
    notifyListeners();

    final success = await remoteDataSource.deleteHouse(houseId, token);

    isUpdating = false;
    notifyListeners();
    return success;
  }

  void clearData() {
    requests = [];
    availableRooms = [];
    userData = null;
    isLoading = false;
    isProfileLoading = false;
    isForwarding = false;
    isUpdating = false;
    searchQuery = '';
    lastAllocationError = null;
    lastRoomError = null;

    notifyListeners();
  }
}
