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
    Key? key,
    required this.request,
    required this.isBudgetFree,
  }) : super(key: key);

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
        plan = await _plannerService.generatePlan(widget.request);
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
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Creating Your ${widget.request.country} Plan',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isError ? _buildErrorState() : _buildLoadingState(),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
          // Animated loading header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                // Loading animation for country plan
                _buildLoadingText("Creating your ${widget.request.country} adventure..."),
                const SizedBox(height: 24),
                
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
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CD964),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                Container(
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

  Widget _buildLoadingText(String text) {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: const Color(0xFF4CD964),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
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
