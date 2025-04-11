import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/theme_provider.dart';
import '../models/travel_request.dart';
import '../services/travel_planner_service.dart';
import 'travel_plan_display_screen.dart';

class BudgetFreeTravelForm extends StatefulWidget {
  const BudgetFreeTravelForm({Key? key}) : super(key: key);

  @override
  _BudgetFreeTravelFormState createState() => _BudgetFreeTravelFormState();
}

class _BudgetFreeTravelFormState extends State<BudgetFreeTravelForm> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _daysController = TextEditingController();
  DateTime? _selectedDate;
  bool _isGenerating = false;
  final TravelPlannerService _plannerService = TravelPlannerService();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.planeDeparture,
              color: isDarkMode ? Colors.green : Colors.green.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Budget-Free Travel Planner',
              style: TextStyle(
                color: isDarkMode ? Colors.green : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode 
                  ? [Colors.black, Colors.black87]
                  : [Colors.white, Colors.green.shade50],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isDarkMode ? Colors.black45 : Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.green.withOpacity(0.1) 
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    FontAwesomeIcons.dollarSign,
                                    color: isDarkMode ? Colors.green : Colors.green.shade700,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Budget-Optimized Travel Plan',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'We\'ll create an affordable travel plan that maximizes your experience while keeping costs low.',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
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
                        onPressed: _isGenerating ? null : _generatePlan,
                        icon: Icon(
                          _isGenerating
                              ? Icons.hourglass_empty
                              : FontAwesomeIcons.wandMagicSparkles,
                        ),
                        label: Text(
                          _isGenerating ? 'Generating...' : 'Generate Budget Plan',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: isDarkMode ? Colors.green : Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.green : Colors.green.shade700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode 
                ? Colors.green.withOpacity(0.5) 
                : Colors.green.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.green : Colors.green.shade700,
          ),
        ),
        filled: true,
        fillColor: isDarkMode 
            ? Colors.black.withOpacity(0.3) 
            : Colors.green.shade50,
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
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
          prefixIcon: Icon(
            Icons.calendar_today,
            color: isDarkMode ? Colors.green : Colors.green.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode
                  ? Colors.green.withOpacity(0.5)
                  : Colors.green.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.green : Colors.green.shade700,
            ),
          ),
          filled: true,
          fillColor: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.green.shade50,
        ),
        child: Text(
          _selectedDate == null
              ? 'Select Date'
              : _selectedDate!.toLocal().toString().split(' ')[0],
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a travel start date'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final request = TravelRequest(
        country: _countryController.text.trim(),
        budget: null, // No budget for budget-free plan
        days: int.parse(_daysController.text),
        startDate: _selectedDate!,
      );

      final plan = await _plannerService.generateBudgetPlan(request);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TravelPlanDisplayScreen(plan: plan),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}