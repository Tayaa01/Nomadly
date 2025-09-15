import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherService {
  static Future<Map<String, dynamic>> getWeatherFullForecast(
      double latitude, double longitude) async {
    try {
      // Fetch data for the next 7 days (API standard)
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 6));
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      // Request current weather, daily summaries, and hourly details
      final url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=$latitude&longitude=$longitude'
          '&current=temperature_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code' // Current weather fields
          '&hourly=temperature_2m,precipitation_probability,weather_code' // Hourly fields for next ~24-48h usually
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum' // Daily summary fields
          '&start_date=$formattedStartDate&end_date=$formattedEndDate'
          '&timezone=auto'; // Use auto timezone detection

      print('Fetching full weather from: $url');

      final response = await http.get(Uri.parse(url));

      print('Weather API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Basic validation
        if (data == null || data['current'] == null || data['daily'] == null || data['hourly'] == null || data['timezone'] == null || data['utc_offset_seconds'] == null) {
           throw Exception('Incomplete weather or timezone data received from API.');
        }

        // Process Hourly Data (filter for relevant timeframe, e.g., next 24 hours)
        final List<Map<String, dynamic>> hourlyForecast = [];
        if (data['hourly'] != null && data['hourly']['time'] != null) {
           final List<dynamic> times = data['hourly']['time'];
           final List<dynamic> temps = data['hourly']['temperature_2m'];
           final List<dynamic> codes = data['hourly']['weather_code'];
           // final List<dynamic> probs = data['hourly']['precipitation_probability']; // Optional: Precipitation probability

           final now = DateTime.now();
           final next24Hours = now.add(const Duration(hours: 24));

           for (int i = 0; i < times.length; i++) {
              final time = DateTime.parse(times[i]);
              // Only include hours from now up to 24 hours ahead
              if (time.isAfter(now.subtract(const Duration(minutes: 30))) && time.isBefore(next24Hours)) {
                 hourlyForecast.add({
                    'time': time.toIso8601String(),
                    'temp': (temps[i] as num?)?.toDouble() ?? 0.0,
                    'weather_code': (codes[i] as num?)?.toInt() ?? 0,
                    // 'precip_prob': (probs[i] as num?)?.toInt() ?? 0, // Optional
                 });
              }
           }
        }


        // Process Daily Data
        final List<Map<String, dynamic>> dailyForecast = [];
         if (data['daily'] != null && data['daily']['time'] != null) {
            final List<dynamic> dates = data['daily']['time'];
            final List<dynamic> codes = data['daily']['weather_code'];
            final List<dynamic> maxTemps = data['daily']['temperature_2m_max'];
            final List<dynamic> minTemps = data['daily']['temperature_2m_min'];
            final List<dynamic> rainSums = data['daily']['precipitation_sum'];
            final List<dynamic> snowSums = data['daily']['snowfall_sum'];

            for (int i = 0; i < dates.length; i++) {
               dailyForecast.add({
                  'date': dates[i],
                  'weather_code': (codes[i] as num?)?.toInt() ?? 0,
                  'maxTemp': (maxTemps[i] as num?)?.toDouble() ?? 0.0,
                  'minTemp': (minTemps[i] as num?)?.toDouble() ?? 0.0,
                  'totalRain': (rainSums[i] as num?)?.toDouble() ?? 0.0, // API provides daily sum
                  'totalSnow': (snowSums[i] as num?)?.toDouble() ?? 0.0, // API provides daily sum
               });
            }
         }

        return {
          'current': data['current'],
          'daily': dailyForecast, // Use the processed daily list
          'hourly': hourlyForecast, // Use the processed hourly list
          'timezone': data['timezone'], // Pass timezone name
          'utc_offset_seconds': data['utc_offset_seconds'], // Pass UTC offset
        };

      } else {
        // ... (Error handling remains the same) ...
        String errorMessage = response.body;
        try {
          final errorData = json.decode(response.body);
          if (errorData['reason'] != null) {
            errorMessage = errorData['reason'];
          }
        } catch (_) {}
        throw Exception('Failed to load weather data: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error in getWeatherFullForecast: $e');
      throw Exception('Error fetching or processing weather data: $e');
    }
  }

  // Helper to get description and icon from WMO Weather Code
  static Map<String, String> getWeatherInfoFromCode(int code, {bool isDay = true}) {
    String description;
    String iconCode;

    switch (code) {
      case 0:
        description = 'Clear sky';
        iconCode = isDay ? '01d' : '01n';
        break;
      case 1:
        description = 'Mainly clear';
        iconCode = isDay ? '02d' : '02n';
        break;
      case 2:
        description = 'Partly cloudy';
        iconCode = isDay ? '03d' : '03n';
        break;
      case 3:
        description = 'Overcast';
        iconCode = '04d'; // Often same day/night
        break;
      case 45:
        description = 'Fog';
        iconCode = '50d';
        break;
      case 48:
        description = 'Depositing rime fog';
        iconCode = '50d';
        break;
      case 51:
        description = 'Light drizzle';
        iconCode = '09d';
        break;
      case 53:
        description = 'Moderate drizzle';
        iconCode = '09d';
        break;
      case 55:
        description = 'Dense drizzle';
        iconCode = '09d';
        break;
      case 56:
        description = 'Light freezing drizzle';
        iconCode = '09d'; // Combine with freezing icon?
        break;
      case 57:
        description = 'Dense freezing drizzle';
        iconCode = '09d';
        break;
      case 61:
        description = 'Slight rain';
        iconCode = '10d';
        break;
      case 63:
        description = 'Moderate rain';
        iconCode = '10d';
        break;
      case 65:
        description = 'Heavy rain';
        iconCode = '10d';
        break;
      case 66:
        description = 'Light freezing rain';
        iconCode = '13d'; // Use snow/freezing icon
        break;
      case 67:
        description = 'Heavy freezing rain';
        iconCode = '13d';
        break;
      case 71:
        description = 'Slight snow fall';
        iconCode = '13d';
        break;
      case 73:
        description = 'Moderate snow fall';
        iconCode = '13d';
        break;
      case 75:
        description = 'Heavy snow fall';
        iconCode = '13d';
        break;
      case 77:
        description = 'Snow grains';
        iconCode = '13d';
        break;
      case 80:
        description = 'Slight rain showers';
        iconCode = '09d';
        break;
      case 81:
        description = 'Moderate rain showers';
        iconCode = '09d';
        break;
      case 82:
        description = 'Violent rain showers';
        iconCode = '09d';
        break;
      case 85:
        description = 'Slight snow showers';
        iconCode = '13d';
        break;
      case 86:
        description = 'Heavy snow showers';
        iconCode = '13d';
        break;
      case 95:
        description = 'Thunderstorm';
        iconCode = '11d';
        break;
      case 96:
        description = 'Thunderstorm with slight hail';
        iconCode = '11d';
        break;
      case 99:
        description = 'Thunderstorm with heavy hail';
        iconCode = '11d';
        break;
      default:
        description = 'Unknown';
        iconCode = isDay ? '01d' : '01n';
    }
    return {'description': description, 'icon': iconCode};
  }

  // Keep old methods if they are used elsewhere, otherwise they can be removed
  // static Future<List<Map<String, dynamic>>> getWeatherForecastRange(...) { ... }
  // static String _getWeatherIcon(String description) { ... }
  // static String getTravelAdvice(Map<String, dynamic> weatherData) { ... }
}