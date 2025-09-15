
// --- Data Models ---

class WeatherForecast {
  final DateTime date;
  final List<HourlyForecast> hourlyForecasts;
  final double maxTemperature;
  final double minTemperature;
  final double totalRain;
  final double totalShowers;
  final double totalSnowfall;

  WeatherForecast({
    required this.date,
    required this.hourlyForecasts,
    required this.maxTemperature,
    required this.minTemperature,
    required this.totalRain,
    required this.totalShowers,
    required this.totalSnowfall,
  });

  // Generate a summary of the day's weather
  String get summary {
    if (totalSnowfall > 0.1) { // Use a small threshold
      return 'Snowfall Expected';
    } else if (totalRain > 0.1 || totalShowers > 0.1) {
      return 'Rain Expected';
    } else {
      if (maxTemperature > 30) {
        return 'Hot';
      } else if (maxTemperature > 20) {
        return 'Warm';
      } else if (maxTemperature > 10) {
        return 'Mild';
      } else {
        return 'Cold';
      }
    }
  }

  // Get weather icon code compatible with OpenWeatherMap icons
  String get iconCode {
    if (totalSnowfall > 0.1) {
      return '13d'; // Snow icon
    } else if (totalRain > 0.1 || totalShowers > 0.1) {
      return '10d'; // Rain icon
    } else {
      // Determine icon based on temperature
      if (maxTemperature > 25) {
        return '01d'; // Clear hot day
      } else if (maxTemperature > 15) {
        return '02d'; // Few clouds
      } else {
        return '03d'; // Cloudy
      }
    }
  }

  // For serialization/deserialization (e.g., saving to SharedPreferences)
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'hourlyForecasts': hourlyForecasts.map((hf) => hf.toJson()).toList(),
    'maxTemperature': maxTemperature,
    'minTemperature': minTemperature,
    'totalRain': totalRain,
    'totalShowers': totalShowers,
    'totalSnowfall': totalSnowfall,
  };

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
    date: DateTime.parse(json['date']),
    hourlyForecasts: (json['hourlyForecasts'] as List)
        .map((hfJson) => HourlyForecast.fromJson(hfJson))
        .toList(),
    maxTemperature: (json['maxTemperature'] as num?)?.toDouble() ?? 0.0,
    minTemperature: (json['minTemperature'] as num?)?.toDouble() ?? 0.0,
    totalRain: (json['totalRain'] as num?)?.toDouble() ?? 0.0,
    totalShowers: (json['totalShowers'] as num?)?.toDouble() ?? 0.0,
    totalSnowfall: (json['totalSnowfall'] as num?)?.toDouble() ?? 0.0,
  );
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final double rain;
  final double showers;
  final double snowfall;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.rain,
    required this.showers,
    required this.snowfall,
  });

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'temperature': temperature,
    'rain': rain,
    'showers': showers,
    'snowfall': snowfall,
  };

  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
    time: DateTime.parse(json['time']),
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
    rain: (json['rain'] as num?)?.toDouble() ?? 0.0,
    showers: (json['showers'] as num?)?.toDouble() ?? 0.0,
    snowfall: (json['snowfall'] as num?)?.toDouble() ?? 0.0,
  );
}
