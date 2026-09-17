import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:accommodation/core/api/api_config.dart';
import 'package:accommodation/domain/models/accommodation_request.dart';
import 'package:accommodation/domain/models/room.dart';

class RequestRemoteDataSource {
  final http.Client client;

  RequestRemoteDataSource(this.client);

  Future<List<Map<String, dynamic>>> getPradeshList(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/pradesh');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("DEBUG: Pradesh API Raw Data: ${response.body}");
        return List<Map<String, dynamic>>.from(data['pradesh'] ?? []);
      }
      return [];
    } catch (e) {
      print("GET PRADESH ERROR: $e");
      return [];
    }
  }

  Future<bool> createRequest(Map<String, dynamic> data, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requests}');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print("REQUEST DATA: $data");
      print("RESPONSE: ${response.statusCode} ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("API ERROR: $e");
      return false;
    }
  }

  Future<List<AccommodationRequest>> getMyRequests(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.myRequests}');
      print("GET MY REQUESTS URL: $url");
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        "GET MY REQUESTS RESPONSE: ${response.statusCode} ${response.body}",
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['requests'] ?? [];
        return data.map((json) => AccommodationRequest.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("GET MY REQUESTS ERROR: $e");
      return [];
    }
  }

  Future<List<AccommodationRequest>> getAllRequests(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminRequests}');
      print("GET ADMIN REQUESTS URL: $url");
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET ADMIN REQUESTS RESPONSE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['requests'] ?? [];
        return data.map((json) => AccommodationRequest.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("GET ADMIN REQUESTS ERROR: $e");
      return [];
    }
  }

  Future<bool> sendToAdmin(int requestId, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/requests/$requestId/send-to-admin');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("SEND TO ADMIN RESPONSE: ${response.statusCode} ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("SEND TO ADMIN ERROR: $e");
      return false;
    }
  }



  Future<bool> cancelRequest(int requestId, String token) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.requests}/$requestId',
      );
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("CANCEL REQUEST RESPONSE: ${response.statusCode} ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("CANCEL REQUEST ERROR: $e");
      return false;
    }
  }

  Future<bool> updateMyRequest(
    int requestId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.requests}/$requestId',
      );
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print(
        "UPDATE MY REQUEST RESPONSE: ${response.statusCode} ${response.body}",
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("UPDATE MY REQUEST ERROR: $e");
      return false;
    }
  }

  Future<bool> forwardToMembers(
    int requestId,
    List<int> memberIds,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.requests}/$requestId/forward-to-members',
      );
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({"member_ids": memberIds}),
      );

      print(
        "FORWARD TO MEMBERS RESPONSE: ${response.statusCode} ${response.body}",
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("FORWARD TO MEMBERS ERROR: $e");
      return false;
    }
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
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminRequests}/$requestId',
      );
      final payload = {
        if (requestName != null) 'request_name': requestName,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        if (checkIn != null)
          'check_in': checkIn.toIso8601String().split('T').first,
        if (checkOut != null)
          'check_out': checkOut.toIso8601String().split('T').first,
        if (members != null) 'total_people': members.length,
        if (members != null) 'members': members.map((m) => m.toJson()).toList(),
      };
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      print(
        "UPDATE ADMIN REQUEST RESPONSE: ${response.statusCode} ${response.body}",
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("UPDATE ADMIN REQUEST ERROR: $e");
      return false;
    }
  }

  Future<(bool, String?)> allocateMember(
    int requestId,
    String token, {
    required int memberId,
    int? roomId,
    int? houseId,
    int? assignedCapacity,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminRequests}/$requestId/allocate-member',
      );
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'request_member_id': memberId,
          if (roomId != null) 'room_id': roomId,
          if (houseId != null) 'house_id': houseId,
          if (assignedCapacity != null) 'assigned_capacity': assignedCapacity,
        }),
      );

      print(
        "ALLOCATE MEMBER RESPONSE: ${response.statusCode} ${response.body}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, null);
      } else {
        String? errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error']?.toString();
          print(
            "ALLOCATE MEMBER ERROR DETAIL: ${errorMessage ?? 'Unknown error'}",
          );
        } catch (e) {
          print("ALLOCATE MEMBER ERROR parsing response: $e");
        }
        return (false, errorMessage ?? 'Server error (${response.statusCode})');
      }
    } catch (e) {
      print("ALLOCATE MEMBER ERROR: $e");
      return (false, e.toString());
    }
  }

  Future<List<Room>> getAvailableRooms(
    String token, {
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (checkIn != null) queryParams['check_in'] = checkIn;
      if (checkOut != null) queryParams['check_out'] = checkOut;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.rooms}',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print("GET ROOMS URL: $uri");
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET ROOMS RESPONSE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['rooms'] ?? [];
        return data.map((json) => Room.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("GET ROOMS ERROR: $e");
      return [];
    }
  }

  Future<bool> addRoom(Map<String, dynamic> data, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rooms}');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("ADD ROOM ERROR: $e");
      return false;
    }
  }

  Future<bool> updateRoom(
    int roomId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rooms}/$roomId');
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE ROOM ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteRoom(int roomId, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rooms}/$roomId');
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE ROOM ERROR: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllHouses(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.allHouses}');
      print("GET ALL HOUSES URL: $uri");
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['houses'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET ALL HOUSES ERROR: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableHouses(
    String token, {
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.availableHouses}?check_in=$checkIn&check_out=$checkOut',
      );
      print("GET AVAILABLE HOUSES URL: $uri");
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['houses'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET AVAILABLE HOUSES ERROR: $e");
      return [];
    }
  }

  Future<(bool, String?)> allocateHouse(
    int requestId,
    int houseId,
    String token, {
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.houseBookings}');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'house_id': houseId,
          'request_id': requestId,
          'check_in': checkIn,
          'check_out': checkOut,
        }),
      );

      print("ALLOCATE HOUSE RESPONSE: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, null);
      } else {
        final errorData = json.decode(response.body);
        return (
          false,
          errorData['error']?.toString() ?? 'Failed to allocate house',
        );
      }
    } catch (e) {
      print("ALLOCATE HOUSE ERROR: $e");
      return (false, e.toString());
    }
  }

  Future<bool> addHouse(Map<String, dynamic> data, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.allHouses}');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      print("ADD HOUSE RESPONSE: ${response.statusCode} ${response.body}");
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("ADD HOUSE ERROR: $e");
      return false;
    }
  }

  Future<bool> updateHouse(
    int houseId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.allHouses}/$houseId',
      );
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      print("UPDATE HOUSE RESPONSE: ${response.statusCode} ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE HOUSE ERROR: $e");
      return false;
    }
  }

  Future<bool> updateHouseStatus(
    int houseId,
    bool isActive,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.allHouses}/$houseId',
      );
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'is_active': isActive}),
      );

      print("UPDATE HOUSE STATUS RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE HOUSE STATUS ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteHouse(int houseId, String token) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.allHouses}/$houseId',
      );
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("DELETE HOUSE RESPONSE: ${response.statusCode} ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE HOUSE ERROR: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMemberSuggestions(
    String token, {
    String? pradesh,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (pradesh != null && pradesh.trim().isNotEmpty) {
        queryParams['pradesh'] = pradesh.trim();
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.memberSuggestions}',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET MEMBER SUGGESTIONS RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['members'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET MEMBER SUGGESTIONS ERROR: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdminMembers(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminMembers}');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET ADMIN MEMBERS RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['members'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET ADMIN MEMBERS ERROR: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminUsers}');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET ALL USERS RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['users'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET ALL USERS ERROR: $e");
      return [];
    }
  }

  Future<bool> updateUser(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminUsers}/$id');
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print("UPDATE USER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE USER ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminUsers}/$id');
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("DELETE USER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE USER ERROR: $e");
      return false;
    }
  }

  Future<bool> addUser(Map<String, dynamic> data, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminUsers}');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print("ADD USER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("ADD USER ERROR: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserMembers(
    String userId,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminUsers}/$userId/members',
      );
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET USER MEMBERS RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['members'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET USER MEMBERS ERROR: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllRooms(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminRoomsAll}');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET ALL ROOMS RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['rooms']);
      }
      return [];
    } catch (e) {
      print("GET ALL ROOMS ERROR: $e");
      return [];
    }
  }

  Future<bool> updateRoomStatus(int roomId, bool isActive, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rooms}/$roomId');
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'is_active': isActive}),
      );

      print("UPDATE ROOM STATUS RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE ROOM STATUS ERROR: $e");
      return false;
    }
  }

  Future<bool> updateMember(
    int memberId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminMembers}/$memberId',
      );
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      print("UPDATE MEMBER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE MEMBER ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteMember(int memberId, String token) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminMembers}/$memberId',
      );
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("DELETE MEMBER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE MEMBER ERROR: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyMembers(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.myMembers}');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET MY MEMBERS RESPONSE: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['members'] ?? [];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("GET MY MEMBERS ERROR: $e");
      return [];
    }
  }

  Future<bool> updateMyMember(
    int memberId,
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.myMembers}/$memberId',
      );
      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      print("UPDATE MY MEMBER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE MY MEMBER ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteMyMember(int memberId, String token) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.myMembers}/$memberId',
      );
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("DELETE MY MEMBER RESPONSE: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE MY MEMBER ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteAllocationItem(int itemId, String token) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.allocationItems}/$itemId',
      );
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        "DELETE ALLOCATION ITEM RESPONSE: ${response.statusCode} ${response.body}",
      );
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE ALLOCATION ITEM ERROR: $e");
      return false;
    }
  }

  Future<bool> deleteMemberAllocation(
    int memberAllocationId,
    String token,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.memberAllocations}/$memberAllocationId',
      );
      final response = await client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        "DELETE MEMBER ALLOCATION RESPONSE: ${response.statusCode} ${response.body}",
      );
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE MEMBER ALLOCATION ERROR: $e");
      return false;
    }
  }

  Future<(bool, String?)> syncRequestAllocation(
    int requestId,
    String token, {
    required List<int> memberIds,
    int? roomId,
    int? houseId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.adminRequests}/$requestId/sync-allocation',
      );
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'member_ids': memberIds,
          if (roomId != null) 'room_id': roomId,
          if (houseId != null) 'house_id': houseId,
          'assigned_capacity': memberIds.length,
        }),
      );

      print(
        "SYNC REQUEST ALLOCATION RESPONSE: ${response.statusCode} ${response.body}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, null);
      }

      String? errorMessage;
      try {
        final body = json.decode(response.body);
        errorMessage = body['error']?.toString();
      } catch (_) {}
      return (false, errorMessage ?? 'Server error (${response.statusCode})');
    } catch (e) {
      print("SYNC REQUEST ALLOCATION ERROR: $e");
      return (false, e.toString());
    }
  }

  Future<String?> uploadImage(String filePath, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.upload}');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("UPLOAD IMAGE RESPONSE: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      print("UPLOAD IMAGE ERROR: $e");
      return null;
    }
  }

  /// Fetch requests that are approved and forwarded to a specific SubAdmin type
  Future<List<AccommodationRequest>> getSubAdminRequests(
    String token,
    String subAdminType,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.subadminRequests}?type=$subAdminType',
      );
      print("GET SUBADMIN REQUESTS URL: $url");
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET SUBADMIN REQUESTS RESPONSE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['requests'] ?? [];
        return data
            .map((json) => AccommodationRequest.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print("GET SUBADMIN REQUESTS ERROR: $e");
      return [];
    }
  }
}
