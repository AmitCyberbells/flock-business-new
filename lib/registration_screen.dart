import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isChecked = false;
  bool _obscureText = true;

  // Controllers for registration fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String _signupUrl = 'http://165.232.152.77/mobi/api/vendor/signup';
  final String _termsUrl = 'http://165.232.152.77/mobi/api/vendor/terms';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Retrieve token stored during login (if any)
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch Terms and Conditions from the API
  Future<void> _fetchTermsAndConditions() async {
    String? token = await _getToken();

    try {
      final response = await http.get(
        Uri.parse(_termsUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Log the raw response for debugging
      print("Terms API Response Status: ${response.statusCode}");
      print("Terms API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Check if the response body is empty
        if (response.body.isEmpty) {
          _showError('Terms and Conditions are not available.');
          return;
        }

        // Try to parse the response as JSON
        try {
          final responseData = jsonDecode(response.body);
          // Assuming the terms are in responseData['data']['terms']
          String terms = responseData['data']?['terms']?.toString() ??
              responseData['terms']?.toString() ??
              'No terms available.';
          _showTermsDialog(terms);
        } catch (e) {
          // If JSON parsing fails, treat the response as plain text
          print("JSON Parsing Error: $e");
          _showTermsDialog(response.body); // Fallback to raw response body
        }
      } else {
        _showError('Error ${response.statusCode}: Unable to fetch terms.');
      }
    } catch (error) {
      _showError('Network error: $error');
    }
  }

  /// Show Terms and Conditions in a dialog
  void _showTermsDialog(String terms) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(terms),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show Date Picker for DOB
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format: YYYY-MM-DD
      });
    }
  }

  Future<void> _register() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String dob = _dobController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        dob.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      _showError('Please fill in all the fields.');
      return;
    }
    if (!isChecked) {
      _showError('You must agree to the Terms and Conditions.');
      return;
    }

    try {
      final Map<String, dynamic> body = {
        'first_name': firstName,
        'last_name': lastName,
        'dob': dob,
        'email': email,
        'phone': phone,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(_signupUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Registration response: $responseData");

        if (responseData['status'] == 'success') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('email', email);

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Success'),
              content: const Text('OTP sent successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtpVerificationScreen(email: email),
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          _showError(responseData['message'] ?? 'Registration failed.');
        }
      } else {
        _showError('Registration failed with status: ${response.statusCode}.');
      }
    } catch (error) {
      _showError('An error occurred. Please try again.');
      print("Error during registration: $error");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_back.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                Container(
                  color: Colors.transparent,
                  child: Image.asset('assets/business_logo.png',
                      width: 120, height: 120),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 30),
                const Text(
                  'Register',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Create your account',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(

                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            hintText: 'First Name',
                            fillColor: Colors.grey,
                            border: InputBorder.none,
                                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            hintText: 'Last Name',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Date of Birth',
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.grey),
                        onPressed: _selectDate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter email address',
                      border: InputBorder.none,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2.0,
                        
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2.0,
                        offset: Offset(0, 1),
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
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                ),
                const SizedBox(height: 25),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isChecked,
                        activeColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            isChecked = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I am 18 years of age and agree to the ',
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(color: Colors.orange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _fetchTermsAndConditions();
                                },
                            ),
                            const TextSpan(text: ' as set out by the '),
                            TextSpan(
                              text: 'User Agreement.',
                              style: const TextStyle(color: Colors.orange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _fetchTermsAndConditions();
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _register,
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Have an account? ',
                      style: TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: 'Login',
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
      ),
    );
  }
}