import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/domain/models/room.dart';
import '../datasources/request_remote_datasource.dart';

class RequestRepositoryImpl {
  final RequestRemoteDataSource remote;

  RequestRepositoryImpl(this.remote);

  Future<bool> createRequest(Map<String, dynamic> data, String token) {
    return remote.createRequest(data, token);
  }

  Future<List<AccommodationRequest>> getMyRequests(String token) {
    return remote.getMyRequests(token);
  }

  Future<List<AccommodationRequest>> getAllRequests(String token) {
    return remote.getAllRequests(token);
  }

  Future<bool> cancelRequest(int requestId, String token) {
    return remote.cancelRequest(requestId, token);
  }

  Future<bool> forwardToMembers(
    int requestId,
    List<int> memberIds,
    String token,
  ) {
    return remote.forwardToMembers(requestId, memberIds, token);
  }

  Future<bool> updateAdminRequest(
    int requestId,
    String token, {
    String? requestName,
    String? status,
    String? notes,
    DateTime? checkIn,
    DateTime? checkOut,
    List<AddedMember>? members,
  }) {
    return remote.updateAdminRequest(
      requestId,
      token,
      requestName: requestName,
      status: status,
      notes: notes,
      checkIn: checkIn,
      checkOut: checkOut,
      members: members,
    );
  }

  Future<(bool, String?)> allocateMember(
    int requestId,
    String token, {
    required int memberId,
    int? roomId,
    int? houseId,
    int? assignedCapacity,
  }) {
    return remote.allocateMember(
      requestId,
      token,
      memberId: memberId,
      roomId: roomId,
      houseId: houseId,
      assignedCapacity: assignedCapacity,
    );
  }

  Future<List<Room>> getAvailableRooms(
    String token, {
    String? checkIn,
    String? checkOut,
  }) {
    return remote.getAvailableRooms(
      token,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }
}
