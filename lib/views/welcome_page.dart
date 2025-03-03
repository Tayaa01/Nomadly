import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> aziz

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Nomadly',
                  style: TextStyle(
                    color: Color(0xFF4CD964),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Illustration Container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                  ),
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
                          width: 280,
                          height: 280,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Welcome Text Section
              const Text(
                'Travel Smart,\nPay Less',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Your personal travel assistant for smarter currency conversions and tax refunds.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              ElevatedButton(
<<<<<<< HEAD
                onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
=======
                onPressed: () => Navigator.pushNamed(context, '/sign-in'),
>>>>>>> aziz
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CD964),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF333333), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Learn More',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
<<<<<<< HEAD
      floatingActionButton: FloatingActionButton(
        onPressed: () => _resetWelcomeFlag(context), // Pass context here
        backgroundColor: Colors.grey[800],
        child: Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  // Updated to accept a context parameter
  void _resetWelcomeFlag(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_seen_welcome');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome screen will show next time')),
      );
    } catch (e) {
      print('Error resetting welcome flag: $e');
    }
  }
=======
    );
  }
>>>>>>> aziz
}
