import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/travel_request.dart';
import '../models/travel_plan.dart';
import '../services/travel_planner_service.dart';
import 'travel_plan_display_screen.dart';

class TravelPlanLoadingScreen extends StatefulWidget {
  final TravelRequest request;
  final bool isBudgetFree;

  const TravelPlanLoadingScreen({
    super.key,
    required this.request,
    required this.isBudgetFree,
  });

  @override
  State<TravelPlanLoadingScreen> createState() => _TravelPlanLoadingScreenState();
}

class _TravelPlanLoadingScreenState extends State<TravelPlanLoadingScreen> {
  final TravelPlannerService _plannerService = TravelPlannerService();
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTravelPlan();
  }

  Future<void> _loadTravelPlan() async {
    try {
      TravelPlan plan;
      
      if (widget.isBudgetFree) {
        plan = await _plannerService.generateBudgetPlan(widget.request);
      } else {
        plan = await _plannerService.generateCustomPlan(widget.request); // Changed from generatePlan to generateCustomPlan
      }
      
      if (mounted) {
        // Replace this screen with the actual display screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TravelPlanDisplayScreen(plan: plan),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Remove the appBar completely
      body: WillPopScope(
        // Prevent back button navigation while loading
        onWillPop: () async => false,
        child: _isError ? _buildErrorState() : _buildLoadingState(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isError = false;
                      _errorMessage = '';
                    });
                    _loadTravelPlan();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CD964),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final dayCount = widget.request.days;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add top padding to account for status bar
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          
          // Animated loading header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24), // Increased padding
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced loading title - make it more prominent
                Text(
                  "Creating Your ${widget.request.country} Adventure",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22, // Larger font
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.request.city.isNotEmpty ? widget.request.city : "",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30), // More vertical space
                
                // Progress indicators
                Shimmer.fromColors(
                  baseColor: const Color(0xFF333333),
                  highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 12, // Slightly larger dots
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CD964),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30), // More spacing
                      // Timeline items being generated
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProcessingItem(
                            FontAwesomeIcons.magnifyingGlass, 
                            "Finding attractions"
                          ),
                          _buildProcessingItem(
                            FontAwesomeIcons.hotel, 
                            "Selecting places"
                          ),
                          _buildProcessingItem(
                            FontAwesomeIcons.route, 
                            "Optimizing routes"
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skeleton for summary card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSkeletonContainer(120),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day tabs skeleton
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dayCount,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: const Color(0xFF333333),
                        highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Skeleton activity cards
                ...List.generate(
                  4, // Show 4 skeleton activities
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildSkeletonContainer(120 + (index * 20) % 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProcessingItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4CD964),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSkeletonContainer(double height) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF333333),
      highlightColor: const Color(0xFF4CD964).withOpacity(0.3),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
