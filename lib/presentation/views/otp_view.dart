import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/notifications.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/modules/admin/admin_home_screen.dart';
import 'package:accommodation/modules/user/userhomescreen.dart';
import 'package:accommodation/presentation/viewmodels/login_viewmodel.dart';
import 'package:accommodation/modules/subadmin/subadmin_home_screen.dart';
import 'package:pinput/pinput.dart';

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<LoginViewModel>();
    _notificationSubscription = viewModel.uiNotificationStream.listen((n) {
      if (mounted) {
        AppNotifications.showTopSnackBar(context, n.message, isError: n.isError);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.teal, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.bgGrey.withOpacity(0.5),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -40,
            right: -30,
            child: _Blob(size: 160, color: AppColors.tealLight),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: _Blob(size: 130, color: AppColors.tealLight),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          color: AppColors.tealLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: AppColors.teal,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a 6-digit code to\n${viewModel.emailController.text}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.labelGrey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _FieldLabel('Verification Code'),
                                GestureDetector(
                                  onTap: () async {
                                      await viewModel.sendOtp();
                                    },
                                  child: const Text(
                                    'Resend code',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Pinput(
                                length: 6,
                                controller: viewModel.otpController,
                                focusNode: viewModel.otpFocusNode,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: focusedPinTheme,
                                submittedPinTheme: submittedPinTheme,
                                hapticFeedbackType: HapticFeedbackType.lightImpact,
                                onCompleted: (pin) {
                                  // Optionally auto-verify here
                                },
                                cursor: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 9),
                                      width: 22,
                                      height: 1,
                                      color: AppColors.teal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            _VerifyButton(viewModel: viewModel),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.teal,
        letterSpacing: 1.2,
      ),
    );
  }
}



class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.viewModel});
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isLoading
            ? null
            : () async {
                final success = await viewModel.verifyAndLogin();
                if (!context.mounted) return;

                if (success) {
                  final role = await Prefs.getRole();
                  Widget homeScreen;
                  if (role == 'ADMIN') {
                    homeScreen = const AdminHomeScreen();
                  } else if (role == 'SUBADMIN') {
                    homeScreen = const SubAdminHomeScreen();
                  } else {
                    homeScreen = const UserHomeScreen();
                  }
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => homeScreen),
                    (route) => false,
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: viewModel.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
              )
            : const Text(
                'Verify & Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// class _TrustBadge extends StatelessWidget {
//   const _TrustBadge();
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.footerGrey),
//         const SizedBox(width: 6),
//         const Text(
//           'Secure 256-bit SSL encrypted connection',
//           style: TextStyle(fontSize: 10, color: AppColors.footerGrey),
//         ),
//       ],
//     );
//   }
// }

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
