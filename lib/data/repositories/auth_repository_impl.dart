import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  Future<String?> requestOtp(String email) async {
    return await remote.requestOtp(email);
  }

  Future<Map<String, dynamic>?> verifyOtp({
    required String email,
    required String otp,
    required String otpToken,
  }) async {
    return await remote.verifyOtp(
      email: email,
      otp: otp,
      otpToken: otpToken,
    );
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    return await remote.getProfile(token);
  }

  Future<Map<String, dynamic>?> loginWithPassword({
    required String email,
    required String password,
  }) async {
    return await remote.loginWithPassword(
      email: email,
      password: password,
    );
  }
}