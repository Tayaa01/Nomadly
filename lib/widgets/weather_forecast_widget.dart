
import 'package:flutter/material.dart';
import '../services/open_meteo_service.dart'; // Use models from here
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class WeatherForecastWidget extends StatefulWidget {
  final List<WeatherForecast> forecasts;

  const WeatherForecastWidget({super.key, required this.forecasts});

  @override
  _WeatherForecastWidgetState createState() => _WeatherForecastWidgetState();
}

class _WeatherForecastWidgetState extends State<WeatherForecastWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure forecasts list is not empty before creating TabController
    final tabLength = widget.forecasts.isNotEmpty ? widget.forecasts.length : 1;
    _tabController = TabController(
      length: tabLength,
      vsync: this,
    );
    _tabController.addListener(() {
      // Check if the controller index is valid before updating state
      if (_tabController.index < widget.forecasts.length && _tabController.index != _selectedDayIndex) {
        setState(() {
          _selectedDayIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where forecasts might be empty
    if (widget.forecasts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Detailed forecast data not available.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day selector Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0xFF4CD964).withOpacity(0.3), // Subtle indicator
            ),
            labelColor: const Color(0xFF4CD964),
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: widget.forecasts.map((forecast) {
              return Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(DateFormat('EEE d').format(forecast.date)), // Short day format
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(color: Colors.white24, height: 1),

        // Selected day details
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildDayForecastDetails(widget.forecasts[_selectedDayIndex]),
        ),
      ],
    );
  }

  Widget _buildDayForecastDetails(WeatherForecast forecast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Hourly Temperature Chart ---
        const Row(
          children: [
            Icon(Icons.thermostat, color: Color(0xFF4CD964), size: 18),
            SizedBox(width: 8),
            Text(
              'Hourly Temperature (°C)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180, // Adjust height as needed
          child: _buildTemperatureChart(forecast.hourlyForecasts),
        ),

        const SizedBox(height: 24),

        // --- Daily Precipitation Info ---
        const Row(
          children: [
            Icon(Icons.water_drop_outlined, color: Color(0xFF4CD964), size: 18),
            SizedBox(width: 8),
            Text(
              'Daily Precipitation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPrecipitationInfo(forecast),
      ],
    );
  }

  // Builds the hourly temperature line chart
  Widget _buildTemperatureChart(List<HourlyForecast> hourlyForecasts) {
    if (hourlyForecasts.isEmpty) {
      return const Center(child: Text('No hourly data.', style: TextStyle(color: Colors.white70)));
    }

    // Filter data for clarity (e.g., every 2 or 3 hours)
    final List<HourlyForecast> filteredForecasts = [];
    for (int i = 0; i < hourlyForecasts.length; i += 2) { // Show every 2 hours
       filteredForecasts.add(hourlyForecasts[i]);
    }
    if (filteredForecasts.isEmpty && hourlyForecasts.isNotEmpty) {
        filteredForecasts.add(hourlyForecasts.first); // Ensure at least one point if filtering removes all
    }
     if (filteredForecasts.isEmpty) {
       return const Center(child: Text('No hourly data points.', style: TextStyle(color: Colors.white70)));
     }


    // Find min/max for Y-axis scaling
    final temps = filteredForecasts.map((f) => f.temperature).toList();
    final minY = (temps.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (temps.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 4, // Adjust interval based on range
          verticalInterval: (filteredForecasts.length > 1) ? (filteredForecasts.length / 4).ceilToDouble() : 1, // Adjust interval
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white24.withOpacity(0.2), strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.white24.withOpacity(0.2), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          // Left (Y) Axis Titles - Temperature
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35, // Increased space for labels
              interval: (maxY - minY) / 4, // Match grid interval
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  '${value.toInt()}°',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
          ),
          // Bottom (X) Axis Titles - Time
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25, // Space for time labels
              interval: (filteredForecasts.length / 4).ceilToDouble(), // Show fewer labels
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < filteredForecasts.length) {
                  // Show time for specific intervals
                  if (index % ((filteredForecasts.length / 4).ceil()) == 0 || index == filteredForecasts.length -1) {
                     return SideTitleWidget(
                       axisSide: meta.axisSide,
                       space: 4,
                       child: Text(
                         DateFormat('HH:mm').format(filteredForecasts[index].time),
                         style: const TextStyle(color: Colors.white70, fontSize: 10),
                       ),
                     );
                  }
                }
                return const SizedBox.shrink(); // Hide other labels
              },
            ),
          ),
          // Hide top and right titles
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false), // Hide outer border
        minX: 0,
        maxX: (filteredForecasts.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: filteredForecasts.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.temperature);
            }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CD964), Color(0xFF3CB371)], // Green gradient
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true, // Show dots on points
               getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                 radius: 3,
                 color: Colors.white,
                 strokeWidth: 1,
                 strokeColor: const Color(0xFF4CD964),
               ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CD964).withOpacity(0.3),
                  const Color(0xFF4CD964).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        // Tooltip customization
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                if (index < filteredForecasts.length) {
                   final forecast = filteredForecasts[index];
                   return LineTooltipItem(
                     '${DateFormat('HH:mm').format(forecast.time)}\n${forecast.temperature.toStringAsFixed(1)}°C',
                     const TextStyle(color: Colors.white, fontSize: 12),
                   );
                }
                return null;
              }).whereType<LineTooltipItem>().toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  // Builds the precipitation summary section
  Widget _buildPrecipitationInfo(WeatherForecast forecast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF282828), // Slightly different background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPrecipitationItem(
            icon: Icons.umbrella_outlined, // Use outlined icons
            value: forecast.totalRain,
            unit: 'mm',
            label: 'Rain',
            color: Colors.blue.shade300,
          ),
          _buildPrecipitationItem(
            icon: Icons.grain_outlined,
            value: forecast.totalShowers,
            unit: 'mm',
            label: 'Showers',
            color: Colors.lightBlue.shade300,
          ),
          _buildPrecipitationItem(
            icon: Icons.ac_unit_outlined,
            value: forecast.totalSnowfall,
            unit: 'cm',
            label: 'Snow',
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  // Helper for individual precipitation items
  Widget _buildPrecipitationItem({
    required IconData icon,
    required double value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}