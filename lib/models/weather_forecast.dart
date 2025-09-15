
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WeatherForecast {
  final DateTime date;
  final int weatherCode; // WMO Weather interpretation codes
  final double maxTemperature;
  final double minTemperature;
  final double precipitation; // Total daily precipitation sum
  final Map<int, double> hourlyTemperatures; // Map<Hour (0-23), Temperature>

  WeatherForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemperature,
    required this.minTemperature,
    required this.precipitation,
    required this.hourlyTemperatures,
  });

  // Get a human-readable summary based on the weather code
  String get summary {
    // WMO Code descriptions (simplified)
    switch (weatherCode) {
      case 0: return 'Clear sky';
      case 1: return 'Mainly clear';
      case 2: return 'Partly cloudy';
      case 3: return 'Overcast';
      case 45: return 'Fog';
      case 48: return 'Depositing rime fog';
      case 51: return 'Light drizzle';
      case 53: return 'Moderate drizzle';
      case 55: return 'Dense drizzle';
      case 56: return 'Light freezing drizzle';
      case 57: return 'Dense freezing drizzle';
      case 61: return 'Slight rain';
      case 63: return 'Moderate rain';
      case 65: return 'Heavy rain';
      case 66: return 'Light freezing rain';
      case 67: return 'Heavy freezing rain';
      case 71: return 'Slight snow fall';
      case 73: return 'Moderate snow fall';
      case 75: return 'Heavy snow fall';
      case 77: return 'Snow grains';
      case 80: return 'Slight rain showers';
      case 81: return 'Moderate rain showers';
      case 82: return 'Violent rain showers';
      case 85: return 'Slight snow showers';
      case 86: return 'Heavy snow showers';
      case 95: return 'Thunderstorm'; // Slight or moderate
      case 96: return 'Thunderstorm with slight hail';
      case 99: return 'Thunderstorm with heavy hail';
      default: return 'Unknown ($weatherCode)';
    }
  }

  // Get an icon based on the weather code
  IconData get iconData {
     switch (weatherCode) {
      case 0: return FontAwesomeIcons.sun; // Clear sky
      case 1: return FontAwesomeIcons.cloudSun; // Mainly clear
      case 2: return FontAwesomeIcons.cloud; // Partly cloudy
      case 3: return FontAwesomeIcons.cloud; // Overcast
      case 45: case 48: return FontAwesomeIcons.smog; // Fog
      case 51: case 53: case 55: return FontAwesomeIcons.cloudRain; // Drizzle
      case 56: case 57: return FontAwesomeIcons.snowflake; // Freezing Drizzle (use snow icon)
      case 61: case 63: case 65: return FontAwesomeIcons.cloudShowersHeavy; // Rain
      case 66: case 67: return FontAwesomeIcons.cloudRain; // Freezing Rain (use rain icon)
      case 71: case 73: case 75: case 77: return FontAwesomeIcons.snowflake; // Snow
      case 80: case 81: case 82: return FontAwesomeIcons.cloudShowersHeavy; // Rain showers
      case 85: case 86: return FontAwesomeIcons.snowflake; // Snow showers
      case 95: case 96: case 99: return FontAwesomeIcons.cloudBolt; // Thunderstorm
      default: return FontAwesomeIcons.questionCircle; // Unknown
    }
  }

   // Get an icon code string (similar to old format if needed)
   String get iconCode {
     // Map WMO codes to approximate OpenWeatherMap-like codes if needed elsewhere
     // This is a simplified mapping
     switch (weatherCode) {
       case 0: return '01d'; // Clear sky -> sun
       case 1: return '02d'; // Mainly clear -> few clouds
       case 2: return '03d'; // Partly cloudy -> scattered clouds
       case 3: return '04d'; // Overcast -> broken clouds
       case 45: case 48: return '50d'; // Fog -> mist
       case 51: case 53: case 55: return '09d'; // Drizzle -> shower rain
       case 56: case 57: return '13d'; // Freezing Drizzle -> snow
       case 61: case 63: case 65: return '10d'; // Rain -> rain
       case 66: case 67: return '10d'; // Freezing Rain -> rain
       case 71: case 73: case 75: case 77: return '13d'; // Snow -> snow
       case 80: case 81: case 82: return '09d'; // Rain showers -> shower rain
       case 85: case 86: return '13d'; // Snow showers -> snow
       case 95: case 96: case 99: return '11d'; // Thunderstorm -> thunderstorm
       default: return 'na'; // Unknown
     }
   }
}