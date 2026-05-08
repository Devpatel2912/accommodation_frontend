import '../../data/repositories/auth_repository_impl.dart';

class VerifyOtpUseCase {
  final AuthRepositoryImpl repository;

  VerifyOtpUseCase(this.repository);

  Future<Map<String, dynamic>?> execute({
    required String email,
    required String otp,
    required String otpToken,
  }) {
    return repository.verifyOtp(
      email: email,
      otp: otp,
      otpToken: otpToken,
    );
  }
}
