import 'package:flutter/material.dart';
import 'travel_preferences.dart';

void main() {
  runApp(TravelPlannerApp());
}

class TravelPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system, // Auto-switch based on system setting
      home: TravelPreferencesScreen(),
    );
  }
}
