import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Import async library for Timer
import '../services/weather_service.dart';
import '../widgets/stars_background.dart'; // Import the new stars widget

class DestinationWeatherScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime? tripStartDate;

  const DestinationWeatherScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.tripStartDate,
  });

  @override
  State<DestinationWeatherScreen> createState() => _DestinationWeatherScreenState();
}

class _DestinationWeatherScreenState extends State<DestinationWeatherScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _dailyForecast = [];
  List<Map<String, dynamic>> _hourlyForecast = [];
  String _lastUpdated = '';
  String _localTime = '';
  int? _utcOffsetSeconds;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateLocalTime() {
    if (_utcOffsetSeconds == null || !mounted) return;

    try {
      final nowUtc = DateTime.now().toUtc();
      final destinationTime = nowUtc.add(Duration(seconds: _utcOffsetSeconds!));

      setState(() {
        _localTime = DateFormat('h:mm a').format(destinationTime);
      });
    } catch (e) {
      print('Error updating local time: $e');
      if (mounted) {
        setState(() {
          _localTime = 'Error';
        });
      }
    }
  }

  void _startClockTimer() {
    if (_utcOffsetSeconds != null && mounted) {
      _clockTimer?.cancel();
      _updateLocalTime();
      _clockTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateLocalTime();
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentWeather = null;
      _dailyForecast = [];
      _hourlyForecast = [];
      _localTime = '';
      _utcOffsetSeconds = null;
      _clockTimer?.cancel();
    });

    try {
      final weatherData = await WeatherService.getWeatherFullForecast(
        widget.latitude,
        widget.longitude,
      );

      if (!mounted) return;

      _currentWeather = weatherData['current'];
      _dailyForecast = weatherData['daily'];
      _hourlyForecast = weatherData['hourly'];

      _utcOffsetSeconds = weatherData['utc_offset_seconds'];
      print('Fetched UTC offset: $_utcOffsetSeconds seconds');

      _lastUpdated = DateFormat('MMM d, h:mm a').format(DateTime.now());

      if (_currentWeather != null) {
        final weatherCode = (_currentWeather!['weather_code'] as num?)?.toInt() ?? 0;
        print('Current weather code from API: $weatherCode - ${WeatherService.getWeatherInfoFromCode(weatherCode)['description']}');
      }

      _startClockTimer();
    } catch (e) {
      print("Error fetching weather: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Updated background gradient method with enhanced colors
  List<Color> _getBackgroundGradient(bool isDarkMode) {
    // Default gradients (cloudy/overcast)
    List<Color> defaultDayGradient = [Colors.lightBlue[100]!, Colors.blue[300]!];
    List<Color> defaultNightGradient = [
      const Color(0xFF1F2B44), // Deep navy blue
      const Color(0xFF0F1726)  // Very dark blue-gray
    ];
    
    if (_currentWeather == null) {
      return isDarkMode ? defaultNightGradient : defaultDayGradient;
    }
    
    final weatherCode = (_currentWeather!['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = (_currentWeather!['is_day'] as num?)?.toInt() == 1;
    
    // Clear sky conditions (codes 0, 1)
    if (weatherCode <= 1) {
      if (isDay) {
        // Bright sky blue gradient for clear day
        return [
          const Color(0xFF87CEEB), // Sky blue
          const Color(0xFF1E90FF)  // Dodger blue
        ];
      } else {
        // Deep night sky gradient for clear night
        return [
          const Color(0xFF0A1128), // Deep navy
          const Color(0xFF001233)  // Very dark blue
        ];
      }
    }
    
    // Partly cloudy (code 2)
    else if (weatherCode == 2) {
      if (isDay) {
        // Light blue with some grey for partly cloudy day
        return [
          const Color(0xFFADD8E6), // Light blue
          const Color(0xFF778899)  // Light slate gray
        ];
      } else {
        // Dark blue-grey for partly cloudy night
        return [
          const Color(0xFF2C3E50), // Dark blue gray
          const Color(0xFF1B2631)  // Very dark blue gray
        ];
      }
    }
    
    // Overcast (code 3)
    else if (weatherCode == 3) {
      if (isDay) {
        return [
          const Color(0xFFB0C4DE), // Light steel blue
          const Color(0xFF708090)  // Slate gray
        ];
      } else {
        return [
          const Color(0xFF3B4254), // Slate gray blue
          const Color(0xFF2A2D34)  // Dark slate
        ];
      }
    }
    
    // For rain conditions (codes 51-99)
    else if (weatherCode >= 51) {
      if (isDay) {
        return [
          const Color(0xFF5D8CAE), // Steel blue
          const Color(0xFF36454F)  // Charcoal
        ];
      } else {
        return [
          const Color(0xFF253746), // Dark slate blue
          const Color(0xFF1A1A2E)  // Very dark blue
        ];
      }
    }
    
    // Default fallback
    return isDay ? defaultDayGradient : defaultNightGradient;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4CD964);

    // Determine if it's currently night based on weather data
    final bool isNight = _currentWeather != null && (_currentWeather!['is_day'] as num?)?.toInt() == 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.locationName,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _isLoading ? null : _fetchWeather,
          ),
        ],
      ),
      body: Stack( // Use Stack to layer background and content
        children: [
          // Background Gradient Container
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getBackgroundGradient(isDarkMode),
              ),
            ),
          ),
          // Stars Background (only if night)
          if (isNight)
            const StarsBackground(numberOfStars: 150), // Add stars layer

          // Main Content with RefreshIndicator
          RefreshIndicator(
            onRefresh: _fetchWeather,
            color: primaryColor,
            child: _buildBody(context, isDarkMode, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode, Color primaryColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800]?.withOpacity(0.8) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 50),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                onPressed: _fetchWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_currentWeather == null || _dailyForecast.isEmpty) {
      return const Center(child: Text('No weather data available.', style: TextStyle(color: Colors.white)));
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight)),
        SliverToBoxAdapter(child: _buildCurrentWeather(context, isDarkMode)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_localTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Local time: $_localTime',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Last updated: $_lastUpdated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (widget.tripStartDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      'Trip starts: ${DateFormat('MMM d, yyyy').format(widget.tripStartDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildHourlyForecast(context, isDarkMode)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
            child: Text(
              '7-Day Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        _buildDailyForecastList(isDarkMode, primaryColor),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildCurrentWeather(BuildContext context, bool isDarkMode) {
    final current = _currentWeather!;
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final feelsLike = (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0;
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = (current['is_day'] as num?)?.toInt() == 1;
    final weatherInfo = WeatherService.getWeatherInfoFromCode(weatherCode, isDay: isDay);
    final iconUrl = 'https://openweathermap.org/img/wn/${weatherInfo['icon']}@4x.png';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87
                ),
                const SizedBox(width: 4),
                Text(
                  'Destination Weather',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Image.network(
            iconUrl,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.cloud_off,
              size: 80,
              color: null, // Use default theme icon color
            ),
          ),
          Text(
            '${temp.toStringAsFixed(0)}°',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w300,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${weatherInfo['description'] ?? 'N/A'}. Feels like ${feelsLike.toStringAsFixed(0)}°',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.grey[300] : Colors.black.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(BuildContext context, bool isDarkMode) {
    if (_hourlyForecast.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _hourlyForecast.length,
        itemBuilder: (context, index) {
          final hourData = _hourlyForecast[index];
          final time = DateTime.parse(hourData['time']);
          final temp = (hourData['temp'] as num?)?.toDouble() ?? 0.0;
          final weatherCode = (hourData['weather_code'] as num?)?.toInt() ?? 0;
          final bool isHourDay = time.hour >= 6 && time.hour < 19;
          final weatherInfo = WeatherService.getWeatherInfoFromCode(weatherCode, isDay: isHourDay);
          final iconUrl = 'https://openweathermap.org/img/wn/${weatherInfo['icon']}@2x.png';
          final formattedTime = DateFormat('ha').format(time);

          return Container(
            width: 75,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  index == 0 ? 'Now' : formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.grey[300] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Image.network(
                  iconUrl,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.thermostat,
                    size: 30,
                    color: null, // Use default theme icon color
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${temp.toStringAsFixed(0)}°',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecastList(bool isDarkMode, Color primaryColor) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dayForecast = _dailyForecast[index];
          final date = DateTime.parse(dayForecast['date']);
          
          final bool isTripStartDate = widget.tripStartDate != null && 
                                       date.day == widget.tripStartDate!.day &&
                                       date.month == widget.tripStartDate!.month &&
                                       date.year == widget.tripStartDate!.year;
          
          final bool isToday = date.day == DateTime.now().day &&
                               date.month == DateTime.now().month &&
                               date.year == DateTime.now().year;
                               
          final formattedDate = isToday 
              ? 'Today' 
              : DateFormat('EEEE').format(date);
              
          final weatherCode = (dayForecast['weather_code'] as num?)?.toInt() ?? 0;
          final weatherInfo = WeatherService.getWeatherInfoFromCode(weatherCode, isDay: true);
          final iconCode = weatherInfo['icon'] ?? '01d';
          final description = weatherInfo['description'] ?? 'N/A';
          final minTemp = (dayForecast['minTemp'] as num?)?.toDouble() ?? 0.0;
          final maxTemp = (dayForecast['maxTemp'] as num?)?.toDouble() ?? 0.0;
          final totalRain = (dayForecast['totalRain'] as num?)?.toDouble() ?? 0.0;
          final totalSnow = (dayForecast['totalSnow'] as num?)?.toDouble() ?? 0.0;

          List<Widget> precipitationWidgets = [];
          if (totalSnow > 0.1) {
            precipitationWidgets.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ac_unit, size: 12, color: Colors.lightBlue[200]),
                const SizedBox(width: 3),
                Text('${totalSnow.toStringAsFixed(1)}cm', style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
              ],
            ));
          }
          if (totalRain > 0.5) {
            if (precipitationWidgets.isNotEmpty) {
              precipitationWidgets.add(const SizedBox(width: 6));
            }
            precipitationWidgets.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_outlined, size: 12, color: Colors.blue[300]),
                const SizedBox(width: 3),
                Text('${totalRain.toStringAsFixed(1)}mm', style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
              ],
            ));
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isTripStartDate
                  ? primaryColor.withOpacity(0.2)
                  : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(12.0),
              border: isTripStartDate 
                  ? Border.all(color: primaryColor)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isTripStartDate 
                              ? primaryColor 
                              : (isDarkMode ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (isTripStartDate)
                        Text(
                          'Trip Start',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://openweathermap.org/img/wn/$iconCode@2x.png',
                        width: 35,
                        height: 35,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.wb_sunny,
                              size: 30,
                              color: Colors.orange, // Explicitly set color for sun
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      if (precipitationWidgets.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: precipitationWidgets)
                      ]
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${maxTemp.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${minTemp.toStringAsFixed(0)}°',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: _dailyForecast.length,
      ),
    );
  }
}
