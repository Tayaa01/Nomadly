import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/travel_plan.dart';

class TravelPlanDisplayScreen extends StatefulWidget {
  final TravelPlan plan;

  const TravelPlanDisplayScreen({
    Key? key, 
    required this.plan, 
  }) : super(key: key);

  @override
  _TravelPlanDisplayScreenState createState() => _TravelPlanDisplayScreenState();
}

class _TravelPlanDisplayScreenState extends State<TravelPlanDisplayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAdditionalInfo = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.plan.daysContent.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.plan.country,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: const Color(0xFF4CD964),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: List.generate(widget.plan.daysContent.length, (index) {
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Day ${index + 1}'),
                  ),
                );
              }),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showAdditionalInfo ? Icons.info : Icons.info_outline,
              color: const Color(0xFF4CD964),
            ),
            onPressed: () {
              setState(() {
                _showAdditionalInfo = !_showAdditionalInfo;
              });
            },
            tooltip: 'Additional Info',
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: Color(0xFF4CD964),
            ),
            onPressed: _addToCalendar,
            tooltip: 'Add to Calendar',
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Summary Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSummaryCard(),
            ),
            
            if (_showAdditionalInfo && widget.plan.additionalInfo.isNotEmpty)
              _buildAdditionalInfoSection()
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(widget.plan.daysContent.length, (index) {
                    return _buildDayContent(widget.plan.daysContent[index].content, index);
                  }),
                ),
              ),
            
            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(FontAwesomeIcons.penToSquare),
                      label: const Text('Create New Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CD964),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate budget savings for custom plans
    String? savingsText;
    if (!widget.plan.isBudgetOptimized && widget.plan.budget > 0 && widget.plan.estimatedBudget > 0) {
      final savings = widget.plan.budget - widget.plan.estimatedBudget;
      final savingsPercentage = (savings / widget.plan.budget * 100).toStringAsFixed(0);
      
      if (savings > 0) {
        savingsText = 'You save \$${savings.toStringAsFixed(0)} (${savingsPercentage}%)';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CD964).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CD964).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.suitcase,
                    color: Color(0xFF4CD964),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.plan.days}-Day Adventure',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Starting ${widget.plan.formattedStartDate}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CD964).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CD964).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FontAwesomeIcons.dollarSign,
                        size: 16,
                        color: Color(0xFF4CD964),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.plan.isBudgetOptimized
                            ? 'Budget-optimized: ~\$${widget.plan.estimatedBudget.toStringAsFixed(0)}'
                            : 'Budget: \$${widget.plan.budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4CD964),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Add savings info if available
                  if (savingsText != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.piggyBank,
                          size: 14,
                          color: Color(0xFF4CD964),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          savingsText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4CD964),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAdditionalInfoSection() {
    final lines = widget.plan.additionalInfo.split('\n');
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4CD964).withOpacity(0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Additional Information', FontAwesomeIcons.circleInfo),
                const SizedBox(height: 16),
                ...lines.map((line) {
                  if (line.startsWith('##')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        line.replaceAll('##', '').trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (line.startsWith('*')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            FontAwesomeIcons.circleCheck,
                            size: 12,
                            color: Color(0xFF4CD964),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line.replaceAll('*', '').trim(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (line.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox(height: 8);
                  }
                }).toList(),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildDayContent(String content, int dayIndex) {
    // Extract activities from the markdown content
    final List<ActivityItem> activities = _parseActivities(content);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('Day ${dayIndex + 1} Itinerary', FontAwesomeIcons.route),
          const SizedBox(height: 16),
          ...activities.map((activity) => 
            _buildActivityCard(activity)
          ).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CD964).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CD964),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CD964).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTimeColor(activity.time),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTimeIcon(activity.time),
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activity.time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activity.cost.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CD964).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4CD964).withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Cost',
                      style: TextStyle(
                        color: Color(0xFF4CD964),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.activity,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (activity.cost.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                activity.cost,
                style: const TextStyle(
                  color: Color(0xFF4CD964),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (activity.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openMap(activity.location),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.locationDot,
                      color: Color(0xFF4CD964), // Updated from blue to green
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity.location,
                        style: const TextStyle(
                          color: Color(0xFF4CD964), // Updated from blue to green
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms * activity.index);
  }

  Color _getTimeColor(String time) {
    // Use intensity variations instead of hue changes for time indicators
    if (time.toLowerCase().contains('morning')) {
      return const Color(0xFF3CB371); // Medium Sea Green
    } else if (time.toLowerCase().contains('afternoon')) {
      return const Color(0xFF4CD964); // Main app green
    } else if (time.toLowerCase().contains('evening')) {
      return const Color(0xFF2E8B57); // Sea Green (darker)
    } else {
      // Parse time to determine period
      final timePattern = RegExp(r'(\d+)(?::(\d+))?\s*(AM|PM)?', caseSensitive: false);
      final match = timePattern.firstMatch(time);
      
      if (match != null) {
        final hour = int.tryParse(match.group(1) ?? '');
        final amPm = match.group(3)?.toUpperCase();
        
        if (hour != null) {
          int adjustedHour = hour;
          if (amPm == 'PM' && hour < 12) adjustedHour += 12;
          if (amPm == 'AM' && hour == 12) adjustedHour = 0;
          
          if (adjustedHour >= 5 && adjustedHour < 12) {
            return const Color(0xFF3CB371); // Morning - Medium Sea Green
          } else if (adjustedHour >= 12 && adjustedHour < 17) {
            return const Color(0xFF4CD964); // Afternoon - Main app green
          } else {
            return const Color(0xFF2E8B57); // Evening - Sea Green (darker)
          }
        }
      }
      
      return const Color(0xFF4CD964); // Default to main app green
    }
  }

  IconData _getTimeIcon(String time) {
    if (time.toLowerCase().contains('morning')) {
      return FontAwesomeIcons.sun;
    } else if (time.toLowerCase().contains('afternoon')) {
      return FontAwesomeIcons.cloudSun;
    } else if (time.toLowerCase().contains('evening')) {
      return FontAwesomeIcons.moon;
    } else {
      return FontAwesomeIcons.clock;
    }
  }

  List<ActivityItem> _parseActivities(String content) {
    final activities = <ActivityItem>[];
    int index = 0;
    
    // Check if content uses markdown table format
    if (content.contains('|')) {
      // Extract activities from markdown table
      final lines = content.split('\n');
      bool isInTable = false;
      
      for (final line in lines) {
        if (line.trim().startsWith('|') && line.contains('|')) {
          // Skip table headers and separators
          if (line.contains('---') || 
              line.toLowerCase().contains('time') || 
              line.toLowerCase().contains('activity')) {
            isInTable = true;
            continue;
          }
          
          if (isInTable) {
            final parts = line.split('|');
            if (parts.length >= 4) {
              final time = parts[1].trim();
              final activity = parts[2].trim();
              final location = parts[3].trim();
              String cost = '';
              
              // Check if there's a cost column
              if (parts.length >= 5) {
                cost = parts[4].trim();
              }
              
              activities.add(ActivityItem(
                time: time,
                activity: activity,
                location: location,
                cost: cost,
                index: index++,
              ));
            }
          }
        }
      }
    } else {
      // Handle non-table format (can be enhanced based on your actual content format)
      final timeRegex = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?|Morning|Afternoon|Evening)');
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        
        final timeMatch = timeRegex.firstMatch(line);
        if (timeMatch != null) {
          final time = timeMatch.group(0)!;
          final activity = line.substring(timeMatch.end).trim();
          // Try to find location in next line if it exists
          String location = '';
          String cost = '';
          
          if (i + 1 < lines.length && lines[i + 1].trim().startsWith('Location:')) {
            location = lines[i + 1].trim().substring('Location:'.length).trim();
            i++; // Skip the location line in next iteration
          }
          
          if (i + 1 < lines.length && lines[i + 1].trim().startsWith('Cost:')) {
            cost = lines[i + 1].trim().substring('Cost:'.length).trim();
            i++; // Skip the cost line in next iteration
          }
          
          activities.add(ActivityItem(
            time: time,
            activity: activity,
            location: location,
            cost: cost,
            index: index++,
          ));
        }
      }
    }
    
    return activities;
  }

  Future<void> _openMap(String place) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$place';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for $place')),
        );
      }
    }
  }

  void _copyToClipboard() {
    final String fullPlan = widget.plan.daysContent.map((day) => day.content).join('\n\n');
    
    Clipboard.setData(ClipboardData(text: fullPlan));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Travel plan copied to clipboard'),
        backgroundColor: Color(0xFF4CD964),
      ),
    );
  }

  void _addToCalendar() {
    try {
      final events = _createCalendarEvents();
      for (final event in events) {
        Add2Calendar.addEvent2Cal(event);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Event> _createCalendarEvents() {
    final events = <Event>[];
    
    for (int i = 0; i < widget.plan.daysContent.length; i++) {
      final dayDate = widget.plan.startDate.add(Duration(days: i));
      final activities = _parseActivities(widget.plan.daysContent[i].content);
      
      for (final activity in activities) {
        // Parse time - assuming format like "9:00 AM", "14:30", etc.
        int? startHour;
        int startMinute = 0;
        
        final timePattern = RegExp(r'(\d+)(?::(\d+))?\s*(AM|PM)?', caseSensitive: false);
        final timeMatch = timePattern.firstMatch(activity.time);
        
        if (timeMatch != null) {
          startHour = int.tryParse(timeMatch.group(1) ?? '');
          startMinute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
          final ampm = timeMatch.group(3)?.toUpperCase();
          
          if (startHour != null && ampm == 'PM' && startHour < 12) {
            startHour += 12;
          } else if (startHour != null && ampm == 'AM' && startHour == 12) {
            startHour = 0;
          }
        } else {
          // Handle descriptive times
          if (activity.time.toLowerCase().contains('morning')) {
            startHour = 9;
          } else if (activity.time.toLowerCase().contains('afternoon')) {
            startHour = 14;
          } else if (activity.time.toLowerCase().contains('evening')) {
            startHour = 19;
          }
        }
        
        if (startHour != null) {
          final startDateTime = DateTime(
            dayDate.year, 
            dayDate.month, 
            dayDate.day, 
            startHour, 
            startMinute
          );
          
          // Estimate an end time 2 hours later for the event
          final endDateTime = startDateTime.add(const Duration(hours: 2));
          
          events.add(Event(
            title: activity.activity,
            description: activity.cost.isNotEmpty 
                ? 'Cost: ${activity.cost}' 
                : '',
            location: activity.location,
            startDate: startDateTime,
            endDate: endDateTime,
          ));
        }
      }
    }
    
    return events;
  }
}

// Simple class to hold activity data
class ActivityItem {
  final String time;
  final String activity;
  final String location;
  final String cost;
  final int index;
  
  ActivityItem({
    required this.time,
    required this.activity,
    required this.location,
    required this.cost,
    required this.index,
  });
}
