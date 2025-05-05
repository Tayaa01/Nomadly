import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/country_currency_util.dart';
import '../providers/auth_provider.dart';

class FinishSetupPage extends StatefulWidget {
  final String? firstName;
  final String? lastName;

  const FinishSetupPage({Key? key, this.firstName, this.lastName})
    : super(key: key);

  @override
  State<FinishSetupPage> createState() => _FinishSetupPageState();
}

class _FinishSetupPageState extends State<FinishSetupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  String? _derivedCurrency;

  @override
  void initState() {
    super.initState();
    _loadPlaceholders();
    _firstNameController.text = widget.firstName ?? '';
    _lastNameController.text = widget.lastName ?? '';
    CountryCurrencyUtil.initialize(); // Ensure currency util is ready
    _countryCodeController.addListener(_onCountryCodeChanged);
  }

  Future<void> _loadPlaceholders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFirstName = prefs.getString('google_first_name');
    final savedLastName = prefs.getString('google_last_name');

    if (savedFirstName != null && savedLastName != null) {
      setState(() {
        _firstNameController.text = savedFirstName;
        _lastNameController.text = savedLastName;
      });
    }
  }

  // ignore: unused_element
  Future<void> _savePlaceholders(String firstName, String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_first_name', firstName);
    await prefs.setString('google_last_name', lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryCodeController.removeListener(_onCountryCodeChanged);
    _countryCodeController.dispose();
    super.dispose();
  }

  void _onCountryCodeChanged() {
    final countryCode = _countryCodeController.text.toUpperCase();
    final currency = CountryCurrencyUtil.getCurrencyForCountry(countryCode);
    if (currency != _derivedCurrency) {
      setState(() {
        _derivedCurrency = currency;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final countryCode = _countryCodeController.text.trim().toUpperCase();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final currency = CountryCurrencyUtil.getCurrencyForCountry(countryCode);
    if (currency == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid country code.';
        });
      }
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final googleUser = authProvider.user;
      print('DEBUG googleUser: $googleUser');
      if (googleUser != null) {
        print('DEBUG googleUser.id: ${googleUser.id}');
        print('DEBUG googleUser.email: ${googleUser.email}');
        print('DEBUG googleUser.role: ${googleUser.role}');
      }
      if (googleUser == null) {
        throw Exception('User not authenticated');
      }
      final updatedUser = User(
        id: googleUser.id,
        email: googleUser.email,
        firstName: firstName,
        lastName: lastName,
        countryCode: countryCode,
        currency: currency,
        role: googleUser.role,
      );
      print('DEBUG updatedUser.toJson(): ${updatedUser.toJson()}');

      // 1. Update profile on the backend
      await _userService.updateUserProfile(updatedUser);

      // 2. Update the AuthProvider with the new user data
      // This will also trigger saving the updated user to SharedPreferences
      await authProvider.updateUser(updatedUser);

      if (mounted) {
        print('[FINISH_SETUP] Update successful, navigating to /home');
        Navigator.pushReplacementNamed(context, '/home');
        print('[FINISH_SETUP] Navigation call completed');
      }
    } catch (e, stack) {
      print('FinishSetupPage _submit error: $e');
      print(stack);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update profile: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF333333),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF4CD964),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Nomadly!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s finish setting up your profile',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildProfileForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormField(
            controller: _firstNameController,
            label: 'First Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _lastNameController,
            label: 'Last Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            controller: _countryCodeController,
            label: 'Country Code',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your country code';
              }
              if (value.length != 2) {
                return 'Country code must be 2 letters';
              }
              if (CountryCurrencyUtil.getCurrencyForCountry(
                    value.toUpperCase(),
                  ) ==
                  null) {
                return 'Invalid country code';
              }
              return null;
            },
            onChanged: (value) {
              final upperCaseValue = value.toUpperCase();
              if (_countryCodeController.text != upperCaseValue) {
                _countryCodeController.value = _countryCodeController.value
                    .copyWith(
                      text: upperCaseValue,
                      selection: TextSelection.collapsed(
                        offset: upperCaseValue.length,
                      ),
                    );
              }
            },
            hint: 'Enter two-letter country code (e.g. US)',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              _derivedCurrency != null
                  ? 'Detected Currency: $_derivedCurrency'
                  : 'Enter valid Country Code to see currency',
              style: TextStyle(
                color:
                    _derivedCurrency != null
                        ? Colors.grey[400]
                        : Colors.orange[300],
                fontSize: 13,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CD964),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        strokeWidth: 3,
                      ),
                    )
                    : const Text(
                      'Complete Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: onChanged,
            style: TextStyle(color: readOnly ? Colors.grey[400] : Colors.white),
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
