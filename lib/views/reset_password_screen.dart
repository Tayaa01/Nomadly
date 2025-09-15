import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/otp_digit_input.dart'; // Import the new widget

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  String _resetCode = ''; // Store code as string
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetSuccessful = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the email passed from the previous screen
    _email = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // Validate inputs
    if (_email == null || _email!.isEmpty) {
      setState(() {
        _errorMessage = "Email is missing. Please go back and try again.";
      });
      return;
    }

    if (_resetCode.length < 6) {
      setState(() {
        _errorMessage = "Please enter the complete 6-digit reset code";
      });
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a new password";
      });
      return;
    }

    if (_newPasswordController.text.length < 8) {
      setState(() {
        _errorMessage = "Password must be at least 8 characters";
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.resetPassword(
        email: _email!.trim(),
        code: _resetCode.trim(),
        newPassword: _newPasswordController.text,
      );

      setState(() {
        _isLoading = false;
        _resetSuccessful = result['success'];
      });

      if (!result['success']) {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred. Please try again.";
      });
      print("Password reset error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            _resetSuccessful
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child:
                _resetSuccessful ? _buildSuccessContent() : _buildResetForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter the reset code sent to your email and create a new password',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Code',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OtpDigitInput(
                length: 6,
                onComplete: (code) {
                  setState(() {
                    _resetCode = code;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildInputField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Enter new password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm new password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 32),
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
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CD964),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 100),
        const SizedBox(height: 32),
        const Text(
          'Password Reset Successful',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your password has been successfully reset. You can now sign in with your new password.',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/sign-in');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CD964),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
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
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: const TextStyle(color: Colors.white),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
