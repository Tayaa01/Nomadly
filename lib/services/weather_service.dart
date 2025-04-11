import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_config.dart';

class WeatherService {
  static Future<Map<String, dynamic>> getWeatherForecast(String city, DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0]; // Format date as YYYY-MM-DD
      final url = '${ApiConfig.BASE_URL}/travel?city=$city&date=$formattedDate';
      print('Fetching weather from: $url'); // Debug log

      final response = await http.get(Uri.parse(url));

      print('Weather API Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        // Parse the text response to extract weather information
        final lines = response.body.split('\n');
        double avgTemp = 0;
        String description = '';
        int count = 0;

        for (final line in lines) {
          if (line.contains('°C')) {
            final parts = line.split(',');
            if (parts.length >= 2) {
              final tempStr = parts[0].split(':')[1].trim().replaceAll('°C', '');
              final temp = double.tryParse(tempStr) ?? 0;
              avgTemp += temp;
              description = parts[1].trim();
              count++;
            }
          }
        }

        if (count > 0) {
          avgTemp = avgTemp / count;
        }

        return {
          'temperature': avgTemp,
          'description': description,
          'humidity': 0,
          'windSpeed': 0,
          'icon': _getWeatherIcon(description),
          'forecast': response.body, // Store the full forecast text
        };
      } else {
        throw Exception('Failed to load weather data: ${response.body}');
      }
    } catch (e) {
      print('Error in getWeatherForecast: $e'); // Debug log
      throw Exception('Error fetching weather data: $e');
    }
  }

  static String _getWeatherIcon(String description) {
    if (description.toLowerCase().contains('rain')) {
      return '10d';
    } else if (description.toLowerCase().contains('cloud')) {
      return '03d';
    } else if (description.toLowerCase().contains('clear')) {
      return '01d';
    } else if (description.toLowerCase().contains('snow')) {
      return '13d';
    } else {
      return '01d';
    }
  }

  static String getTravelAdvice(Map<String, dynamic> weatherData) {
    try {
      final temp = weatherData['temperature'];
      final description = weatherData['description'];
      final forecast = weatherData['forecast'] ?? '';

      print('Weather data for advice: $weatherData'); // Debug log

      String advice = '• Weather forecast:\n$forecast\n\n';

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

      return advice;
    } catch (e) {
      print('Error in getTravelAdvice: $e'); // Debug log
      return '• Weather information is currently unavailable. Please try again later.\n';
    }
  }
} 