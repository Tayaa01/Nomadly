import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/currency_converter_screen.dart';
import 'views/welcome_page.dart';
import 'views/sign_in_page.dart';
import 'views/home_page.dart';
import 'views/speech_to_text_view.dart';
import 'views/tips_screen.dart';
import 'views/sign_up_page.dart';
import 'services/auth_service.dart';
import 'views/statistics_screen.dart';
import 'views/profile_screen.dart';
import 'views/travel_preferences.dart';
import 'views/travelResultsScreen.dart';
import 'package:provider/provider.dart';
import 'providers/destination_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DestinationProvider()),
        // Add other providers as needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _checkStartupLogic();
  }

  Future<void> _checkStartupLogic() async {
    Widget startScreen;

    // Check if user is logged in
    try {
      bool isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        print('User is logged in, showing home page');
        startScreen = const HomePage();
      } else {
        // User is not logged in, show sign-in page
        print('User is not logged in, showing sign-in page');
        startScreen = const SignInPage();

        // Check if this is a new installation (no preferences exist at all)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

        if (!hasSeenWelcome) {
          // First time ever opening the app
          print('First installation, showing welcome page');
          startScreen = const WelcomePage();

          // Mark that user has seen welcome page
          await prefs.setBool('has_seen_welcome', true);
        }
      }
    } catch (e) {
      print('Error during startup check: $e');
      startScreen = const SignInPage(); // Default to sign-in on error
    }

    // Only update state if widget is still mounted
    if (mounted) {
      setState(() {
        _startScreen = startScreen;
        _isLoading = false;
      });
    }
  }

  // Theme definitions
  ThemeData get _lightTheme => ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      surface: const Color(0xFFF5F5F5),
      primary: const Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      secondary: const Color(0xFF666666),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1E1E1E)),
      bodyMedium: TextStyle(color: Color(0xFF666666)),
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: ColorScheme.dark(
      surface: const Color(0xFF1E1E1E),
      primary: const Color(0xFFF2F2F2),
      onPrimary: const Color(0xFF000000),
      secondary: const Color(0xFFA5A5A5),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
      bodyMedium: TextStyle(color: Color(0xFFA5A5A5)),
    ),
  );

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Nomadly',
      theme: isDarkMode ? _darkTheme : _lightTheme,
      debugShowCheckedModeBanner: false,
      home: _startScreen,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/sign-in': (context) => const SignInPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/currency-converter':
            (context) => CurrencyConverterScreen(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
        '/translation': (context) => const SpeechToTextView(),
        '/tips': (context) => const TipsScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/planner':
            (context) => const TravelPreferencesScreen(), // Add this route
        '/travel-results':
            (context) => TravelResultsScreen(destination: ''), // Add this route
      },
    );
  }
}
