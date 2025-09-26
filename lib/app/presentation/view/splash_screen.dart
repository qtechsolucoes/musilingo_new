// lib/app/presentation/view/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:musilingo/app/presentation/view/login_screen.dart';
import 'package:musilingo/app/presentation/view/main_navigation_screen.dart';
import 'package:musilingo/app/presentation/widgets/gradient_background.dart';
import 'package:musilingo/app/services/user_session.dart';
import 'package:musilingo/main.dart';
import 'package:provider/provider.dart' as provider;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _redirect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future.delayed(
        const Duration(seconds: 3)); // Um pouco mais de tempo para a animação

    if (!mounted) return;

    final session = supabase.auth.currentSession;
    final userSession = context.read<UserSession>();

    if (session != null) {
      await userSession.initializeSession();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note,
                    color: Color.fromARGB(255, 240, 196, 25), size: 80),
                const SizedBox(height: 20),
                Text(
                  'Musilingo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 240, 196, 25),
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(2, 2),
                      ),
                    ],
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
