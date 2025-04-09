import 'dart:convert';
import 'package:flock/NewPasswordScreen.dart';
import 'package:flock/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({required this.email, Key? key}) : super(key: key);

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

print("Response Status: ${response.statusCode}");
print("Response Body: ${response.body}");


      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
if (responseData['status'] == 'success') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewPasswordScreen(email: widget.email),
      ),
    );
  }else {
  // Show error if status isn't success
  _showError(responseData['message'] ?? 'OTP verification failed.');
}

      } else {
        _showError('OTP verification failed with status: ${response.statusCode}.');
      }
    } catch (error) {
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppConstants.customAppBar(
    context: context,
    title: 'OTP Verification',
    // Optionally, if you want a different back icon, you can pass:
    // backIconAsset: 'assets/your_custom_back.png',
  ),// 'back' is a String holding the asset path, e.g., 'assets/images/back_icon.png'

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Enter the OTP sent to your email',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                hintText: 'OTP',
                border: OutlineInputBorder(),
              ),
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
            )
          ],
        ),
      ),
    );
  }
}
