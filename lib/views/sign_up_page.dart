import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Add this line
  final _countryCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // Add this line
  String? _passwordError; // Add this line for validation
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Add this line
    _countryCodeController.dispose();
    super.dispose();
  }

  // Add this method to validate passwords
  bool _validatePasswords() {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _passwordError = "Password fields cannot be empty";
      });
      return false;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = "Passwords don't match";
      });
      return false;
    }
    
    setState(() {
      _passwordError = null;
    });
    return true;
  }

  // Add this method to handle sign up
  Future<void> _signUp() async {
    // Validate passwords first
    if (!_validatePasswords()) {
      return;
    }

    // Validate required fields
    if (_firstNameController.text.isEmpty || 
        _lastNameController.text.isEmpty || 
        _emailController.text.isEmpty ||
        _countryCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = "All fields are required";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        countryCode: _countryCodeController.text.trim().toUpperCase(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Registration successful, navigate to home or login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Color(0xFF4CD964),
          ),
        );
        // Navigate to login page
        Navigator.pushReplacementNamed(context, '/sign-in');
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred. Please try again.";
      });
      print("Sign up error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Logo (removed back button)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Nomadly',
                      style: TextStyle(
                        color: Color(0xFF4CD964),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Welcome Text
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to start your journey',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // First Name Input
                _buildInputField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Last Name Input
                _buildInputField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Email Input
                _buildInputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password Input
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 20),

                // Confirm Password Input - Add this block
                _buildInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isConfirmPassword: true,
                  error: _passwordError,
                ),
                const SizedBox(height: 20),

                // Country Code Input
                _buildInputField(
                  controller: _countryCodeController,
                  label: 'Country Code',
                  hint: 'Enter your country code (e.g., US)',
                  icon: Icons.flag_outlined,
                ),
                const SizedBox(height: 32),

                // Display error message if any
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CD964),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Sign In Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: Color(0xFF4CD964),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    String? error,
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
            border: Border.all(
              color: error != null && (isPassword || isConfirmPassword)
                  ? Colors.red.withOpacity(0.8)
                  : const Color(0xFF333333),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isConfirmPassword
                            ? (_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)
                            : (_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        setState(() {
                          if (isConfirmPassword) {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          } else {
                            _obscurePassword = !_obscurePassword;
                          }
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (error != null && (isPassword || isConfirmPassword))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
