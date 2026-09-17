class SuggestedMember {
  final String name;
  final String initials;
  final String pradesh;
  final String contact;
  final String email;
  bool selected;

  SuggestedMember({
    required this.name,
    required this.initials,
    this.pradesh = '',
    this.contact = '',
    this.email = '',
    this.selected = false,
  });
}

class AddedMember {
  final String tempKey =
      "${DateTime.now().microsecondsSinceEpoch}-${(100000 + (999999 - 100000) * (DateTime.now().millisecond / 1000)).toInt()}";
  final int? id;
  String name;
  String contact;
  String email;
  String pradesh;

  AddedMember({
    this.id,
    this.name = '',
    this.contact = '',
    this.email = '',
    this.pradesh = '',
  });

  factory AddedMember.fromJson(Map<String, dynamic> json) {
    return AddedMember(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      contact: json['contact'] ?? '',
      email: json['email'] ?? '',
      pradesh: _parsePradesh(json['pradesh']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'contact': contact,
      'email': email,
      'pradesh': pradesh,
    };
  }
}

class MemberAllocation {
  final int? id;
  final int? requestMemberId;

  MemberAllocation({this.id, this.requestMemberId});

  factory MemberAllocation.fromJson(Map<String, dynamic> json) {
    return MemberAllocation(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      requestMemberId: json['request_member_id'] != null
          ? int.tryParse(json['request_member_id'].toString())
          : (json['request_members'] != null &&
                    json['request_members']['id'] != null
                ? int.tryParse(json['request_members']['id'].toString())
                : null),
    );
  }
}

class AllocationItem {
  final int? id;
  final List<MemberAllocation> memberAllocations;
  final String? roomNumber;
  final HouseAllocationDetails? houseDetails;
  final DateTime? allocationDate;

  AllocationItem({
    this.id,
    required this.memberAllocations,
    this.roomNumber,
    this.houseDetails,
    this.allocationDate,
  });

  factory AllocationItem.fromJson(Map<String, dynamic> json) {
    // Try both plural and singular keys from backend
    final list = json['member_allocations'] ?? json['member_allocation'];

    String? roomNo;
    // Check 'rooms' (plural) and 'room' (singular)
    final roomsData = json['rooms'] ?? json['room'];
    if (roomsData != null) {
      if (roomsData is List) {
        if (roomsData.isNotEmpty) {
          roomNo = roomsData[0]['room_number']?.toString();
        }
      } else {
        roomNo = roomsData['room_number']?.toString();
      }
    }

    HouseAllocationDetails? hDetails;
    // Check 'houses' (plural) and 'house' (singular)
    final housesData = json['houses'] ?? json['house'];
    if (housesData != null) {
      if (housesData is List) {
        if (housesData.isNotEmpty) {
          hDetails = HouseAllocationDetails.fromHouseJson(housesData[0]);
        }
      } else if (housesData is Map<String, dynamic>) {
        hDetails = HouseAllocationDetails.fromHouseJson(housesData);
      } else if (housesData is Map) {
        hDetails = HouseAllocationDetails.fromHouseJson(
          Map<String, dynamic>.from(housesData),
        );
      }
    }

    return AllocationItem(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      memberAllocations:
          (list as List?)
              ?.map((ma) => MemberAllocation.fromJson(ma))
              .toList() ??
          [],
      roomNumber: roomNo,
      houseDetails: hDetails,
      allocationDate: _parseDate(json['created_at'] ?? json['allocation_date']),
    );
  }

  String? get houseName => houseDetails?.ownerName;
}

class HouseAllocationDetails {
  final String? ownerName;
  final String? contactNumber;
  final String? address;
  final String? imageUrl;
  final DateTime? allocationDate;

  const HouseAllocationDetails({
    this.ownerName,
    this.contactNumber,
    this.address,
    this.imageUrl,
    this.allocationDate,
  });

  factory HouseAllocationDetails.fromBookingJson(Map<String, dynamic> json) {
    final house = json['houses'] ?? json['house'];
    Map<String, dynamic>? houseJson;
    if (house is Map<String, dynamic>) {
      houseJson = house;
    } else if (house is Map) {
      houseJson = Map<String, dynamic>.from(house);
    }

    return HouseAllocationDetails(
      ownerName: houseJson?['owner_name']?.toString(),
      contactNumber:
          houseJson?['contact_number']?.toString() ??
          houseJson?['phone']?.toString(),
      address: houseJson?['address']?.toString(),
      imageUrl: houseJson?['image_url']?.toString(),
      allocationDate: _parseDate(json['created_at'] ?? json['allocation_date']),
    );
  }

