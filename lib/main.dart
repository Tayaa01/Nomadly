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
import 'views/request_reset_screen.dart'; // Fixed import path
import 'views/reset_password_screen.dart'; // Fixed import path
import 'package:flutter/services.dart';
import 'utils/country_currency_util.dart'; // Import CountryCurrencyUtil
import 'providers/auth_provider.dart'; // Import AuthProvider
import 'views/finish_setup_page.dart'; // Import FinishSetupPage
import 'models/user.dart'; // Import the User model

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style to dark from the very beginning
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize the country-currency mapping
  await CountryCurrencyUtil.initialize();

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
        ChangeNotifierProvider(create: (_) => AuthProvider()), // <-- added
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
  // Always use dark mode
  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
  }

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

  // We're only using dark theme

  void toggleTheme() {
    // Do nothing - always staying in dark mode
    // Kept for compatibility
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return _buildLoadingScreen();
        }

        if (authProvider.isLoggedIn) {
          return FutureBuilder<bool>(
            future: _checkProfileCompleteness(authProvider.user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              if (snapshot.hasError) {
                print("Error checking profile completeness: ${snapshot.error}");
                return _buildMaterialApp(const SignInPage());
              }

              final isProfileComplete = snapshot.data ?? false;
              if (isProfileComplete) {
                return _buildMaterialApp(const HomePage());
              } else {
                return _buildMaterialApp(const FinishSetupPage());
              }
            },
          );
        } else {
          return FutureBuilder<bool>(
            future: _hasSeenWelcomePage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              if (snapshot.hasError) {
                print("Error checking welcome status: ${snapshot.error}");
                return _buildMaterialApp(const SignInPage());
              }

              final hasSeenWelcome = snapshot.data ?? false;
              if (!hasSeenWelcome) {
                _markWelcomePageSeen();
                return _buildMaterialApp(const WelcomePage());
              } else {
                return _buildMaterialApp(const SignInPage());
              }
            },
          );
        }
      },
    );
  }

  Widget _buildMaterialApp(Widget home) {
    return MaterialApp(
      title: 'Nomadly',
      theme: _darkTheme, // Always use dark theme for main theme
      darkTheme: _darkTheme, // Set dark theme explicitly
      themeMode: ThemeMode.dark, // Force dark theme mode
      debugShowCheckedModeBanner: false,
      home: home,
      onGenerateRoute: _onGenerateRoute,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/sign-in': (context) => const SignInPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/finish-setup': (context) => const FinishSetupPage(),
        '/request-reset': (context) => const RequestResetScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/currency-converter':
            (context) => CurrencyConverterScreen(
              toggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
        '/translation': (context) => const SpeechToTextView(),
        '/travel-deals': (context) => DealsScreen(isDarkMode: isDarkMode),
        '/deal-hunting': (context) => const DealHuntingScreen(),
        '/tips': (context) => const TipsScreen(),
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
        '/weather-forecast': (context) => const WeatherForecastScreen(),
      },
    );
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _darkTheme, // Use the dark theme
      darkTheme: _darkTheme, // Set dark theme explicitly
      themeMode: ThemeMode.dark, // Force dark theme
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or branding can be added here
              Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const SizedBox(height: 100, width: 100),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _checkProfileCompleteness(User? user) async {
    if (user == null) {
      return false;
    }
    return user.firstName.isNotEmpty &&
        user.lastName.isNotEmpty &&
        user.countryCode.isNotEmpty;
  }

  Future<bool> _hasSeenWelcomePage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_seen_welcome') ?? false;
    } catch (e) {
      print("Error reading welcome status: $e");
      return false;
    }
  }

  Future<void> _markWelcomePageSeen() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);
    } catch (e) {
      print("Error saving welcome status: $e");
    }
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    if (settings.name != null &&
        (settings.name == '/' || settings.name!.startsWith('/?'))) {
      return MaterialPageRoute(builder: (_) => const SignInPage());
    }

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SignInPage());
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
        );
      case '/deal-hunting':
        return MaterialPageRoute(builder: (_) => const DealHuntingScreen());
      case '/planner':
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
      case '/finish-setup':
        return MaterialPageRoute(builder: (_) => const FinishSetupPage());
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
