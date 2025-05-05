import 'package:flutter/material.dart';
import 'dart:convert';
// Import for PlatformException
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nomadly/services/auth_service.dart';
import 'package:nomadly/models/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:nomadly/network/api_config.dart';
import 'finish_setup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '177250922222-ap475c7pr5pj7m655i3foh4r2utmjsle.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await _authService.getRememberedCredentials();
    if (credentials != null) {
      setState(() {
        _emailController.text = credentials['email'];
        _passwordController.text = credentials['password'];
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Email and password are required";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (!mounted) return;

        // Extract token and user data from the successful result
        final responseData = result['data'];
        if (responseData != null &&
            responseData['access_token'] != null &&
            responseData['user'] != null) {
          final String appAccessToken = responseData['access_token'].toString();
          final User user = User.fromJson(
            responseData['user'] as Map<String, dynamic>,
          );

          // Update AuthProvider
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.loginSuccess(appAccessToken, user);

          // Navigate based on profile completeness (similar to Google Sign-In)
          // ignore: unnecessary_null_comparison
          if (user.countryCode == null || user.countryCode!.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => FinishSetupPage(
                      firstName: user.firstName,
                      lastName: user.lastName,
                    ),
              ),
            );
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Handle case where backend response format is invalid after success
          setState(() {
            _errorMessage =
                'Login successful, but received invalid data from server.';
          });
        }
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
      print("Sign in error: $e");
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      // Always sign out to force account picker
      await _googleSignIn.signOut();
      print('[GOOGLE_SIGN_IN] Starting Google sign-in flow');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('[GOOGLE_SIGN_IN] Google user: ' + (googleUser?.email ?? 'null'));
      if (googleUser == null) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = 'Google sign-in cancelled.';
        });
        print('[GOOGLE_SIGN_IN] Sign-in cancelled by user');
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('[GOOGLE_SIGN_IN] idToken: ' + (googleAuth.idToken ?? 'null'));
      print(
        '[GOOGLE_SIGN_IN] accessToken: ' + (googleAuth.accessToken ?? 'null'),
      );
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = 'Failed to retrieve Google tokens.';
        });
        print('[GOOGLE_SIGN_IN] Failed to retrieve tokens');
        return;
      }
      print(
        '[GOOGLE_SIGN_IN] Sending tokens to backend: ' +
            "${ApiConfig.BASE_URL}/auth/google/tokens",
      );
      final backendResponse = await http.post(
        Uri.parse("${ApiConfig.BASE_URL}/auth/google/tokens"),
        headers: ApiConfig.commonHeaders,
        body: jsonEncode({
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
        }),
      );
      print(
        '[GOOGLE_SIGN_IN] Backend response status: ' +
            backendResponse.statusCode.toString(),
      );
      print('[GOOGLE_SIGN_IN] Backend response body: ' + backendResponse.body);
      if (backendResponse.statusCode == 200 ||
          backendResponse.statusCode == 201) {
        final Map<String, dynamic> backendData = jsonDecode(
          backendResponse.body,
        );
        final String? appAccessToken = backendData['access_token'];
        final Map<String, dynamic>? userMap = backendData['user'];
        if (appAccessToken != null && userMap != null) {
          final User user = User.fromJson(userMap);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AuthService.TOKEN_KEY, appAccessToken);
          await prefs.setString(
            AuthService.USER_KEY,
            jsonEncode(user.toJsonForStorage()),
          );
          if (!mounted) return;
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.loginSuccess(appAccessToken, user);
          // Check if countryCode is missing or empty
          if (user.countryCode == null || user.countryCode!.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => FinishSetupPage(
                      firstName: user.firstName,
                      lastName: user.lastName,
                    ),
              ),
            );
            return; // Prevent further execution
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() {
            _isGoogleLoading = false;
            _errorMessage = 'Invalid response from backend.';
          });
          print('[GOOGLE_SIGN_IN] Invalid response from backend');
        }
      } else {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = 'Backend authentication failed.';
        });
        print('[GOOGLE_SIGN_IN] Backend authentication failed');
      }
    } catch (e, s) {
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = 'Google sign-in failed: $e';
      });
      print('[GOOGLE_SIGN_IN] Exception: $e');
      print('[GOOGLE_SIGN_IN] Stacktrace: $s');
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
                const Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your account',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 40),
                _buildInputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _rememberMe,
                          onChanged:
                              (value) => setState(() => _rememberMe = value),
                          activeColor: const Color(0xFF4CD964),
                          inactiveTrackColor: Colors.grey[800],
                          inactiveThumbColor: Colors.grey[400],
                        ),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/request-reset');
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF4CD964),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CD964),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(
                      0xFF4CD964,
                    ).withOpacity(0.5),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[800], thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[800], thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                        icon: Icons.g_mobiledata_sharp,
                        label: 'Google',
                        isLoading: _isGoogleLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/sign-up');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[400]),
                        children: const [
                          TextSpan(
                            text: 'Sign Up',
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
                const SizedBox(height: 20),
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
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3C)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(icon, color: Colors.grey[400], size: 22),
              ),
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
              contentPadding: EdgeInsets.symmetric(
                vertical: 18,
                horizontal: isPassword ? 0 : 16,
              ),
            ),
            keyboardType:
                label == 'Email'
                    ? TextInputType.emailAddress
                    : TextInputType.visiblePassword,
            textInputAction:
                isPassword ? TextInputAction.done : TextInputAction.next,
            onSubmitted: (_) {
              if (!isPassword) {
              } else {
                _signIn();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isLoading,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1C1C1E),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF3A3A3C)),
        ),
        elevation: 0,
        disabledBackgroundColor: const Color(0xFF1C1C1E).withOpacity(0.6),
      ),
      child:
          isLoading
              ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
    );
  }
}
