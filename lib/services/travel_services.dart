import 'package:http/http.dart' as http;
import 'dart:convert';

class TravelServices {
  static const String serperApiKey = "531134ef1831e783c276fd6e8c77f1b5e213a32e";

  // Fetch flights using Serper.dev
  static Future<List<Map<String, dynamic>>> fetchFlights(
    String destination,
  ) async {
    print('[TravelServices] Fetching flights for destination: $destination');
    final response = await http.post(
      Uri.parse("https://google.serper.dev/search"),
      headers: {"X-API-KEY": serperApiKey, "Content-Type": "application/json"},
      body: jsonEncode({
        "q": "cheapest flights from tunisia to $destination",
        "gl": "tn",
        "num": 5,
      }),
    );

    print('[TravelServices] Flights API status code: ${response.statusCode}');
    print('[TravelServices] Flights API response body: ${response.body}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<Map<String, dynamic>> flights = [];

      if (data.containsKey("organic") && data["organic"] is List) {
        for (var result in data["organic"]) {
          flights.add({
            "title": result["title"],
            "link": result["link"],
            "snippet": result["snippet"],
            "price": result["price"], // Ensure price is handled, might be null
          });
        }
      } else {
        print(
          '[TravelServices] "organic" key not found or not a list in flights response.',
        );
      }
      print('[TravelServices] Parsed flights: $flights');
      return flights;
    } else {
      print(
        '[TravelServices] Failed to fetch flights. Status: ${response.statusCode}',
      );
      return [];
    }
  }

  // Fetch hotels using Serper.dev
  static Future<List<Map<String, dynamic>>> fetchHotels(
    String destination,
  ) async {
    print('[TravelServices] Fetching hotels for destination: $destination');
    final response = await http.post(
      Uri.parse("https://google.serper.dev/search"),
      headers: {"X-API-KEY": serperApiKey, "Content-Type": "application/json"},
      body: jsonEncode({
        "q": "cheapest hotels in $destination",
        "num": 5,
        "gl": "tn",
      }),
    );

    print('[TravelServices] Hotels API status code: ${response.statusCode}');
    print('[TravelServices] Hotels API response body: ${response.body}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<Map<String, dynamic>> hotels = [];

      if (data.containsKey("organic") && data["organic"] is List) {
        for (var result in data["organic"]) {
          hotels.add({
            "title": result["title"],
            "link": result["link"],
            "snippet": result["snippet"],
            // Note: Hotels search might not have a direct "price" field like flights in Serper
          });
        }
      } else {
        print(
          '[TravelServices] "organic" key not found or not a list in hotels response.',
        );
      }
      print('[TravelServices] Parsed hotels: $hotels');
      return hotels;
    } else {
      print(
        '[TravelServices] Failed to fetch hotels. Status: ${response.statusCode}',
      );
      return [];
    }
  }
}
