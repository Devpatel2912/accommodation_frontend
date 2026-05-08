import 'package:accommodation/data/repositories/request_repository_impl.dart';
import 'package:accommodation/domain/models/room.dart';

class GetAvailableRoomsUseCase {
  final RequestRepositoryImpl repository;
  GetAvailableRoomsUseCase(this.repository);

  Future<List<Room>> execute(String token, {String? checkIn, String? checkOut}) async {
    return await repository.getAvailableRooms(token, checkIn: checkIn, checkOut: checkOut);
  }
}
