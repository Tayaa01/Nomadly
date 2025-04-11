import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/travel_request.dart';

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
  int _selectedDayIndex = -1;
  bool _showImportantNotes = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final chatProvider = context.watch<ChatProvider>();

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
              'Budget-Free Travel Assistant',
              style: TextStyle(
                color: isDarkMode ? Colors.green : Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 24,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: chatProvider.isLoading ? null : _generatePlan,
                          icon: Icon(
                            chatProvider.isLoading
                                ? Icons.hourglass_empty
                                : FontAwesomeIcons.wandMagicSparkles,
                          ),
                          label: Text(
                            chatProvider.isLoading ? 'Generating...' : 'Generate Budget-Free Plan',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            backgroundColor: isDarkMode ? Colors.green : Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  void _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a travel start date'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
      return;
    }

    try {
      final request = TravelRequest(
        country: _countryController.text.trim(),
        budget: 0, // Set budget to 0 for budget-free plan
        days: int.parse(_daysController.text),
        startDate: _selectedDate!,
      );

      await context.read<ChatProvider>().generateItinerary(request);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }
} 