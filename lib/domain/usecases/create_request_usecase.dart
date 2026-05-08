import '../../data/repositories/request_repository_impl.dart';

class CreateRequestUseCase {
  final RequestRepositoryImpl repository;

  CreateRequestUseCase(this.repository);

  Future<bool> execute(Map<String, dynamic> data, String token) {
    return repository.createRequest(data, token);
  }
}