import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:accommodation/core/api/api_config.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource(this.client);

  Future<String?> requestOtp(String email) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOtp}');
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"email": email}),
      );

      print("SEND OTP RESPONSE: ${response.statusCode} ${response.body}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['otpToken'];
      }
      return null;
    } catch (e) {
      print("AUTH API ERROR: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp({
    required String email,
    required String otp,
    required String otpToken,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp');
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": email,
          "otp": otp,
          "otpToken": otpToken,
        }),
      );

      print("VERIFY OTP RESPONSE: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("VERIFY OTP ERROR: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}');
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("GET PROFILE RESPONSE: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      print("GET PROFILE ERROR: $e");
      return null;
    }
  }
}