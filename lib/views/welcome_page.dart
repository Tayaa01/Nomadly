import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markWelcomeAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);
    } catch (e) {
      print('Error saving welcome status: $e');
    }
  }

  void _navigateToSignIn() {
    _markWelcomeAsSeen();
    Navigator.pushReplacementNamed(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Top buttons for Skip and Next
            Positioned(
              top: 10,
              right: 10,
              left: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Show back button if not on first page
                  _currentPage > 0
                      ? TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      )
                      : const SizedBox(width: 80), // Placeholder for balance
                  // Skip button
                  TextButton(
                    onPressed: _navigateToSignIn,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 50.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Logo
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nomadly',
                      style: TextStyle(
                        color: Color(0xFF4CD964),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Page content (main area)
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildTravelPlanningPage(),
                        _buildCurrencyToolsPage(),
                        _buildFinanceManagementPage(),
                        _buildFinalPage(),
                      ],
                    ),
                  ),

                  // Page indicator and action buttons
                  Column(
                    children: [
                      // Page indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _numPages,
                          (index) => _buildPageIndicator(index == _currentPage),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action button (Next or Get Started)
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _numPages - 1) {
                            _navigateToSignIn();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CD964),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _numPages - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual onboarding pages
  Widget _buildWelcomePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Patterns
              Positioned(
                top: 40,
                left: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4CD964).withOpacity(0.2),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                right: 30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4CD964).withOpacity(0.1),
                  ),
                ),
              ),

              // Main Illustration
              Center(
                child: Image.asset(
                  'assets/images/travel_illustration.png',
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Travel Smart,\nPay Less',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your personal travel assistant for smarter currency conversions, expense tracking, and travel planning.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTravelPlanningPage() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Color(0xFF4CD964)),
          const SizedBox(height: 24),
          const Text(
            'Smart Travel Planning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildFeatureItem(
                  Icons.flight_takeoff,
                  'Trip Planner',
                  'Create personalized trip itineraries with budget-friendly recommendations',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.hotel,
                  'Travel Deals',
                  'Discover the best offers on flights, hotels, and local attractions',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.search,
                  'Deal Hunting',
                  'Find amazing shopping deals in your destination country',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.wb_sunny,
                  'Weather Forecast',
                  'Get accurate weather information for your destination',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyToolsPage() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.currency_exchange,
            size: 80,
            color: Color(0xFF4CD964),
          ),
          const SizedBox(height: 24),
          const Text(
            'Currency Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildFeatureItem(
                  Icons.camera_alt,
                  'Bill Scanner',
                  'Scan receipts to automatically extract amounts and convert currencies',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.paid,
                  'Real-time Rates',
                  'Get up-to-date currency exchange rates for accurate conversions',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.translate,
                  'Translation',
                  'Translate text and voice for seamless communication while traveling',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.calculate,
                  'VAT Calculator',
                  'Calculate potential tax refunds when shopping abroad',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceManagementPage() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Color(0xFF4CD964),
          ),
          const SizedBox(height: 24),
          const Text(
            'Financial Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildFeatureItem(
                  Icons.receipt_long,
                  'Expense Tracker',
                  'Record and categorize all your travel expenses in one place',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.group,
                  'Group Expenses',
                  'Split costs with travel companions and settle debts easily',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.bar_chart,
                  'Statistics',
                  'Visualize your spending patterns with detailed charts and insights',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.savings,
                  'Budget Planning',
                  'Set travel budgets and get alerts to stay on track',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF4CD964).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Color(0xFF4CD964),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'You\'re All Set!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Create an account or sign in to start planning your next adventure with Nomadly.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Access all features from the app drawer after signing in.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4CD964),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CD964).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4CD964), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4CD964) : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
