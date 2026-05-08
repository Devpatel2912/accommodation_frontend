import '../../data/repositories/request_repository_impl.dart';

class ForwardToMembersUseCase {
  final RequestRepositoryImpl repository;

  ForwardToMembersUseCase(this.repository);

  Future<bool> execute(int requestId, List<int> memberIds, String token) {
    return repository.forwardToMembers(requestId, memberIds, token);
  }
}
