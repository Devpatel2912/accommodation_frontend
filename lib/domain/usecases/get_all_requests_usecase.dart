import '../../data/repositories/request_repository_impl.dart';
import '../models/accommodation_request.dart';

class GetAllRequestsUseCase {
  final RequestRepositoryImpl repository;

  GetAllRequestsUseCase(this.repository);

  Future<List<AccommodationRequest>> execute(String token) {
    return repository.getAllRequests(token);
  }
}
