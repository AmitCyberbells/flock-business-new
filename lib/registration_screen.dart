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
      _firstNameError = null;
      _lastNameError = null;
      _dobError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty) {
      _firstNameError = 'First name is required';
      isValid = false;
    }
    if (lastName.isEmpty) {
      _lastNameError = 'Last name is required';
      isValid = false;
    }
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
        'dob': dob.isEmpty ? null : dob,
        'location': location.isEmpty ? null : location,
        'email': email,
        'phone': phone.isEmpty ? null : phone,
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
          // Do NOT store access_token or user data yet
          debugPrint("Signup successful, navigating to OTP verification");

          // Show dialog and navigate to OTP screen
          await showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Success'),
                  content: const Text('OTP sent successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        debugPrint("Dialog OK button pressed");
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );

          // Navigate to OTP verification with user data
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OtpVerificationScreen(
                      email: email,
                      firstName: firstName,
                      lastName: lastName,
                    ),
              ),
            ).then((result) {
              // Handle case where user navigates back without verifying
              if (result == null && mounted) {
                debugPrint("Returned from OTP screen without verification");
                _showError(
                  'OTP verification incomplete. Please register again.',
                );
                // Optionally clear controllers
                _firstNameController.clear();
                _lastNameController.clear();
                _emailController.clear();
                _phoneController.clear();
                _passwordController.clear();
                _dobController.clear();
                _locationController.clear();
              }
            });
          }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    bool obscureText = false,
    IconButton? suffixIcon,
    VoidCallback? onTap,
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
        readOnly: onTap != null,
        onTap: onTap,
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
        backgroundColor: Colors.transparent,
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
          Positioned.fill(
            child: Image.asset('assets/login_back.jpg', fit: BoxFit.cover),
          ),
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
                    hintText: 'Enter phone number (optional)',
                    errorText: _phoneError,
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _dobController,
                    hintText: 'Date of Birth (optional)',
                    errorText: _dobError,
                    onTap: () async {
                      final DateTime today = DateTime.now();
                      final DateTime eighteenYearsAgo = DateTime(
                        today.year - 18,
                        today.month,
                        today.day,
                      );

                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: eighteenYearsAgo,
                      );

                      if (pickedDate != null) {
                        String formattedDate =
                            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        _dobController.text = formattedDate;
                      }
                    },
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _locationController,
                    hintText: 'Enter your location (optional)',
                    onTap: () async {
                      final selectedLocation = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationPicker(),
                        ),
                      );
                      if (selectedLocation != null) {
                        setState(() {
                          _locationController.text =
                              selectedLocation.toString();
                        });
                      }
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: const Color.fromRGBO(255, 130, 16, 1),
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
                                style: const TextStyle(
                                  color: const Color.fromRGBO(255, 130, 16, 1),
                                ),
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
                                style: const TextStyle(
                                  color: const Color.fromRGBO(255, 130, 16, 1),
                                ),
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
