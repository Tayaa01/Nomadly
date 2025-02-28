import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'travelresultsscreen.dart';
import 'package:geolocator/geolocator.dart';  // Import Geolocator


class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({super.key});

  @override
  _TravelPreferencesScreenState createState() => _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _activitiesController = TextEditingController();
  String? _departureLocation; // Store GPS location

  bool _isLoading = false;
  String? travelPlan;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  

  

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchCurrentLocation(); // Fetch GPS location on startup

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  /// Fetch the user's current location
  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _departureLocation = "${position.latitude}, ${position.longitude}";
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: ${e.toString()}")),
      );
    }
  }



  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _destinationController.text = prefs.getString('destination') ?? '';
      _budgetController.text = prefs.getString('budget') ?? '';
      _activitiesController.text = prefs.getString('activities') ?? '';
       _departureLocation = prefs.getString('departure') ?? '';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('destination', _destinationController.text);
    await prefs.setString('budget', _budgetController.text);
    await prefs.setString('activities', _activitiesController.text);
      await prefs.setString('departure', _departureLocation ?? '');


  }

  Future<void> generateTravelPlan() async {
    if (_destinationController.text.isEmpty ||
        _budgetController.text.isEmpty ||
        _activitiesController.text.isEmpty ||
        _departureLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _savePreferences();
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/generate_travel_plan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "preferences": {
           "departure": _departureLocation, // Send current location
            "destination": _destinationController.text,
            "budget": _budgetController.text,
            "activities": _activitiesController.text,
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          travelPlan = jsonDecode(response.body)["plan"];
        });
        if (!mounted) return;
        
      } else {
        throw Exception('Failed to generate plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Your Journey"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Where shall we take you?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your preferences and let us create the perfect travel plan for you.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _buildInputSection(colorScheme),
                const SizedBox(height: 32),
                _buildActionButton(),
                if (travelPlan != null) ...[
                  const SizedBox(height: 32),
                  _buildTravelPlanCard(colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _destinationController,
            label: "Where to?",
            icon: Icons.flight_takeoff_rounded,
            hint: "Enter destination",
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _budgetController,
            label: "Your Budget",
            icon: Icons.account_balance_wallet_rounded,
            hint: "Enter amount",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _activitiesController,
            label: "What interests you?",
            icon: Icons.interests_rounded,
            hint: "Enter activities",
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return FilledButton(
      onPressed: _isLoading ? null : generateTravelPlan,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text(
                  "Create My Travel Plan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }

  Widget _buildTravelPlanCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Travel Plan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            travelPlan!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          
              const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TravelResultsScreen(
                    destination: _destinationController.text,

                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined),
                SizedBox(width: 8),
                Text("flights and hotels prices"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    _activitiesController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}  