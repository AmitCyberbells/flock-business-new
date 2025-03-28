import 'dart:async'; // Import for TimeoutException
import 'dart:convert';
import 'package:flock/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your email address.");
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("http://165.232.152.77/mobi/api/vendor/forgot-password");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10)); // Add a timeout for the request

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (responseData['message'] != null &&
            responseData['message'].toString().toLowerCase().contains('success')) {
          Fluttertoast.showToast(msg: "Reset instructions have been sent to your email.");
        } else {
          Fluttertoast.showToast(msg: responseData['message'] ?? 'Reset failed.');
        }
      } else if (response.statusCode == 422) {
        // Handle 422 Unprocessable Entity
        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final errorMessage = errors.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('\n');
          Fluttertoast.showToast(msg: errorMessage);
        } else {
          Fluttertoast.showToast(msg: responseData['message'] ?? 'Validation failed.');
        }
      } else {
        // Handle other status codes
        debugPrint("Error response: ${response.body}");
        Fluttertoast.showToast(msg: "Reset failed with status: ${response.statusCode}");
      }
    } on TimeoutException catch (e) {
      // Handle timeout errors
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Request timed out. Please try again.");
      debugPrint("Timeout error: $e");
    } on http.ClientException catch (e) {
      // Handle network-related errors (e.g., no internet connection)
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Network error. Please check your internet connection.");
      debugPrint("Network error: $e");
    } catch (error) {
      // Handle all other errors
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
      debugPrint("Unexpected error: $error");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login_back.jpg'), // Background image
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/business_logo.png', height: 120, width: 120),
                  const SizedBox(height: 40),
                  // Title
                  const Text(
                    "Reset Password",
                    style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 30),
                  // Input field with shadow
                  Container(
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
          style: const TextStyle(fontSize: 14),
        decoration: AppConstants.textFieldDecoration.copyWith(
            hintText: "Enter email address", // Define hintText here
          ),
          // Use the defined decoration
        ),
      ),
                  
                  const SizedBox(height: 40),
              AppConstants.fullWidthButton(
  text: "Continue",
  onPressed: _resetPassword,
)


                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}