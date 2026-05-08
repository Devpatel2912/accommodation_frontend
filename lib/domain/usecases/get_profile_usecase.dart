import '../../data/repositories/auth_repository_impl.dart';

class GetProfileUseCase {
  final AuthRepositoryImpl repository;

  GetProfileUseCase(this.repository);

  Future<Map<String, dynamic>?> execute(String token) {
    return repository.getProfile(token);
  }
}
