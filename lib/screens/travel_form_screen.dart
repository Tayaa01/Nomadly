import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/theme_provider.dart';
import '../models/travel_request.dart';
import '../models/travel_plan.dart';
import '../widgets/app_drawer.dart';
import 'travel_plan_display_screen.dart';
import '../services/travel_planner_service.dart';
import 'travel_plan_loading_screen.dart';

class TravelFormScreen extends StatefulWidget {
  const TravelFormScreen({super.key});

  @override
  _TravelFormScreenState createState() => _TravelFormScreenState();
}

class _TravelFormScreenState extends State<TravelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController(); // Add city controller
  final _budgetController = TextEditingController();
  final _daysController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _hasExistingPlan = false;
  TravelPlan? _existingPlan;
  final bool _isGeneratingPlan = false;

  final TravelPlannerService _plannerService = TravelPlannerService();

  @override
  void initState() {
    super.initState();
    _checkForExistingPlan();
  }

  Future<void> _checkForExistingPlan() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final existingPlan = await _plannerService.getExistingPlan();
      
      setState(() {
        _existingPlan = existingPlan;
        _hasExistingPlan = existingPlan != null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking for existing plans: $e');
      setState(() {
        _isLoading = false;
        _hasExistingPlan = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return WillPopScope(
      onWillPop: () async {
        // Navigate to home screen when back button is pressed
        // instead of the previous screen in the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        return false; // Prevents default back button behavior
      },
      child: Scaffold(
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
            onPressed: () {
              // Use the same navigation logic as the back button
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
          title: const Text(
            'Travel Planner',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: const Color(0xFF4CD964),
              ),
              onPressed: () {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ],
        ),
        drawer: const AppDrawer(currentRoute: '/planner'),
        body: _isLoading
            ? _buildLoadingState()
            : _buildMainContent(isDarkMode),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CD964)),
          ),
          const SizedBox(height: 20),
          Text(
            'Checking for existing travel plans...',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent(bool isDarkMode) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Main card with options
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4CD964).withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.earthAmericas,
                        size: 48,
                        color: const Color(0xFF4CD964),
                      ).animate().fadeIn(duration: 600.ms),
                      const SizedBox(height: 20),
                      const Text(
                        'Travel Planner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(duration: 700.ms),
                      const SizedBox(height: 10),
                      Text(
                        'Create personalized travel plans with ease',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(duration: 800.ms),
                      const SizedBox(height: 30),
                      if (_hasExistingPlan && _existingPlan != null)
                        _buildExistingPlanCard(),
                      const SizedBox(height: 30),
                      const Text(
                        'Create a new plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanTypeButton(
                              icon: FontAwesomeIcons.dollarSign,
                              title: 'Budget Planner',
                              subtitle: 'Find affordable travel options',
                              onTap: () => _showTravelForm(true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPlanTypeButton(
                              icon: FontAwesomeIcons.suitcase,
                              title: 'Custom Planner',
                              subtitle: 'Plan with your budget',
                              onTap: () => _showTravelForm(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExistingPlanCard() {
    if (_existingPlan == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CD964).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CD964).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Existing Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                FontAwesomeIcons.solidClock,
                size: 16,
                color: Color(0xFF4CD964),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_existingPlan!.country} - ${_existingPlan!.days} days',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Starting on ${_existingPlan!.formattedStartDate}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _existingPlan!.isBudgetOptimized 
                ? 'Budget-optimized plan' 
                : 'Custom plan with budget \$${_existingPlan!.budget.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF4CD964),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToPlanDisplay(_existingPlan!),
              icon: const Icon(FontAwesomeIcons.eye),
              label: const Text('View Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 900.ms).slideY();
  }

  Widget _buildPlanTypeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CD964).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF4CD964),
            ),
            const SizedBox(height: 12),
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
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 900.ms).scale(delay: 200.ms);
  }

  Widget _buildTravelForm(bool isBudgetFree) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBudgetFree 
                ? 'Budget-Optimized Travel Plan'
                : 'Custom Travel Plan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBudgetFree 
                ? 'We\'ll create an affordable plan based on your destination and dates'
                : 'We\'ll create a plan based on your destination, budget, and dates',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _countryController,
            label: 'Country',
            icon: FontAwesomeIcons.earthAmericas,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a country';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            icon: FontAwesomeIcons.city,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a city';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (!isBudgetFree)
            _buildTextField(
              controller: _budgetController,
              label: 'Budget (USD)',
              icon: FontAwesomeIcons.dollarSign,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your budget';
                }
                final budget = int.tryParse(value!);
                if (budget == null || budget <= 0) {
                  return 'Please enter a valid budget';
                }
                return null;
              },
            ),
          if (!isBudgetFree) const SizedBox(height: 16),
          _buildTextField(
            controller: _daysController,
            label: 'Number of Days',
            icon: FontAwesomeIcons.calendar,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter number of days';
              }
              final days = int.tryParse(value!);
              if (days == null || days <= 0 || days > 14) {
                return 'Please enter between 1-14 days';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDatePicker(context),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPlan ? null : () => _generatePlan(isBudgetFree),
              icon: Icon(
                _isGeneratingPlan
                    ? Icons.hourglass_empty
                    : FontAwesomeIcons.wandMagicSparkles,
              ),
              label: Text(
                _isGeneratingPlan 
                    ? 'Generating...' 
                    : isBudgetFree 
                        ? 'Generate Budget Plan' 
                        : 'Generate Custom Plan',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: const Color(0xFF4CD964),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTravelForm(bool isBudgetFree) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                16, 
                16, 
                16, 
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: _buildTravelForm(isBudgetFree),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4CD964),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF4CD964).withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4CD964),
          ),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(
        color: Colors.white,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF4CD964),
                  onPrimary: Colors.black,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Travel Start Date',
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: Color(0xFF4CD964),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF4CD964).withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF4CD964),
            ),
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        child: Text(
          _selectedDate == null
              ? 'Select Date'
              : _selectedDate!.toLocal().toString().split(' ')[0],
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _generatePlan(bool isBudgetFree) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a travel start date'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Create the request
    final request = TravelRequest(
      country: _countryController.text.trim(),
      city: _cityController.text.trim(), // Add city to request
      budget: isBudgetFree ? null : double.parse(_budgetController.text),
      days: int.parse(_daysController.text),
      startDate: _selectedDate!,
    );
    
    // Close the form sheet
    Navigator.pop(context);
    
    // Navigate to loading screen immediately
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelPlanLoadingScreen(
          request: request,
          isBudgetFree: isBudgetFree,
        ),
      ),
    ).then((_) {
      // Refresh the screen when coming back
      _checkForExistingPlan();
    });
  }
  
  void _navigateToPlanDisplay(TravelPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelPlanDisplayScreen(plan: plan),
      ),
    ).then((_) {
      // Refresh the screen when coming back from the plan display
      _checkForExistingPlan();
    });
  }
}
