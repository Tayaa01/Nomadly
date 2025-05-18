import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geocoding/geocoding.dart';
import 'destination_weather_screen.dart'; // Fix this import - it's in the same directory
import '../models/travel_plan.dart';
import '../widgets/app_drawer.dart'; // Import the AppDrawer

class TravelPlanDisplayScreen extends StatefulWidget {
  final TravelPlan plan;

  const TravelPlanDisplayScreen({super.key, required this.plan});

  @override
  _TravelPlanDisplayScreenState createState() =>
      _TravelPlanDisplayScreenState();
}

class _TravelPlanDisplayScreenState extends State<TravelPlanDisplayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAdditionalInfo = false;
  bool _showOnlyFreeActivities = false; // New state variable for filtering
  String _weatherError = '';
  final Map<String, String> _countryCapitals = {
    'United States': 'Washington, D.C.',
    'USA': 'Washington, D.C.',
    'Canada': 'Ottawa',
    'UK': 'London',
    'United Kingdom': 'London',
    'France': 'Paris',
    'Germany': 'Berlin',
    'Italy': 'Rome',
    'Spain': 'Madrid',
    'Japan': 'Tokyo',
    'China': 'Beijing',
    'India': 'New Delhi',
    'Australia': 'Canberra',
    'Brazil': 'Brasília',
    'Mexico': 'Mexico City',
    'Russia': 'Moscow',
    'South Africa': 'Pretoria',
    'Egypt': 'Cairo',
    'Turkey': 'Ankara',
    'Argentina': 'Buenos Aires',
    'South Korea': 'Seoul',
    'Thailand': 'Bangkok',
    'Indonesia': 'Jakarta',
    'Malaysia': 'Kuala Lumpur',
    'Singapore': 'Singapore',
    'Vietnam': 'Hanoi',
    'Greece': 'Athens',
    'Portugal': 'Lisbon',
    'Ireland': 'Dublin',
    'Poland': 'Warsaw',
    'Sweden': 'Stockholm',
    'Norway': 'Oslo',
    'Denmark': 'Copenhagen',
    'Finland': 'Helsinki',
    'Netherlands': 'Amsterdam',
    'Belgium': 'Brussels',
    'Switzerland': 'Bern',
    'Austria': 'Vienna',
    'New Zealand': 'Wellington',
    // Add more countries and capitals as needed
  };

  void debugPrintInfo() {
    print("====== DEBUGGING TRAVEL PLAN INFO ======");
    print("Country: ${widget.plan.country}");
    print("City: ${widget.plan.city}");
    print("Days: ${widget.plan.days}");
    print("Start Date: ${widget.plan.startDate}");
    print("Budget: ${widget.plan.budget}");
    print("Estimated Budget: ${widget.plan.estimatedBudget}");
    print("Is Budget Optimized: ${widget.plan.isBudgetOptimized}");
    print("============= DAY CONTENTS =============");
    for (int i = 0; i < widget.plan.daysContent.length; i++) {
      print("--- DAY ${i + 1} ---");
      print(widget.plan.daysContent[i].content);
    }
    print("=======================================");
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.plan.daysContent.length,
      vsync: this,
    );
    debugPrintInfo();
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
        title: Column(
          children: [
            Text(
              widget.plan.country,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (widget.plan.city.isNotEmpty)
              Text(
                widget.plan.city,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
        actions: [
          // Filter button for free activities (keep this out of the menu)
          IconButton(
            icon: Icon(
              _showOnlyFreeActivities
                  ? FontAwesomeIcons.filter
                  : FontAwesomeIcons.filterCircleXmark,
              color:
                  _showOnlyFreeActivities
                      ? const Color(0xFF4CD964)
                      : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showOnlyFreeActivities = !_showOnlyFreeActivities;
              });
            },
            tooltip:
                _showOnlyFreeActivities
                    ? 'Show All Activities'
                    : 'Show Free Activities Only',
          ),

          // Menu button with other options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4CD964)),
            onSelected: (value) {
              switch (value) {
                case 'weather':
                  _navigateToWeatherForecast();
                  break;
                case 'info':
                  setState(() {
                    _showAdditionalInfo = !_showAdditionalInfo;
                  });
                  break;
                case 'calendar':
                  _addToCalendar();
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  // Remove filter option from popup menu since we have a dedicated button for it
                  PopupMenuItem(
                    value: 'weather',
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 16),
                        const SizedBox(width: 12),
                        const Text('Weather Forecast'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(
                          _showAdditionalInfo ? Icons.info : Icons.info_outline,
                          size: 16,
                          color:
                              _showAdditionalInfo
                                  ? const Color(0xFF4CD964)
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _showAdditionalInfo
                              ? 'Hide Info'
                              : 'Show Additional Info',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'calendar',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 12),
                        Text('Add to Calendar'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text('Day ${index + 1}'),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      // Add the drawer
      drawer: const AppDrawer(
        currentRoute: '/travel-plan',
      ), // Assuming '/travel-plan' is the route name
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
                  children: List.generate(widget.plan.daysContent.length, (
                    index,
                  ) {
                    return _buildDayContent(
                      widget.plan.daysContent[index].content,
                      index,
                    );
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
    if (!widget.plan.isBudgetOptimized &&
        widget.plan.budget > 0 &&
        widget.plan.estimatedBudget > 0) {
      final savings = widget.plan.budget - widget.plan.estimatedBudget;
      final savingsPercentage = (savings / widget.plan.budget * 100)
          .toStringAsFixed(0);

      if (savings > 0) {
        savingsText =
            'You save \$${savings.toStringAsFixed(0)} ($savingsPercentage%)';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.3)),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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
                        _buildBudgetText(),
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
            border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'Additional Information',
                  FontAwesomeIcons.circleInfo,
                ),
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
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 4,
                        left: 8,
                      ),
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
                }),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildDayContent(String content, int dayIndex) {
    // 1. Attempt to extract an EXPLICIT daily total first
    String? explicitDailyTotal;
    final explicitPatterns = [
      // Pattern 1: Standard "Daily Total: $XXX" format
      RegExp(
        r'(?:Daily\s*Total|Day\s*Total|Total\s*for\s*Day)[^\d\$€£]*([\$€£]?\s*\d+(?:[.,]\d{1,2})?\s*(?:USD|EUR|GBP)?|\d+\s*(?:USD|EUR|GBP|\$|€|£))',
        caseSensitive: false,
      ),
    ];

    for (var pattern in explicitPatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        explicitDailyTotal =
            match
                .group(1)
                ?.replaceAll(RegExp(r'\s+'), ' ')
                .replaceAll(',', '.')
                .trim();
        print(
          'Found EXPLICIT daily total for day ${dayIndex + 1}: $explicitDailyTotal',
        );
        break; // Found explicit total, no need to check others
      }
    }

    // 2. ALWAYS calculate the total by summing activities as a fallback or primary method
    String? calculatedDailyTotal;
    print('Calculating total from activities for Day ${dayIndex + 1}...');
    final activitiesForCalc = _parseActivities(
      content,
    ); // Parse activities specifically for calculation

    double total = 0;
    bool hasValidCosts = false;
    String detectedCurrencySymbol = '\$'; // Default currency symbol
    bool currencySymbolDetected = false;

    print('Activities count for calculation: ${activitiesForCalc.length}');

    for (final activity in activitiesForCalc) {
      if (activity.cost.isNotEmpty && !_isActivityFree(activity)) {
        // Exclude free activities from sum
        print('Processing activity cost: "${activity.cost}"');

        // More robust cost extraction: Remove currency symbols/text, handle commas/periods
        String cleanedCost = activity.cost
            .replaceAll(
              RegExp(r'[^\d.,]'),
              '',
            ) // Keep only digits, period, comma
            .replaceAll(',', '.'); // Standardize decimal separator to period

        // Attempt to find the first valid number in the cleaned string
        final costMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleanedCost);

        if (costMatch != null) {
          final numericPart = costMatch.group(1);
          if (numericPart != null) {
            try {
              final amount = double.parse(numericPart);
              print('Parsed amount: $amount');
              total += amount;
              hasValidCosts = true;

              // Detect currency symbol from the original cost string (only once)
              if (!currencySymbolDetected) {
                if (activity.cost.contains('€')) {
                  detectedCurrencySymbol = '€';
                  currencySymbolDetected = true;
                } else if (activity.cost.contains('£')) {
                  detectedCurrencySymbol = '£';
                  currencySymbolDetected = true;
                } else if (activity.cost.contains('\$')) {
                  detectedCurrencySymbol = '\$';
                  currencySymbolDetected = true;
                }
                // Add more currency checks if needed
              }
            } catch (e) {
              print(
                'Failed to parse numeric part "$numericPart" from cost: "${activity.cost}". Error: $e',
              );
            }
          } else {
            print(
              'Could not extract numeric part from cleaned cost: "$cleanedCost"',
            );
          }
        } else {
          print(
            'No numeric match found in cleaned cost: "$cleanedCost" from original: "${activity.cost}"',
          );
        }
      } else {
        print('Skipping activity cost (empty or free): "${activity.cost}"');
      }
    }

    if (hasValidCosts) {
      // Format the calculated total with the detected currency symbol
      calculatedDailyTotal =
          '$detectedCurrencySymbol${total.toStringAsFixed(2)}';
      print(
        'CALCULATED daily total for day ${dayIndex + 1}: $calculatedDailyTotal',
      );
    } else {
      print(
        'No valid costs found in activities for day ${dayIndex + 1} to calculate total.',
      );
    }

    // 3. Determine the final amount to display
    String finalDailyTotalAmount;
    if (explicitDailyTotal != null &&
        explicitDailyTotal.isNotEmpty &&
        !explicitDailyTotal.contains(RegExp(r'^\D*$'))) {
      // Use the explicitly found total if it's valid
      finalDailyTotalAmount = explicitDailyTotal;
      print('Using EXPLICIT total: $finalDailyTotalAmount');
    } else if (calculatedDailyTotal != null &&
        calculatedDailyTotal.isNotEmpty) {
      // Otherwise, use the calculated total if available
      finalDailyTotalAmount = calculatedDailyTotal;
      print('Using CALCULATED total: $finalDailyTotalAmount');
    } else {
      // Default if neither worked
      finalDailyTotalAmount = "\$0.00";
      print('Using DEFAULT total: $finalDailyTotalAmount');
    }

    // 4. Parse activities for display (filtering out total rows)
    List<ActivityItem> activities =
        _parseActivities(content)
            .where(
              (a) =>
                  !a.activity.toLowerCase().contains('daily total') &&
                  !a.activity.toLowerCase().contains('day total'),
            )
            .toList();

    // 5. Filter for free activities if needed
    if (_showOnlyFreeActivities) {
      activities =
          activities.where((activity) => _isActivityFree(activity)).toList();
    }

    // 6. Build the layout
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(
            'Day ${dayIndex + 1} Itinerary',
            FontAwesomeIcons.route,
          ),
          const SizedBox(height: 16),

          // Display activities if any exist
          if (activities.isNotEmpty)
            ...activities.map((activity) => _buildActivityCard(activity)),

          // Display empty state messages ONLY if activities are empty
          if (activities.isEmpty && _showOnlyFreeActivities)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      FontAwesomeIcons.faceSadTear,
                      color: Colors.grey,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No free activities found for this day',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (activities.isEmpty && !_showOnlyFreeActivities)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      FontAwesomeIcons.faceSadTear,
                      color: Colors.grey,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activities found for this day',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // ALWAYS add the daily total card at the end
          _buildDailyTotalCard(
            finalDailyTotalAmount,
          ), // Pass the final determined value

          const SizedBox(height: 24), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildDailyTotalCard(String? amount) {
    return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16, bottom: 4), // Reduced margins
          decoration: BoxDecoration(
            color: const Color(0xFF333333), // Same background as activity cards
            borderRadius: BorderRadius.circular(16), // Match activity cards
            border: Border.all(
              color: const Color(0xFF4CD964).withOpacity(0.5),
              width: 1, // Thinner border
            ),
          ),
          child: Column(
            children: [
              // Header - more compact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ), // Reduced padding
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF4CD964,
                  ).withOpacity(0.15), // More subtle bg
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Changed layout
                  children: [
                    // Left side - title
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.wallet,
                          color: Color(0xFF4CD964),
                          size: 14, // Smaller icon
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "DAILY TOTAL",
                          style: TextStyle(
                            color: const Color(0xFF4CD964),
                            fontWeight: FontWeight.w700,
                            fontSize: 14, // Smaller text
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    // Right side - amount
                    Text(
                      amount ?? 'N/A',
                      style: const TextStyle(
                        color: Color(0xFF4CD964),
                        fontWeight: FontWeight.w800,
                        fontSize: 20, // Smaller but still prominent amount
                      ),
                    ),
                  ],
                ),
              ),

              // Amount details - more compact
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ), // Reduced padding
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.moneyBillWave,
                      color: Color(0xFF4CD964),
                      size: 14,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Spent today",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0); // Subtler animation
  }

  List<ActivityItem> _parseActivities(String content) {
    final activities = <ActivityItem>[];
    int index = 0;
    print("--- Parsing Activities ---"); // Add start log

    // Check if content uses markdown table format
    if (content.contains('|')) {
      print("Parsing as Markdown Table");
      // Extract activities from markdown table
      final lines = content.split('\n');
      bool isInTable = false;

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('|') &&
            trimmedLine.contains('|') &&
            trimmedLine.endsWith('|')) {
          // Skip table headers and separators
          if (trimmedLine.contains('---') ||
              trimmedLine.toLowerCase().contains('| time |') ||
              trimmedLine.toLowerCase().contains('| activity |')) {
            isInTable = true;
            print("Skipping header/separator line: $trimmedLine");
            continue;
          }

          if (isInTable) {
            final parts = trimmedLine.split('|').map((p) => p.trim()).toList();
            // Expecting format like: | Time | Activity | Location | Cost |
            // parts[0] will be empty, parts[1] = Time, parts[2] = Activity, etc.
            if (parts.length >= 5) {
              // Need at least 5 parts for Cost
              final time = parts[1];
              final activity = parts[2];
              final location = parts[3];
              final cost = parts[4]; // Cost is the 5th element (index 4)

              // Log extracted values
              print(
                "Table Row Parsed: Time='$time', Activity='$activity', Location='$location', Cost='$cost'",
              );

              // Skip if this row is explicitly a daily total row
              final activityLower = activity.toLowerCase();
              if (activityLower.contains('daily total') ||
                  activityLower.contains('day total')) {
                print(
                  "Skipping row as it contains 'daily total' or 'day total'",
                );
                continue;
              }

              activities.add(
                ActivityItem(
                  time: time,
                  activity: _cleanMarkdown(activity),
                  location: location,
                  cost: cost, // Use the extracted cost
                  index: index++,
                  isDailyTotal: false,
                ),
              );
            } else {
              print("Skipping table row, not enough parts (< 5): $trimmedLine");
            }
          }
        } else {
          // print("Skipping line, not a valid table row: $trimmedLine");
        }
      }
    } else {
      print("Parsing as Plain Text");
      // Handle non-table format (plain text)
      final timeRegex = RegExp(
        r'(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?|Morning|Afternoon|Evening)',
      );
      final lines = content.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line.startsWith('#')) {
          // print("Skipping empty or comment line: $line");
          continue;
        }

        // Skip if this line is explicitly a daily total line
        final lineLower = line.toLowerCase();
        if (lineLower.contains('daily total') ||
            lineLower.contains('day total')) {
          print(
            "Skipping line as it contains 'daily total' or 'day total': $line",
          );
          continue;
        }

        final timeMatch = timeRegex.firstMatch(line);
        if (timeMatch != null) {
          final time = timeMatch.group(0)!;
          final activity = line.substring(timeMatch.end).trim();
          String location = '';
          String cost = '';

          // Look ahead for Location and Cost lines
          int lookaheadIndex = i + 1;
          while (lookaheadIndex < lines.length) {
            final nextLine = lines[lookaheadIndex].trim();
            if (nextLine.startsWith('Location:')) {
              location = nextLine.substring('Location:'.length).trim();
              print("Found Location on next line: '$location'");
              i = lookaheadIndex; // Consume this line
            } else if (nextLine.startsWith('Cost:')) {
              cost = nextLine.substring('Cost:'.length).trim();
              print("Found Cost on next line: '$cost'");
              i = lookaheadIndex; // Consume this line
            } else if (timeRegex.hasMatch(nextLine) ||
                nextLine.isEmpty ||
                nextLine.startsWith('#')) {
              // Stop looking ahead if we hit the next activity, empty line, or comment
              break;
            }
            lookaheadIndex++;
          }

          // Log extracted values
          print(
            "Plain Text Parsed: Time='$time', Activity='$activity', Location='$location', Cost='$cost'",
          );

          // Skip if the activity itself contains total keywords (redundant check, but safe)
          final activityLower = activity.toLowerCase();
          if (activityLower.contains('daily total') ||
              activityLower.contains('day total')) {
            print(
              "Skipping activity as it contains 'daily total' or 'day total'",
            );
            continue;
          }

          activities.add(
            ActivityItem(
              time: time,
              activity: activity,
              location: location,
              cost: cost, // Use the extracted cost
              index: index++,
            ),
          );
        } else {
          // print("Skipping line, no time match found: $line");
        }
      }
    }
    print(
      "--- Finished Parsing Activities (${activities.length} found) ---",
    ); // Add end log
    return activities;
  }

  String _cleanMarkdown(String text) {
    return text.replaceAll('**', '').replaceAll('*', '').trim();
  }

  Widget _buildActivityCard(ActivityItem activity) {
    // Prevent rendering of any backend "daily total" activity as a card
    if (activity.activity.toLowerCase().contains('daily total') ||
        activity.activity.toLowerCase().contains('day total')) {
      return const SizedBox.shrink();
    }
    // Regular activity card (for non-daily totals)
    final bool isFree = _isActivityFree(activity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CD964).withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          // Main content - with padding adjustments for cost badge
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              top: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with time indicator on left, cost on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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

                    const Spacer(), // Push cost to the right
                    // Cost indicator directly in the layout
                    isFree
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CD964),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                        : Container(
                          constraints: const BoxConstraints(
                            maxWidth: 150,
                          ), // Control maximum width
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CD964).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF4CD964).withOpacity(0.3),
                            ),
                          ),
                          child: _formatCostText(activity.cost),
                        ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  activity.activity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (activity.location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _openMap(activity.location),
                    child: Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.locationDot,
                          color: Color(0xFF4CD964),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: const TextStyle(
                              color: Color(0xFF4CD964),
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
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms * activity.index);
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
    final String fullPlan = widget.plan.daysContent
        .map((day) => day.content)
        .join('\n\n');

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

        final timePattern = RegExp(
          r'(\d+)(?::(\d+))?\s*(AM|PM)?',
          caseSensitive: false,
        );
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
            startMinute,
          );

          // Estimate an end time 2 hours later for the event
          final endDateTime = startDateTime.add(const Duration(hours: 2));

          events.add(
            Event(
              title: activity.activity,
              description:
                  activity.cost.isNotEmpty ? 'Cost: ${activity.cost}' : '',
              location: activity.location,
              startDate: startDateTime,
              endDate: endDateTime,
            ),
          );
        }
      }
    }

    return events;
  }

  Future<void> _navigateToWeatherForecast() async {
    setState(() {
      _weatherError = '';
    });

    try {
      String searchQuery = widget.plan.country;
      String displayName = searchQuery;

      // Check if we have a capital city for this country
      String? capital = _countryCapitals[searchQuery];
      if (capital != null) {
        // Use the capital city for better weather targeting
        searchQuery = '$capital, ${widget.plan.country}';
        displayName = capital;
        print('Using capital city: $searchQuery');
      } else {
        // No capital found in our map, try to find a major city from the itinerary
        if (widget.plan.daysContent.isNotEmpty) {
          final firstDayContent = widget.plan.daysContent[0].content;

          // Look for city names in the content
          final cityPattern = RegExp(
            r'(visit|in|to|at|explore)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)',
          );
          final cityMatches = cityPattern.allMatches(firstDayContent);

          if (cityMatches.isNotEmpty && cityMatches.first.groupCount >= 2) {
            final capturedCity = cityMatches.first.group(2);
            if (capturedCity != null && capturedCity.length > 3) {
              // Use city name + country for more precision
              searchQuery = '$capturedCity, ${widget.plan.country}';
              displayName = capturedCity;
              print('Using city from itinerary: $searchQuery');
            }
          }
        }
      }

      // Get coordinates for the location
      print('Geocoding location: $searchQuery');
      final List<Location> locations = await locationFromAddress(searchQuery);

      if (locations.isEmpty) {
        throw Exception('Could not find location coordinates for $searchQuery');
      }

      // Use the first result
      final location = locations.first;

      // Debug info
      print(
        'Found coordinates for $searchQuery: ${location.latitude}, ${location.longitude}',
      );

      // Navigate to the weather screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => DestinationWeatherScreen(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  locationName: displayName,
                  tripStartDate: widget.plan.startDate,
                ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to weather forecast: $e');
      setState(() {
        _weatherError = e.toString();
      });

      // Show error in snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load weather data: $_weatherError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CD964).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4CD964), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Add this method inside _TravelPlanDisplayScreenState
  bool _isActivityFree(ActivityItem activity) {
    final costLower = activity.cost.toLowerCase();
    return costLower.contains('free') ||
        costLower.contains('no cost') ||
        costLower.contains('\$0') ||
        costLower.contains('€0') ||
        costLower.contains('£0') ||
        costLower == '0' ||
        costLower.isEmpty;
  }

  // Add this method inside _TravelPlanDisplayScreenState
  Color _getTimeColor(String time) {
    if (time.toLowerCase().contains('morning')) {
      return const Color(0xFF3CB371); // Medium Sea Green
    } else if (time.toLowerCase().contains('afternoon')) {
      return const Color(0xFF4CD964); // Main app green
    } else if (time.toLowerCase().contains('evening')) {
      return const Color(0xFF2E8B57); // Sea Green (darker)
    } else {
      // Try to parse time as hour
      final timePattern = RegExp(
        r'(\d+)(?::(\d+))?\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = timePattern.firstMatch(time);
      if (match != null) {
        final hour = int.tryParse(match.group(1) ?? '');
        final amPm = match.group(3)?.toUpperCase();
        if (hour != null) {
          int adjustedHour = hour;
          if (amPm == 'PM' && hour < 12) adjustedHour += 12;
          if (amPm == 'AM' && hour == 12) adjustedHour = 0;
          if (adjustedHour >= 5 && adjustedHour < 12) {
            return const Color(0xFF3CB371); // Morning
          } else if (adjustedHour >= 12 && adjustedHour < 17) {
            return const Color(0xFF4CD964); // Afternoon
          } else {
            return const Color(0xFF2E8B57); // Evening
          }
        }
      }
      return const Color(0xFF4CD964); // Default
    }
  }

  // Add this method inside _TravelPlanDisplayScreenState
  IconData _getTimeIcon(String time) {
    final lower = time.toLowerCase();
    if (lower.contains('morning')) {
      return FontAwesomeIcons.sun;
    } else if (lower.contains('afternoon')) {
      return FontAwesomeIcons.cloudSun;
    } else if (lower.contains('evening')) {
      return FontAwesomeIcons.moon;
    } else {
      return FontAwesomeIcons.clock;
    }
  }

  // Helper method to format the cost text for better display
  Widget _formatCostText(String cost) {
    if (cost.isEmpty) {
      return const Text(
        'COST',
        style: TextStyle(
          color: Color(0xFF4CD964),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    // If the cost contains parentheses or is longer than a certain threshold
    final bool isLongText = cost.contains('(') || cost.length > 15;

    if (isLongText) {
      // For long text with parentheses, extract and format differently
      final RegExp costPattern = RegExp(r'([\$€£]\s*\d+(?:[,.]\d+)?)');
      final match = costPattern.firstMatch(cost);
      final String? numericPart = match?.group(1);

      if (numericPart != null) {
        // Has a numeric part we can extract
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              numericPart,
              style: const TextStyle(
                color: Color(0xFF4CD964),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cost.replaceFirst(numericPart, '').trim(),
              style: const TextStyle(
                color: Color(0xFF4CD964),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ],
        );
      }
    }

    // Default case for shorter cost text
    return Text(
      cost,
      style: const TextStyle(
        color: Color(0xFF4CD964),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _buildBudgetText() {
    if (widget.plan.isBudgetOptimized) {
      return 'Budget-optimized: ~\$${widget.plan.estimatedBudget.toStringAsFixed(0)}';
    } else if (widget.plan.budget > 0) {
      return 'Budget: \$${widget.plan.budget.toStringAsFixed(0)}';
    } else if (widget.plan.estimatedBudget > 0) {
      // Fallback to estimated budget if regular budget is 0
      return 'Estimated budget: \$${widget.plan.estimatedBudget.toStringAsFixed(0)}';
    } else {
      // Both budgets are 0, generic text
      return 'Budget information unavailable';
    }
  }
}

// Simple class to hold activity data
class ActivityItem {
  final String time;
  final String activity;
  final String location;
  final String cost;
  final int index;
  final bool isDailyTotal; // Add this flag

  ActivityItem({
    required this.time,
    required this.activity,
    required this.location,
    required this.cost,
    required this.index,
    this.isDailyTotal = false, // Default to false
  });
}
