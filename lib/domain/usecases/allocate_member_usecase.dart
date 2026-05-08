import 'package:accommodation/data/repositories/request_repository_impl.dart';

class AllocateMemberUseCase {
  final RequestRepositoryImpl repository;
  AllocateMemberUseCase(this.repository);

  Future<(bool, String?)> execute(int requestId, String token, {required int memberId, int? roomId, int? houseId, int? assignedCapacity}) async {
    return await repository.allocateMember(requestId, token, memberId: memberId, roomId: roomId, houseId: houseId, assignedCapacity: assignedCapacity);
  }
}
