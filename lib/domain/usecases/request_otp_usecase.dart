import '../../data/repositories/auth_repository_impl.dart';

class RequestOtpUseCase {
  final AuthRepositoryImpl repository;

  RequestOtpUseCase(this.repository);

  Future<String?> execute(String email) {
    return repository.requestOtp(email);
  }
}