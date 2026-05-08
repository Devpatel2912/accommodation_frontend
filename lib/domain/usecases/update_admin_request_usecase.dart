import 'package:accommodation/data/repositories/request_repository_impl.dart';
import 'package:accommodation/domain/models/accommodation_request.dart';

class UpdateAdminRequestUseCase {
  final RequestRepositoryImpl repository;
  UpdateAdminRequestUseCase(this.repository);

  Future<bool> execute(
    int requestId,
    String token, {
    String? requestName,
    String? status,
    String? notes,
    DateTime? checkIn,
    DateTime? checkOut,
    List<AddedMember>? members,
  }) async {
    return await repository.updateAdminRequest(
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
}
