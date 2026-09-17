class Room {
  final int id;
  final String roomNumber;
  final int capacity;
  final int currentOccupancy;
  final int remainingCapacity;
  final String status;
  final bool isActive;
  final List<Map<String, dynamic>> members;

  Room({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    this.currentOccupancy = 0,
    required this.remainingCapacity,
    this.status = 'Available',
    this.isActive = true,
    this.members = const [],
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final int totalCapacity =
        int.tryParse(json['capacity']?.toString() ?? '0') ?? 0;
    final int occupied =
        int.tryParse(json['current_occupancy']?.toString() ?? '0') ?? 0;
    return Room(
      id: json['id'],
      roomNumber:
          json['room_number']?.toString() ?? json['no']?.toString() ?? '',
      capacity: totalCapacity,
      currentOccupancy: occupied,
      remainingCapacity:
          int.tryParse(json['remaining_capacity']?.toString() ?? '') ??
          totalCapacity,
      status: json['status'] ?? 'Available',
      isActive: json['is_active'] ?? true,
      members: (json['members'] as List?)?.map((m) => Map<String, dynamic>.from(m)).toList() ?? [],
    );
  }
}
