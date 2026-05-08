import '../../data/repositories/request_repository_impl.dart';

class CancelRequestUseCase {
  final RequestRepositoryImpl repository;

  CancelRequestUseCase(this.repository);

  Future<bool> execute(int requestId, String token) {
    return repository.cancelRequest(requestId, token);
  }
}
