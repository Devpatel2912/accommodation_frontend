import 'package:flutter/material.dart';
import 'package:accommodation/core/utils/color.dart';
import 'package:accommodation/core/utils/prefs.dart';
import 'package:accommodation/presentation/views/login_view.dart';
import 'package:accommodation/modules/admin/admin_home_screen.dart';
import 'package:accommodation/modules/user/userhomescreen.dart';
import 'package:accommodation/modules/subadmin/subadmin_home_screen.dart';
import 'package:hugeicons/hugeicons.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final token = await Prefs.getToken();
    final role = await Prefs.getRole();

    if (token != null && token.isNotEmpty) {
      Widget homeScreen;
      if (role == 'ADMIN') {
        homeScreen = const AdminHomeScreen();
      } else if (role == 'SUBADMIN') {
        homeScreen = const SubAdminHomeScreen();
      } else {
        homeScreen = const UserHomeScreen();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => homeScreen),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF05D51),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedHome01,
                            color: Colors.white,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ACCOMMODATION',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Safe & Comfortable Stay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 40,
                  right: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

