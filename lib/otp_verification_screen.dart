import 'dart:convert';
import 'package:flock/HomeScreen.dart';
import 'package:flock/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;

  const OtpVerificationScreen({
    required this.email,
    required this.firstName,
    required this.lastName,
    Key? key,
  }) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final String _otpUrl = 'http://165.232.152.77/api/vendor/otp-login';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final String otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Please enter the OTP.');
      return;
    }

    try {
      final Map<String, dynamic> body = {
        'email': widget.email,
        'otp': otp,
      };

      final response = await http.post(
        Uri.parse(_otpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint("OTP Verification Response Status: ${response.statusCode}");
      debugPrint("OTP Verification Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Store user data and token only after successful OTP verification
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', widget.firstName);
          await prefs.setString('lastName', widget.lastName);
          await prefs.setString('email', widget.email);

          // Handle token storage
          String? newToken;
          if (responseData['data'] != null && responseData['data'] is Map) {
            newToken = responseData['data']['token'] ??
                responseData['data']['access_token'];
          }
          if (newToken != null) {
            await prefs.setString('access_token', newToken);
            debugPrint("Stored token after OTP verification: $newToken");
          } else {
            debugPrint("No token returned from OTP verification API");
          }

          // Navigate to HomeScreen and remove previous routes
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => TabDashboard()),
              (route) => false,
            );
          }
        } else {
          _showError(responseData['message'] ?? 'OTP verification failed.');
        }
      } else {
        _showError(
            'OTP verification failed with status: ${response.statusCode}.');
      }
    } catch (error) {
      debugPrint("Error during OTP verification: $error");
      _showError('An error occurred. Please try again.');
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Clear any stored data if user navigates back
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('firstName');
        await prefs.remove('lastName');
        await prefs.remove('email');
        debugPrint("Cleared SharedPreferences on back navigation");
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppConstants.customAppBar(
          context: context,
          title: 'OTP Verification',
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Enter the OTP sent to ${widget.email}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  hintText: 'OTP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
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
                  onPressed: _verifyOtp,
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}