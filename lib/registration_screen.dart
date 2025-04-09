import 'dart:convert';
import 'package:flock/TermsAndConditionsPage.dart';
import 'package:flock/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'otp_verification_screen.dart';
import 'constants.dart'; // Adjust the import path as needed.

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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Error messages for inline validation
  String? _firstNameError;
  String? _lastNameError;
  String? _dobError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  final String _signupUrl = 'http://165.232.152.77/api/vendor/signup';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final RegExp regex = RegExp(r"^[\w.\+\-]+@([\w\-]+\.)+[\w\-]{2,4}$");
    return regex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    return phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      // Reset errors before validating
      _firstNameError = null;
      _lastNameError = null;
      _dobError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final dob = _dobController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // Validate First Name
    if (firstName.isEmpty) {
      _firstNameError = 'First name is required';
      isValid = false;
    }
    // Validate Last Name
    if (lastName.isEmpty) {
      _lastNameError = 'Last name is required';
      isValid = false;
    }
    // Validate Date of Birth
    if (dob.isEmpty) {
      _dobError = 'Date of birth is required';
      isValid = false;
    }
    // Validate Email
    if (email.isEmpty) {
      _emailError = 'Email is required';
      isValid = false;
    } else if (!isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
      isValid = false;
    }
    // Validate Phone Number
    if (phone.isEmpty) {
      _phoneError = 'Phone number is required';
      isValid = false;
    } else if (!isValidPhone(phone)) {
      _phoneError = 'Please enter a valid 10-digit phone number';
      isValid = false;
    }
    // Validate Password
    if (password.isEmpty) {
      _passwordError = 'Password is required';
      isValid = false;
    }
    return isValid;
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String dob = _dobController.text.trim();
    final String location = _locationController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;

    try {
      final Map<String, dynamic> body = {
        'first_name': firstName,
        'last_name': lastName,
        'dob': dob,
        'location': location,
        'email': email,
        'phone': phone,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(_signupUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint("Signup Response Status: ${response.statusCode}");
      debugPrint("Signup Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('email', email);

          if (responseData['data'] != null &&
              responseData['data']['access_token'] != null) {
            final token = responseData['data']['access_token'];
            await prefs.setString('access_token', token);
            debugPrint("Stored token after signup: $token");
          } else {
            debugPrint("No token returned from signup API");
          }

          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Success'),
                  content: const Text('OTP sent successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    OtpVerificationScreen(email: email),
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
      debugPrint("Error during signup: $error");
      _showError('An error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Error'),
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

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _locationController.text =
                '${place.street}, ${place.locality}, ${place.country}';
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to get location. Please try again.')),
      );
    }
  }

  // Helper method for building text fields with inline validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    bool obscureText = false,
    IconButton? suffixIcon,
    VoidCallback? onTap, // 👈 Add this line
  }) {
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
        controller: controller,
        obscureText: obscureText,
        readOnly: onTap != null, // 👈 Prevents keyboard if onTap is set
        onTap: onTap, // 👈 Executes the passed onTap function
        style: const TextStyle(color: Colors.black, fontSize: 14.0),
        decoration: AppConstants.textFieldDecoration.copyWith(
          hintText: hintText,
          errorText: errorText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Match background image
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        leadingWidth: 80,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/login_back.jpg', fit: BoxFit.cover),
          ),
          // Form content
          SafeArea(
            child: SingleChildScrollView(
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
                  const Text('Register', style: TextStyle(fontSize: 24)),
                  const Text(
                    'Create your account',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // First Name and Last Name in one row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          hintText: 'First Name',
                          errorText: _firstNameError,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          hintText: 'Last Name',
                          errorText: _lastNameError,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter email address',
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Enter phone number',
                    errorText: _phoneError,
                  ),
                  const SizedBox(height: 25),
                 _buildTextField(
  controller: _dobController,
  hintText: 'Date of Birth',
  errorText: _dobError,
  onTap: () async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      String formattedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      _dobController.text = formattedDate;
    }
  },
),

                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _locationController,
                    hintText: 'Enter your location',

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationPicker(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Enter password',
                    errorText: _passwordError,
                    obscureText: _obscureText,
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
                  const SizedBox(height: 30),
                  // Checkbox and link for Terms and Conditions/User Agreement
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
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const TermsAndConditionsPage(),
                                          ),
                                        );
                                      },
                              ),
                              const TextSpan(text: ' as set out by the '),
                              TextSpan(
                                text: 'User Agreement.',
                                style: const TextStyle(color: Colors.orange),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const TermsAndConditionsPage(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  AppConstants.fullWidthButton(
                    text: "Continue",
                    onPressed: _register,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
