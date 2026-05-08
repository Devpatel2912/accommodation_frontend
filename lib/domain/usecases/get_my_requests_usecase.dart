import 'package:accommodation/domain/models/accommodation_request.dart';
import '../../data/repositories/request_repository_impl.dart';

class GetMyRequestsUseCase {
  final RequestRepositoryImpl repository;

  GetMyRequestsUseCase(this.repository);

  Future<List<AccommodationRequest>> execute(String token) {
    return repository.getMyRequests(token);
  }
}
