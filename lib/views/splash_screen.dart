import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'sign_in_page.dart';
import 'welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate after showing splash screen
    Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      bool isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        _navigateTo(const HomePage());
      } else {
        // Check if first time opening the app
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

        if (!hasSeenWelcome) {
          await prefs.setBool('has_seen_welcome', true);
          _navigateTo(const WelcomePage());
        } else {
          _navigateTo(const SignInPage());
        }
      }
    } catch (e) {
      print('Error during authentication check: $e');
      _navigateTo(const SignInPage());
    }
  }

  void _navigateTo(Widget destination) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => destination));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logodark.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
