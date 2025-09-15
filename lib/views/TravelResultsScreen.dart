import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '/services/travel_services.dart';

class TravelResultsScreen extends StatefulWidget {
  final String destination;

  const TravelResultsScreen({super.key, required this.destination});

  @override
  _TravelResultsScreenState createState() => _TravelResultsScreenState();
}

class _TravelResultsScreenState extends State<TravelResultsScreen> {
  List<Map<String, dynamic>> flights = [];
  List<Map<String, dynamic>> hotels = [];
  bool isLoadingFlights = true;
  bool isLoadingHotels = true;

  @override
  void initState() {
    super.initState();
    _fetchTravelData();
  }

  Future<void> _fetchTravelData() async {
    flights = await TravelServices.fetchFlights(widget.destination);
    hotels = await TravelServices.fetchHotels(widget.destination);

    // Sort flights by price if available
    flights.sort((a, b) => (a['price'] ?? double.infinity).compareTo(b['price'] ?? double.infinity));

    setState(() {
      isLoadingFlights = false;
      isLoadingHotels = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Travel Options: ${widget.destination}")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Flights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              isLoadingFlights
                  ? Center(child: CircularProgressIndicator())
                  : flights.isEmpty
                      ? Text("No flights found.")
                      : Column(
                          children: flights.map((flight) {
                            bool isCheapest = flight == flights.first;
                            return Card(
                              color: isCheapest ? Colors.green[100] : null, // Highlight the cheapest flight
                              child: ListTile(
                                title: Text(flight['title']),
                                subtitle: Text("${flight['snippet']}\nPrice: ${flight['price'] ?? 'N/A'}"),
                                trailing: Icon(Icons.flight),
                                onTap: () => _launchURL(flight['link']),
                              ),
                            );
                          }).toList(),
                        ),
              SizedBox(height: 20),
              
              Text("Hotels", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              isLoadingHotels
                  ? Center(child: CircularProgressIndicator())
                  : hotels.isEmpty
                      ? Text("No hotels found.")
                      : Column(
                          children: hotels.map((hotel) {
                            return Card(
                              child: ListTile(
                                title: Text(hotel['title']),
                                subtitle: Text(hotel['snippet']),
                                trailing: Icon(Icons.hotel),
                                onTap: () => _launchURL(hotel['link']),
                              ),
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
