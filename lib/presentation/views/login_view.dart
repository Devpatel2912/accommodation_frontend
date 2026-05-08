import 'dart:async';

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
        return LoginViewModel(requestUseCase, verifyUseCase);
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
        AppNotifications.showTopSnackBar(context, n.message, isError: n.isError);
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
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
      backgroundColor: AppColors.bgGrey,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
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
        ],
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── App icon ──
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.teal,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──
          const Text(
            'Accommodation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),

          // ── Email section ──
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const _FieldLabel('Email'),
                const SizedBox(height: 8),
                _EmailField(controller: viewModel.emailController),
                const SizedBox(height: 14),
                _SendOtpButton(viewModel: viewModel),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        // color: AppColors.cardBg,
        // border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

// ── Field label ──────────────────────────────────────────────────
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

// ── Email input ──────────────────────────────────────────────────
class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.email_outlined, color: AppColors.teal, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
              decoration: const InputDecoration(
                hintText: 'name@company.com',
                hintStyle: TextStyle(
                  color: AppColors.hintGrey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 13,
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

// ── Send OTP button ──────────────────────────────────────────────
class _SendOtpButton extends StatelessWidget {
  const _SendOtpButton({required this.viewModel});
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isLoading
            ? null
            : () async {
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
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.teal.withOpacity(0.6),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
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
            color: AppColors.white,
            strokeWidth: 2,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Send OTP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}


// ── Trust item ───────────────────────────────────────────────────
class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.footerGrey, size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.footerGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── Decorative blob ──────────────────────────────────────────────
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

// ── Dot grid ─────────────────────────────────────────────────────
class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 36,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}