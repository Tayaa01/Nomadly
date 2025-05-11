import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final String _themeKey = 'is_dark_mode';

  ThemeProvider() {
    // Always ensure dark mode is set
    _ensureDarkMode();
  }

  bool get isDarkMode => true; // Always return true

  Future<void> _ensureDarkMode() async {
    // Set dark mode to always be true in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, true);
    notifyListeners();
  }

  // Keep this method but make it do nothing - for compatibility
  Future<void> toggleTheme() async {
    // Do nothing, we're staying in dark mode
    notifyListeners();
  }

  ThemeData get theme => darkTheme; // Always return dark theme

  static final darkTheme = ThemeData(
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.black,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: Colors.green,
      secondary: Colors.greenAccent,
    ),
  );

  // Keep the lightTheme definition for compatibility, but it won't be used
  static final lightTheme = ThemeData(
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.black, // Changed to black
    brightness: Brightness.dark, // Changed to dark
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Changed to black
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      // Changed to dark
      primary: Colors.green,
      secondary: Colors.greenAccent,
    ),
  );
}
