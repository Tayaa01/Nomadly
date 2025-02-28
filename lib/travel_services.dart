import 'package:http/http.dart' as http;
import 'dart:convert';

class TravelServices {
  static const String serperApiKey = "b6e7935b4ea8abba16d7330df0d54c487abf24f0";

  // Fetch flights using Serper.dev
  static Future<List<Map<String, dynamic>>> fetchFlights(String destination ) async {
    final response = await http.post(
      Uri.parse("https://google.serper.dev/search"),
      headers: {
        "X-API-KEY": serperApiKey,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "q": "cheapest flights from tunisia to $destination",
        "gl": "tn",
        "num": 5
        
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<Map<String, dynamic>> flights = [];

      for (var result in data["organic"]) {
        flights.add({
          "title": result["title"],
          "link": result["link"],
          "snippet": result["snippet"],
          "price": result["price"]

        });
      }

      return flights;
    } else {
      return [];
    }
  }

  // Fetch hotels using Serper.dev
  static Future<List<Map<String, dynamic>>> fetchHotels(String destination ) async {
    final response = await http.post(
      Uri.parse("https://google.serper.dev/search"),
      headers: {
        "X-API-KEY": serperApiKey,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "q": "cheapest hotels in $destination",
        "num": 5,
        "gl": "tn"
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<Map<String, dynamic>> hotels = [];

      for (var result in data["organic"]) {
        hotels.add({
          "title": result["title"],
          "link": result["link"],
          "snippet": result["snippet"]
        });
      }

      return hotels;
    } else {
      return [];
    }
  }
}
