import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String _loginUrl = 'http://165.232.152.77/mobi/api/vendor/login';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }

    try {
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Login response: $responseData");

        if (responseData['message'] != null &&
            responseData['message'].toString().toLowerCase().contains('success')) {
          // Extract userId, email, and full name from the API response
          String? userId;
          String? userEmail;
          String? fName;
          String? lName;
          if (responseData['data'] != null && responseData['data']['user'] != null) {
            userId = responseData['data']['user']['id']?.toString();
            userEmail = responseData['data']['user']['email']?.toString();
            fName = responseData['data']['user']['first_name']?.toString();
            lName = responseData['data']['user']['last_name']?.toString();
          } else {
            // Fallback extraction if needed
            userId = responseData['userId']?.toString() ?? responseData['vendor_id']?.toString();
          }
          if (userId != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('userid', userId);
            if (userEmail != null) {
              await prefs.setString('email', userEmail);
            }
            // Store full name if available
            if (fName != null && lName != null) {
              await prefs.setString('firstName', fName);
              await prefs.setString('lastName', lName);
            }
            print("Saved userId: $userId, email: $userEmail, full name: $fName $lName");
          } else {
            print("Warning: userId not found in response");
          }
          Navigator.pushNamed(context, '/home');
        } else {
          _showError(responseData['message'] ?? 'Login failed.');
        }
      } else {
        _showError('Login failed with status: ${response.statusCode}.');
      }
    } catch (error) {
      _showError('An error occurred. Please try again.');
      print("Error during login: $error");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(
      String hintText, bool isPassword, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        decoration: InputDecoration(
          hintText: 'Enter password',
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
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
            child: Image.asset(
              'assets/login_back.jpg',
              fit: BoxFit.cover,
            ),
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
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.orange),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Image.asset(
                          'assets/business_logo.png',
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Login',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Login to your account',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField('Enter email address', false, _emailController),
                        const SizedBox(height: 15),
                        _buildPasswordField(),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Forgot password? ',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  TextSpan(
                                    text: 'Reset here',
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _login,
                            child: const Text(
                              'Continue',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: 'Don’t have an account? ',
                              style: TextStyle(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Create New',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold),
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
