import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'TravelResultsScreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import '/config/secrets.dart';
import '../widgets/app_drawer.dart'; // Add this import

// Add GoogleAuthClient class at the top level
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

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
  
  // Store itinerary data
  List<dynamic>? itineraryData;
  bool showActivities = false; // State variable to toggle between location and activities

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
    clientId: Secrets.googleClientId,
  );

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
          var responseData = jsonDecode(response.body);
          travelPlan = responseData["trip_name"];
          itineraryData = responseData["day_itinerary"];
        });
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

  Widget _buildItineraryTable() {
    if (itineraryData == null) return const SizedBox(); // No data to show

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: DataTable(
          key: ValueKey<bool>(showActivities),
          columns: const [
            DataColumn(label: Text('Day')),
            DataColumn(label: Text('Location/Activities')),
            DataColumn(label: Text('Estimated Cost')),
          ],
          rows: itineraryData!.map<DataRow>((day) {
            return DataRow(
              cells: [
                DataCell(Text(day["day"].toString())),
                DataCell(
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showActivities = !showActivities;
                      });
                    },
                    child: Text(showActivities ? day["activities"].join(", ") : day["title"]),
                  ),
                ),
                DataCell(Text("\$${day["estimated_cost"]}")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Travel Planner',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Simply pop back to home screen
            Navigator.of(context).pop();
          },
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/planner'), // Add drawer 
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
                  const SizedBox(height: 32),
                  if (itineraryData != null) ...[
                    const SizedBox(height: 32),
                    _buildItineraryTable(),
                    const SizedBox(height: 32),
                    _buildBudgetChart(),  // Add the chart here
                  ],
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
        color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : generateTravelPlan,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.green, // Change the button color to green
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Create My Travel Plan'),
    );
  }

 Widget _buildBudgetChart() {
  if (itineraryData == null || itineraryData!.isEmpty) {
    return const SizedBox();
  }

  List<PieChartSectionData> sections = itineraryData!.map((day) {
    return PieChartSectionData(
      color: Colors.primaries[day["day"] % Colors.primaries.length],
      value: day["estimated_cost"].toDouble(),
      title: "\$${day["estimated_cost"]}",
      radius: 55, // Increased for better visibility
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      badgeWidget: _buildBadge(day["day"]),
      badgePositionPercentageOffset: 1.2, // Adjusted positioning
    );
  }).toList();

  return Container(
    height: 280, // Slightly taller for better spacing
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color.fromARGB(46, 118, 168, 120),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 3),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Budget Breakdown",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              centerSpaceRadius: 45,
              sectionsSpace: 3,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// 🎯 Badge Widget for Each Section
Widget _buildBadge(int day) {
  return Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 2),
      ],
    ),
    child: Text(
      "Day $day",
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
    ),
  );
}

Future<void> _exportToGoogleCalendar() async {
  try {
    if (itineraryData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No itinerary data to export')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Sign in with Google
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign in cancelled');
      }

      // Get auth credentials
      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.accessToken == null) {
        throw Exception('Failed to get access token');
      }

      // Create HTTP client with auth headers
      final Map<String, String> headers = {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Accept': 'application/json',
      };
      final httpClient = GoogleAuthClient(headers);
      final calendarApi = calendar.CalendarApi(httpClient);

      // Create events for each day in the itinerary
      for (var day in itineraryData!) {
        final startTime = DateTime.now().add(Duration(days: day['day'] - 1));
        final endTime = startTime.add(const Duration(days: 1));

        final event = calendar.Event(
          summary: day['title'],
          description: 'Activities: ${day['activities'].join(", ")}\nEstimated Cost: \$${day['estimated_cost']}',
          start: calendar.EventDateTime(
            dateTime: startTime,
            timeZone: 'UTC',
          ),
          end: calendar.EventDateTime(
            dateTime: endTime,
            timeZone: 'UTC',
          ),
        );

        await calendarApi.events.insert(event, 'primary');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully exported to Google Calendar!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      print('Google Calendar Export Error: $e');
    }
  } finally {
    setState(() => _isLoading = false);
  }
}

  Widget _buildTravelPlanCard(ColorScheme colorScheme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      color: const Color.fromARGB(146, 167, 190, 168),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              travelPlan ?? '',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your personalized travel plan has been generated!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.tonal(
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flight_takeoff_rounded, size: 20),
                          Icon(Icons.hotel, size: 20),
                          SizedBox(width: 4),
                          Text("Prices", overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.tonal(
                      onPressed: _isLoading ? null : _exportToGoogleCalendar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.blue,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const Icon(Icons.calendar_month, size: 20),
                          const SizedBox(width: 4),
                          const Text("Calendar", overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
