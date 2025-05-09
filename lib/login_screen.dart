import 'dart:convert';
import 'package:flock/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// For inline validation errors:
  String? _emailError;
  String? _passwordError;

  final String _loginUrl = 'https://api.getflock.io/api/vendor/login';
  final String _deviceUpdateUrl =
      'https://api.getflock.io/api/vendor/devices/update';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final RegExp regex = RegExp(r"^[\w.\+\-]+@([\w\-]+\.)+[\w\-]{2,4}$");
    return regex.hasMatch(email);
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    } else if (!isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    }

    return isValid;
  }

  Future<void> _updateDeviceToken(String accessToken) async {
    try {
      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('Failed to retrieve FCM token');
        return;
      }

      // Prepare payload (adjust based on API requirements)
      final body = {
        'fcm_token': fcmToken,
        'platform': 'android', // or 'ios' based on Platform.isIOS
      };

      final response = await http.post(
        Uri.parse(_deviceUpdateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Device token updated successfully');
      } else {
        print('Failed to update device token: ${response.statusCode}');
        final responseData = jsonDecode(response.body);
        print('Error: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (error) {
      print('Error updating device token: $error');
    }
  }

  Future<void> _login() async {
    if (!_validateInputs()) return;

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      final Map<String, dynamic> body = {'email': email, 'password': password};

      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['message'] != null &&
            responseData['message'].toString().toLowerCase().contains(
              'success',
            )) {
          final token = responseData['data']['access_token'];

          String? userId;
          String? userEmail;
          String? fName;
          String? lName;

          if (responseData['data'] != null &&
              responseData['data']['user'] != null) {
            userId = responseData['data']['user']['id']?.toString();
            userEmail = responseData['data']['user']['email']?.toString();
            fName = responseData['data']['user']['first_name']?.toString();
            lName = responseData['data']['user']['last_name']?.toString();

            print('First name from API: $fName');
            print('Last name from API: $lName');
            print('User details: ${responseData['data']['user']}');
          } else {
            userId =
                responseData['userId']?.toString() ??
                responseData['vendor_id']?.toString();
          }

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setBool('isLoggedIn', true);
          if (userId != null) await prefs.setString('userid', userId);
          if (userEmail != null) await prefs.setString('email', userEmail);
          if (fName != null) await prefs.setString('firstName', fName);
          if (lName != null) await prefs.setString('lastName', lName);

          print('Stored firstName: ${prefs.getString('firstName')}');
          print('Stored lastName: ${prefs.getString('lastName')}');

          // Call API to update device token after successful login
          await _updateDeviceToken(token);

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showError(
            responseData['message'] ?? 'Please check your email or password',
          );
        }
      } else {
        if (response.statusCode == 401) {
          _showError(
            'Invalid credentials. Please check your email or password.',
          );
        } else {
          final message = responseData['message'] ?? 'Login failed.';
          _showError(message);
        }
      }
    } catch (error) {
      _showError('An error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14.0,
          fontFamily: 'YourFontFamily',
        ),
        decoration: AppConstants.textFieldDecoration.copyWith(
          hintText: "Enter Email Address",
          errorText: _emailError,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14.0,
          fontFamily: 'YourFontFamily',
        ),
        decoration: AppConstants.textFieldDecoration.copyWith(
          hintText: "Enter password",
          errorText: _passwordError,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/login_back.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                          'assets/business_logo.png',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 30),
                        const Text('Login', style: TextStyle(fontSize: 24)),
                        const Text(
                          'Login to your account',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        _buildEmailField(),
                        const SizedBox(height: 15),
                        _buildPasswordField(),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                ),
                            child: const Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Forgot password? ',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  TextSpan(
                                    text: 'Reset here',
                                    style: TextStyle(
                                      color: Color.fromRGBO(255, 130, 16, 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        AppConstants.fullWidthButton(
                          text: 'Continue',
                          onPressed: _login,
                        ),

                        const SizedBox(height: 20),
                        TextButton(
                          onPressed:
                              () => Navigator.pushNamed(context, '/register'),
                          child: const Text.rich(
                            TextSpan(
                              text: 'Don’t have an account? ',
                              style: TextStyle(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Create New',
                                  style: TextStyle(
                                    color: Color.fromRGBO(255, 130, 16, 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
