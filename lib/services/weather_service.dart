import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_config.dart';

class WeatherService {
  static Future<Map<String, dynamic>> getWeatherForecast(String city, DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0]; // Format date as YYYY-MM-DD
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.BASE_URL}/weather?city=$city&date=$formattedDate',
        ),
      );

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        
        // Parse the weather data from your backend response
        return {
          'temperature': weatherData['temperature'] ?? 0,
          'description': weatherData['description'] ?? 'Unknown',
          'humidity': weatherData['humidity'] ?? 0,
          'windSpeed': weatherData['windSpeed'] ?? 0,
          'icon': weatherData['icon'] ?? '01d',
        };
      } else {
        throw Exception('Failed to load weather data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  static String getTravelAdvice(Map<String, dynamic> weatherData) {
    final temp = weatherData['temperature'];
    final description = weatherData['description'];
    final humidity = weatherData['humidity'];
    final windSpeed = weatherData['windSpeed'];

    String advice = '';

    // Temperature advice
    if (temp < 10) {
      advice += '• It will be quite cold (${temp.toStringAsFixed(1)}°C). Pack warm clothing.\n';
    } else if (temp > 30) {
      advice += '• It will be very hot (${temp.toStringAsFixed(1)}°C). Stay hydrated and use sunscreen.\n';
    } else {
      advice += '• Temperature will be pleasant (${temp.toStringAsFixed(1)}°C).\n';
    }

    // Weather condition advice
    if (description.toLowerCase().contains('rain')) {
      advice += '• Rain is expected. Bring an umbrella and waterproof clothing.\n';
    } else if (description.toLowerCase().contains('snow')) {
      advice += '• Snow is expected. Be prepared for cold conditions and possible travel delays.\n';
    } else if (description.toLowerCase().contains('cloud')) {
      advice += '• Cloudy conditions expected. Good for sightseeing without harsh sunlight.\n';
    } else if (description.toLowerCase().contains('clear')) {
      advice += '• Clear skies expected. Perfect for outdoor activities.\n';
    }

    // Humidity advice
    if (humidity > 80) {
      advice += '• High humidity levels. Stay hydrated and take breaks in air-conditioned areas.\n';
    } else if (humidity < 30) {
      advice += '• Low humidity levels. Use moisturizer and stay hydrated.\n';
    }

    // Wind advice
    if (windSpeed > 20) {
      advice += '• Strong winds expected. Be cautious with outdoor activities.\n';
    }

    return advice;
  }
} 