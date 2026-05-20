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

  Future<Map<String, dynamic>?> loginWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      print("LOGIN WITH PASSWORD RESPONSE: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("LOGIN WITH PASSWORD ERROR: $e");
      return null;
    }
  }

  /// Register a new user with role (ADMIN, SUBADMIN, USER)
  /// For SUBADMIN, also pass sub_admin_type (AVD or ANAND)
  Future<(bool, String?)> registerUser({
    required String name,
    required String email,
    required String phone,
    required String role,
    String? subAdminType,
    String? pradesh,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}');
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.toUpperCase(),
        if (subAdminType != null) 'sub_admin_type': subAdminType.toUpperCase(),
        if (pradesh != null && pradesh.isNotEmpty) 'pradesh': pradesh,
      };

      print("REGISTER USER PAYLOAD: $payload");

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print("REGISTER USER RESPONSE: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (true, null);
      } else {
        final errorData = json.decode(response.body);
        return (false, errorData['error']?.toString() ?? 'Registration failed');
      }
    } catch (e) {
      print("REGISTER USER ERROR: $e");
      return (false, e.toString());
    }
  }
}