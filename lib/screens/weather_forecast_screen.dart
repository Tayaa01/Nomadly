import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stars_background.dart'; // Import the new stars widget
import 'package:shimmer/shimmer.dart'; // Import Shimmer package

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  String _locationName = 'Loading location...';
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _dailyForecast = [];
  List<Map<String, dynamic>> _hourlyForecast = [];
  String _lastUpdated = '';

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _locationName = 'Loading location...';
      _currentWeather = null;
      _dailyForecast = [];
      _hourlyForecast = [];
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception(
              'Location permissions are denied. Please enable them in settings.');
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks[0];
          _locationName = '${placemark.locality ?? placemark.subAdministrativeArea ?? ''}, ${placemark.country ?? ''}';
          _locationName = _locationName.replaceAll(RegExp(r'^,\s*|\s*,$'), '');
          if (_locationName.isEmpty) _locationName = 'Current Location';
        } else {
          _locationName = 'Unknown Location';
        }
      } catch (e) {
        print("Error getting location name: $e");
        _locationName = 'Could not get location name';
      }

      final weatherData = await WeatherService.getWeatherFullForecast(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      _currentWeather = weatherData['current'];
      _dailyForecast = weatherData['daily'];
      _hourlyForecast = weatherData['hourly'];

      _lastUpdated = DateFormat('MMM d, h:mm a').format(DateTime.now());

      if (_currentWeather != null) {
        final weatherCode = (_currentWeather!['weather_code'] as num?)?.toInt() ?? 0;
        print('Current weather code from API: $weatherCode - ${WeatherService.getWeatherInfoFromCode(weatherCode)['description']}');
      }

    } catch (e) {
      print("Error fetching location or weather: $e");
      setState(() {
        _errorMessage = e.toString();
        _locationName = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Updated background gradient method with enhanced cloudy/overcast colors
  List<Color> _getBackgroundGradient(bool isDarkMode) {
    // Default gradients (clear day/night)
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
    
    // Partly cloudy (code 2) - IMPROVED
    else if (weatherCode == 2) {
      if (isDay) {
        // Enhanced partly cloudy day gradient - softer silver-blue tones
        return [
          const Color(0xFFABD1E7), // Soft powder blue
          const Color(0xFF8BADC2)  // Muted slate blue
        ];
      } else {
        // Enhanced partly cloudy night gradient - deeper atmospheric blues
        return [
          const Color(0xFF2E394C), // Deep slate blue
          const Color(0xFF1D2733)  // Rich navy charcoal
        ];
      }
    }
    
    // Overcast (code 3) - DARKER IMPROVED
    else if (weatherCode == 3) {
      if (isDay) {
        // Enhanced overcast day gradient - much darker and dramatic grays
        return [
          const Color(0xFF8C9DAD), // Muted slate blue-gray (darker)
          const Color(0xFF5D6977), // Deep steel gray
          const Color(0xFF4A545F), // Very dark slate gray
        ];
      } else {
        // Enhanced overcast night - even deeper atmospheric grays
        return [
          const Color(0xFF2A333C), // Very dark slate blue
          const Color(0xFF1C2329), // Almost black blue-gray
          const Color(0xFF0F1417), // Nearly black with blue undertone
        ];
      }
    }
    
    // For rain conditions (codes 51-99)
    else if (weatherCode >= 51) {
      if (isDay) {
        // Enhanced rainy day - cooler blue grays
        return [
          const Color(0xFF677E8E), // Steel blue gray
          const Color(0xFF455664)  // Slate blue gray
        ];
      } else {
        // Enhanced rainy night - deeper blues
        return [
          const Color(0xFF23313D), // Deep slate blue
          const Color(0xFF141C24)  // Almost black blue
        ];
      }
    }
    
    // Default fallback
    return isDay ? defaultDayGradient : defaultNightGradient;
  }

  Widget _buildWeatherSkeleton() {
    // Adjusted colors for higher contrast shimmer
    final containerBackgroundColor = const Color(0xFF1A2533); // Dark blue-grey background
    final baseSkeletonColor = const Color(0xFF28384A);       // Slightly lighter base blue-grey
    final highlightSkeletonColor = const Color(0xFF5A7698);  // Much lighter blue-grey highlight for more pop
    final cardSkeletonColor = const Color(0xFF202D3D);       // Slightly darker card background
    final placeholderShapeColor = const Color(0xFF5A7698);   // Match highlight color for shapes
    final iconColor = const Color(0xFF4CD964); // App's primary green

    return Container(
      color: containerBackgroundColor,
      child: Shimmer.fromColors(
        baseColor: baseSkeletonColor,
        highlightColor: highlightSkeletonColor,
        period: const Duration(milliseconds: 1200), // Slightly faster shimmer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header indicating loading process - Refined Layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 25, left: 16, right: 16), // Increased bottom padding
              decoration: BoxDecoration(
                color: cardSkeletonColor.withOpacity(0.6), // Adjusted opacity
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25), // Slightly larger radius
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Loading text placeholder
                  Container(
                    width: 240, // Wider text placeholder
                    height: 22, // Taller text placeholder
                    decoration: BoxDecoration(
                      color: placeholderShapeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.only(bottom: 30), // Increased spacing
                  ),
                  // Processing step icons - Refined Layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround, // Use spaceAround for better distribution
                    children: [
                      _buildProcessingIndicator(Icons.location_searching, "Locating", iconColor, placeholderShapeColor), // Changed icon & text
                      _buildProcessingIndicator(Icons.cloud_download_outlined, "Fetching", iconColor, placeholderShapeColor), // Changed icon & text
                      _buildProcessingIndicator(Icons.calendar_month_outlined, "Forecasting", iconColor, placeholderShapeColor), // Changed icon & text
                    ],
                  ),
                ],
              ),
            ),

            // Top: location and main weather skeleton
            Padding(
              padding: const EdgeInsets.only(top: 35, left: 24, right: 24, bottom: 20), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Weather icon skeleton (circle)
                  Container(
                    width: 110, // Slightly larger icon
                    height: 110,
                    decoration: BoxDecoration(
                      color: placeholderShapeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 20), // Increased spacing
                  // Temperature skeleton (larger line)
                  Container(
                    width: 100, // Wider temp
                    height: 52, // Taller temp
                    decoration: BoxDecoration(
                      color: placeholderShapeColor,
                      borderRadius: BorderRadius.circular(14), // Adjusted radius
                    ),
                  ),
                  const SizedBox(height: 12), // Increased spacing
                  // Description skeleton (smaller line)
                  Container(
                    width: 160, // Wider description
                    height: 20, // Taller description
                    decoration: BoxDecoration(
                      color: placeholderShapeColor,
                      borderRadius: BorderRadius.circular(7), // Adjusted radius
                    ),
                  ),
                ],
              ),
            ),

            // Hourly forecast skeleton (within a card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0), // Adjusted padding
              child: Container( // Card background
                height: 135, // Slightly taller
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0), // Adjusted padding
                decoration: BoxDecoration(
                  color: cardSkeletonColor,
                  borderRadius: BorderRadius.circular(18.0), // Adjusted radius
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  itemBuilder: (context, i) => Container(
                    width: 80, // Slightly wider items
                    padding: const EdgeInsets.symmetric(horizontal: 5.0), // Adjusted padding
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container( // Time skeleton
                          width: 40, // Wider time
                          height: 15, // Taller time
                          decoration: BoxDecoration(
                            color: placeholderShapeColor,
                            borderRadius: BorderRadius.circular(5), // Adjusted radius
                          ),
                        ),
                        const SizedBox(height: 12), // Increased spacing
                        Container( // Icon skeleton
                          width: 45, // Larger icon
                          height: 45,
                          decoration: BoxDecoration(
                            color: placeholderShapeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 12), // Increased spacing
                        Container( // Temp skeleton
                          width: 35, // Wider temp
                          height: 18, // Taller temp
                          decoration: BoxDecoration(
                            color: placeholderShapeColor,
                            borderRadius: BorderRadius.circular(5), // Adjusted radius
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 7-day forecast skeleton title
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 10.0), // Adjusted padding
              child: Container( // Title line
                width: 130, // Wider title
                height: 22, // Taller title
                decoration: BoxDecoration(
                  color: placeholderShapeColor,
                  borderRadius: BorderRadius.circular(7), // Adjusted radius
                ),
              ),
            ),

            // 7-day forecast list skeleton (individual cards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Adjusted padding
              child: Column(
                children: List.generate(7, (i) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 5.0), // Adjusted spacing
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Adjusted padding
                  height: 70, // Taller items
                  decoration: BoxDecoration(
                    color: cardSkeletonColor,
                    borderRadius: BorderRadius.circular(14), // Adjusted radius
                  ),
                  child: Row(
                    children: [
                      Container( // Day name skeleton
                        width: 75, // Wider day name
                        height: 18, // Taller day name
                        decoration: BoxDecoration(
                          color: placeholderShapeColor,
                          borderRadius: BorderRadius.circular(5), // Adjusted radius
                        ),
                      ),
                      const Spacer(flex: 2),
                      Container( // Icon skeleton
                        width: 40, // Larger icon
                        height: 40,
                        decoration: BoxDecoration(
                          color: placeholderShapeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(flex: 3),
                      Container( // Max temp skeleton
                        width: 35, // Wider temp
                        height: 18, // Taller temp
                        decoration: BoxDecoration(
                          color: placeholderShapeColor,
                          borderRadius: BorderRadius.circular(5), // Adjusted radius
                        ),
                      ),
                      const SizedBox(width: 14), // Increased spacing
                      Container( // Min temp skeleton
                        width: 35, // Wider temp
                        height: 18, // Taller temp
                        decoration: BoxDecoration(
                          color: placeholderShapeColor.withOpacity(0.6), // Adjusted dimmer opacity
                          borderRadius: BorderRadius.circular(5), // Adjusted radius
                        ),
                      ),
                    ],
                  ),
                )),
              ),
            ),
            const SizedBox(height: 25), // Increased bottom padding
          ],
        ),
      ),
    );
  }

  // Helper widget for processing indicators in the header - Adjusted text width
  Widget _buildProcessingIndicator(IconData icon, String label, Color iconColor, Color placeholderColor) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 22, // Slightly larger icon
        ),
        const SizedBox(height: 10), // Increased spacing
        Container( // Skeleton for the label text
          width: 70, // Adjusted width for shorter labels
          height: 14, // Taller label placeholder
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(5), // Adjusted radius
          ),
        ),
      ],
    );
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
        title: Text(_isLoading ? 'Weather' : _locationName, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _isLoading ? null : _fetchLocationAndWeather,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: '/weather-forecast'),
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
            onRefresh: _fetchLocationAndWeather,
            color: primaryColor,
            child: _isLoading
                ? _buildWeatherSkeleton()
                : _buildBody(context, isDarkMode, primaryColor),
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
                onPressed: _fetchLocationAndWeather,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Last updated: $_lastUpdated',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          const SizedBox(height: 0),
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
          ),
          const SizedBox(height: 8),
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
          final bool isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;
          final formattedDate = isToday ? 'Today' : DateFormat('EEEE').format(date);
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
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
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
                              color: Colors.yellow, // Explicitly set color for sun
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