  factory HouseAllocationDetails.fromHouseJson(Map<String, dynamic> json) {
    return HouseAllocationDetails(
      ownerName: json['owner_name']?.toString(),
      contactNumber:
          json['contact_number']?.toString() ?? json['phone']?.toString(),
      address: json['address']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  bool get hasAnyValue =>
      (ownerName?.isNotEmpty ?? false) ||
      (contactNumber?.isNotEmpty ?? false) ||
      (imageUrl?.isNotEmpty ?? false) ||
      (address?.isNotEmpty ?? false);
}

class AccommodationRequest {
  static const String adminNotesSeparator = '\n\n--- Admin Notes ---\n';

  final int? id;
  final int? userId;
  final String requestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<AddedMember> members;
  final String notes;
  final String notifyEmail;
  final String status;
  final List<AllocationItem> allocations;
  final HouseAllocationDetails? houseDetails;
  final String requesterPradesh;

  AccommodationRequest({
    this.id,
    this.userId,
    this.requestName = '',
    required this.checkIn,
    required this.checkOut,
    required this.members,
    required this.notes,
    required this.notifyEmail,
    this.status = 'PENDING',
    this.allocations = const [],
    this.houseDetails,
    this.requesterPradesh = '',
  });

  factory AccommodationRequest.fromJson(Map<String, dynamic> json) {
    print(
      "DEBUG: Parsing request ${json['id']} with keys: ${json.keys.toList()}",
    );
    return AccommodationRequest(
      id: json['id'],
      userId: json['user_id'],
      requestName: json['request_name'] ?? '',
      checkIn: DateTime.parse(json['check_in']),
      checkOut: DateTime.parse(json['check_out']),
      members:
          (json['request_members'] as List? ?? json['members'] as List?)
              ?.map((m) => AddedMember.fromJson(m))
              .toList() ??
          [],
      notes: json['notes'] ?? '',
      notifyEmail: json['notify_email'] ?? '',
      status: _parseStatus(json),
      allocations: _parseAllocations(json['allocations'] ?? json['allocation']),
      houseDetails: _parseHouseDetails(
        json['house_bookings'] ?? json['house_booking'],
      ),
      requesterPradesh:
          json['requester_pradesh']?.toString() ??
          json['users']?['pradesh']?.toString() ??
          json['user']?['pradesh']?.toString() ??
          '',
    );
  }

  static String _parseStatus(Map<String, dynamic> json) {
    String status = (json['status'] == null || json['status'] == 'null') ? 'PENDING' : json['status'].toString();
    String notes = json['notes']?.toString() ?? '';
    
    if (status == 'ACCEPTED') {
      if (notes.contains('APPROVED (AVD)')) {
        return 'APPROVED (AVD)';
      } else if (notes.contains('APPROVED (ANAND)')) {
        return 'APPROVED (ANAND)';
      }
    }
    return status;
  }

  static HouseAllocationDetails? _parseHouseDetails(dynamic houseBookingJson) {
    if (houseBookingJson == null) return null;
    if (houseBookingJson is List) {
      if (houseBookingJson.isEmpty) return null;
      final hb = houseBookingJson[0];
      if (hb is Map<String, dynamic>) {
        return HouseAllocationDetails.fromBookingJson(hb);
      }
      if (hb is Map) {
        return HouseAllocationDetails.fromBookingJson(
          Map<String, dynamic>.from(hb),
        );
      }
      return null;
    }
    if (houseBookingJson is Map<String, dynamic>) {
      return HouseAllocationDetails.fromBookingJson(houseBookingJson);
    }
    if (houseBookingJson is Map) {
      return HouseAllocationDetails.fromBookingJson(
        Map<String, dynamic>.from(houseBookingJson),
      );
    }
    return null;
  }

  static List<AllocationItem> _parseAllocations(dynamic allocationJson) {
    if (allocationJson == null) return [];

    // If it's a list (Supabase join result), take the first one or combine them
    if (allocationJson is List) {
      if (allocationJson.isEmpty) return [];
      // Combine items from all allocation records if multiple exist
      final allItems = <AllocationItem>[];
      for (var alloc in allocationJson) {
        final items = alloc['items'] ?? alloc['allocation_items'];
        if (items is List) {
          allItems.addAll(items.map((i) => AllocationItem.fromJson(i)));
        }
      }
      return allItems;
    }

    // If it's a single map
    final itemsList =
        (allocationJson['items'] ?? allocationJson['allocation_items'])
            as List?;
    if (itemsList == null) return [];
    return itemsList.map((i) => AllocationItem.fromJson(i)).toList();
  }

  Set<int> get allocatedMemberIds {
    final ids = <int>{};
    for (var alloc in allocations) {
      for (var ma in alloc.memberAllocations) {
        if (ma.requestMemberId != null) ids.add(ma.requestMemberId!);
      }
    }
    return ids;
  }

  Set<int> get activeAllocatedMemberIds {
    if (allocatedMemberIds.isNotEmpty) return allocatedMemberIds;
    if (hasDirectHouseBooking) {
      return members.where((m) => m.id != null).map((m) => m.id!).toSet();
    }
    return {};
  }

  List<AllocationItem> get memberLevelAllocations => allocations
      .where((allocation) => allocation.memberAllocations.isNotEmpty)
      .toList();

  bool get hasDirectHouseBooking =>
      allocations.isEmpty && (houseDetails?.hasAnyValue ?? false);

  HouseAllocationDetails? get activeHouseDetails {
    for (final allocation in memberLevelAllocations) {
      if (allocation.houseDetails?.hasAnyValue ?? false) {
        return allocation.houseDetails;
      }
    }
    return hasDirectHouseBooking ? houseDetails : null;
  }

  AllocationItem? get activeRoomAllocation {
    for (final allocation in memberLevelAllocations) {
      if (allocation.roomNumber != null) return allocation;
    }
    return null;
  }

  AllocationItem? findAllocationForMember(int? memberId) {
    if (memberId == null) return null;
    for (var alloc in allocations) {
      for (var ma in alloc.memberAllocations) {
        if (ma.requestMemberId == memberId) return alloc;
      }
    }
    return null;
  }

  int? findMemberAllocationId(int? memberId) {
    if (memberId == null) return null;
    for (final alloc in allocations) {
      for (final ma in alloc.memberAllocations) {
        if (ma.requestMemberId == memberId) return ma.id;
      }
    }
    return null;
  }

  bool get isFullyAllocated =>
      members.isNotEmpty && activeAllocatedMemberIds.length >= members.length;
  bool get hasHouseAllocation => activeHouseDetails?.hasAnyValue ?? false;
  bool get hasRoomAllocation => activeRoomAllocation != null;
  bool get hasAnyAllocation => activeAllocatedMemberIds.isNotEmpty;
  bool get isPartiallyAllocated => hasAnyAllocation && !isFullyAllocated;
  bool get isWaitingForAllocation => !hasAnyAllocation;
  String? get houseName => activeHouseDetails?.ownerName;
  String get userNotes {
    String cleanNotes = notes;
    if (cleanNotes.contains(adminNotesSeparator)) {
      cleanNotes = cleanNotes.split(adminNotesSeparator).first;
    }
    
    cleanNotes = cleanNotes.replaceAll('[SENT_TO_ADMIN]', '').trim();
    
    if (cleanNotes.startsWith('Approved:') ||
        cleanNotes.startsWith('Rejected:')) {
      return '';
    }
    return cleanNotes;
  }

  String get adminNotes {
    final trimmedNotes = notes.trim();
    if (!notes.contains(adminNotesSeparator)) {
      if (trimmedNotes.startsWith('Approved:') ||
          trimmedNotes.startsWith('Rejected:')) {
        return trimmedNotes;
      }
      return '';
    }
    return notes
        .split(adminNotesSeparator)
        .skip(1)
        .join(adminNotesSeparator)
        .trim();
  }

  static String composeNotes({String? userNotes, String? adminNotes, bool preserveSentToAdmin = false}) {
    final user = userNotes?.trim() ?? '';
    final admin = adminNotes?.trim() ?? '';
    
    String result = '';
    if (user.isEmpty) {
      result = admin;
    } else if (admin.isEmpty) {
      result = user;
    } else {
      result = '$user$adminNotesSeparator$admin';
    }
    
    if (preserveSentToAdmin && !result.contains('[SENT_TO_ADMIN]')) {
      result = result.isEmpty ? '[SENT_TO_ADMIN]' : '$result\n[SENT_TO_ADMIN]';
    }
    
    return result;
  }

  String get allocationStatusLabel {
    if (isPartiallyAllocated) return 'Partial Pending';
    if (hasHouseAllocation && hasRoomAllocation) return 'Mixed Allocation';
    if (hasHouseAllocation) return 'House Allocated';
    if (hasRoomAllocation) return 'Room Allocated';
    return 'Allocation Pending';
  }

  String get title => requestName.isNotEmpty
      ? requestName
      : (members.isNotEmpty ? members.first.name : 'New Request');
  String get subtitle => '${members.length} Members';
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _parsePradesh(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) return value['name']?.toString() ?? '';
  return value.toString();
}
