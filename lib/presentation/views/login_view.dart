import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:accommodation/core/utils/notifications.dart';
import 'package:accommodation/presentation/viewmodels/login_viewmodel.dart';
import 'package:accommodation/data/datasources/auth_remote_datasource.dart';
import 'package:accommodation/data/repositories/auth_repository_impl.dart';
import 'package:accommodation/domain/usecases/verify_otp_usecase.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/presentation/views/otp_view.dart';
import 'package:accommodation/domain/usecases/request_otp_usecase.dart';
import 'package:accommodation/modules/admin/admin_home_screen.dart'
    as accommodation_admin;
import 'package:accommodation/modules/subadmin/subadmin_home_screen.dart'
    as accommodation_subadmin;
import 'package:accommodation/modules/user/userhomescreen.dart'
    as accommodation_user;

import 'package:accommodation/core/utils/prefs.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final client = http.Client();
        final remote = AuthRemoteDataSource(client);
        final repo = AuthRepositoryImpl(remote);
        final requestUseCase = RequestOtpUseCase(repo);
        final verifyUseCase = VerifyOtpUseCase(repo);
        return LoginViewModel(requestUseCase, verifyUseCase, repo);
      },
      child: const _LoginScreenContent(),
    );
  }
}

// ── Root screen ──────────────────────────────────────────────────
class _LoginScreenContent extends StatefulWidget {
  const _LoginScreenContent();

  @override
  State<_LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<_LoginScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<LoginViewModel>();
    _notificationSubscription = viewModel.uiNotificationStream.listen((n) {
      if (mounted) {
        AppNotifications.showTopSnackBar(
          context,
          n.message,
          isError: n.isError,
        );
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE2E9DF), Color(0xFFF1D8CF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _LoginCard(viewModel: viewModel),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── White card ───────────────────────────────────────────────────
class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.viewModel});
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── App icon ──
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0C4C51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C3232),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),

          // ── Email section ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email address',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3232),
                ),
              ),
              const SizedBox(height: 8),
              _EmailField(controller: viewModel.emailController),

              const SizedBox(height: 24),
              _ActionButton(viewModel: viewModel),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Email input ──────────────────────────────────────────────────
class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD0D5D5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFF869292),
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2C3232)),
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                hintStyle: TextStyle(color: Color(0xFF869292), fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.viewModel});
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isLoading
            ? null
            : () async {
                if (viewModel.isPasswordLogin) {
                  final success = await viewModel.loginWithPassword();
                  if (!context.mounted) return;
                  if (success) {
                    final role = await Prefs.getRole();
                    Widget homeScreen;
                    if (role == 'ADMIN') {
                      homeScreen = const accommodation_admin.AdminHomeScreen();
                    } else if (role == 'SUBADMIN') {
                      homeScreen =
                          const accommodation_subadmin.SubAdminHomeScreen();
                    } else {
                      homeScreen = const accommodation_user.UserHomeScreen();
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => homeScreen),
                      (route) => false,
                    );
                  }
                } else {
                  await viewModel.sendOtp();
                  if (!context.mounted) return;
                  if (viewModel.isOtpSent) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: viewModel,
                          child: const OtpView(),
                        ),
                      ),
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF05D51),
          disabledBackgroundColor: const Color(0xFFF05D51).withOpacity(0.6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: viewModel.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Get OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: const Color(0xFFABC4C1), radius: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFECF3F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF869292),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    Path dashPath = Path();
    double dashWidth = 5.0;
    double dashSpace = 4.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
