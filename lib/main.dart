import 'package:flutter/material.dart';
import 'package:nomadly/views/deal_hunting_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/currency_converter_screen.dart';
import 'views/welcome_page.dart';
import 'views/sign_in_page.dart';
import 'views/home_page.dart';
import 'views/speech_to_text_view.dart';
import 'views/deals_screen.dart';
import 'views/tips_screen.dart'; // Add this import for TipsScreen
import 'views/sign_up_page.dart';
import 'services/auth_service.dart';
import 'views/statistics_screen.dart';
import 'views/profile_screen.dart';
import 'views/travelResultsScreen.dart';
import 'package:provider/provider.dart';
import 'providers/destination_provider.dart';
import 'views/expense_tracker_screen.dart';
import 'views/travel_groups_screen.dart';
import 'viewmodels/expense_viewmodel.dart';
import 'viewmodels/currency_viewmodel.dart';
import 'viewmodels/travel_group_viewmodel.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/travel_form_screen.dart';
import 'screens/weather_forecast_screen.dart'; // Import the new screen
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DestinationProvider()),
        // Add other providers as needed
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => CurrencyViewModel()),
        ChangeNotifierProvider(create: (_) => TravelGroupViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider('haddari')),
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
      onGenerateRoute: _onGenerateRoute,
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
        '/travel-deals':
            (context) => DealsScreen(
              isDarkMode: isDarkMode,
            ), // Fixed: Added isDarkMode parameter
        '/deal-hunting':
            (context) =>
                const DealHuntingScreen(), // New route for Deal Hunting
        '/tips': (context) => const TipsScreen(), // Add this route for tips
        '/statistics': (context) => const StatisticsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/planner': (context) => const TravelFormScreen(),
        '/travel-results': (context) => TravelResultsScreen(destination: ''),
        '/expense-tracker':
            (context) => ExpenseTrackerScreen(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
        '/travel-groups':
            (context) => TravelGroupsScreen(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
        '/weather-forecast':
            (context) => const WeatherForecastScreen(), // Add the new route
      },
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => _startScreen ?? const SignInPage(),
        );
      case '/login':
        return MaterialPageRoute(builder: (_) => const SignInPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/travel-deals':
        return MaterialPageRoute(
          builder: (_) => DealsScreen(isDarkMode: isDarkMode),
        ); // Fixed: Added isDarkMode parameter
      case '/deal-hunting':
        return MaterialPageRoute(builder: (_) => const DealHuntingScreen());
      case '/planner':
        // Use PageRouteBuilder for a custom transition
        return PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  const TravelFormScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
      // ...existing code for other routes...
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
