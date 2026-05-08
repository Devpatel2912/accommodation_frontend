import 'package:flutter/material.dart';
import 'package:accommodation/domain/usecases/request_otp_usecase.dart';
import 'package:accommodation/domain/usecases/verify_otp_usecase.dart';
import 'package:accommodation/core/utils/prefs.dart';

import 'package:accommodation/core/utils/notifications.dart';
import 'dart:async';

class LoginViewModel extends ChangeNotifier {
  final _uiNotificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get uiNotificationStream => _uiNotificationController.stream;

  void notify(String message, {bool isError = false}) {
    _uiNotificationController.add(AppNotification(message, isError: isError));
  }

  final RequestOtpUseCase requestOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  LoginViewModel(this.requestOtpUseCase, this.verifyOtpUseCase);

  TextEditingController emailController = TextEditingController();
  FocusNode emailFocusNode = FocusNode();

  TextEditingController otpController = TextEditingController();
  FocusNode otpFocusNode = FocusNode();

  bool isLoading = false;
  bool isOtpSent = false;
  String? _otpToken;

  Future<void> sendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      notify("Please enter your email address", isError: true);
      return;
    }

    isLoading = true;
    notifyListeners();

    _otpToken = await requestOtpUseCase.execute(email);

    isLoading = false;
    if (_otpToken != null) {
      isOtpSent = true;
      notify("OTP sent successfully to $email");
    } else {
      notify("Failed to send OTP. Please try again.", isError: true);
    }
    notifyListeners();
  }

  Future<bool> verifyAndLogin() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      notify("Please enter a valid 6-digit code", isError: true);
      return false;
    }
    if (_otpToken == null) {
      notify("Session expired. Please request a new OTP.", isError: true);
      return false;
    }

    isLoading = true;
    notifyListeners();

    final response = await verifyOtpUseCase.execute(
      email: email,
      otp: otp,
      otpToken: _otpToken!,
    );

    print("DEBUG: Verification Response: $response");

    if (response != null) {
      final token = response['accessToken'] ?? '';
      final user = response['user'] as Map<String, dynamic>?;
      final role = user?['role'] ?? 'USER';
      final isAdmin = role.toString().toUpperCase() == 'ADMIN';

      await Prefs.saveSession(
        token: token,
        isAdmin: isAdmin,
        email: email,
      );
      
      isLoading = false;
      notifyListeners();
      return true;
    }

    isLoading = false;
    notify("Invalid OTP code. Please try again.", isError: true);
    notifyListeners();
    return false;
  }

  void resendOtp() {
    sendOtp();
  }

  bool validateOtp() {
    String otp = otpController.text.trim();
    return otp.length == 6 && _otpToken != null;
  }

  bool isAdmin() {
    return emailController.text.contains("admin");
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }
}