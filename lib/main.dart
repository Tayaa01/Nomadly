import 'package:flutter/material.dart';
import 'views/currency_converter_screen.dart';
import 'views/welcome_page.dart';
import 'views/sign_in_page.dart';
import 'views/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;

  ThemeData get lightTheme => ThemeData(
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

  ThemeData get darkTheme => ThemeData(
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
    return MaterialApp(
      title: 'Currency Converter',
      theme: isDarkMode ? darkTheme : lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/sign-in': (context) => const SignInPage(),
        '/currency-converter': (context) => CurrencyConverterScreen(
          toggleTheme: toggleTheme,
          isDarkMode: isDarkMode,
        ),
        '/home': (context) => const HomePage(),
        // Add other routes here
      },
    );
  }
}
