import 'dart:convert';
import 'package:flock/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Visibility flags for each password field
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Controllers for user input
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  /// Retrieve the stored token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _changePassword() async {
    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }
    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(
        msg: "New password and confirm password do not match",
      );
      return;
    }

    final String urlString =
        "http://165.232.152.77/api/vendor/profile/change-password";
    final payload = {
      "old_password": currentPassword,
      "password": newPassword,
      "password_confirmation": confirmPassword,
    };

    // Retrieve token for authenticated request
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      Fluttertoast.showToast(msg: "No token found. Please login again.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(urlString),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Adjust the success condition if your API uses a different format
        if (data['message'] != null &&
            data['message'].toString().toLowerCase().contains("success")) {
          Fluttertoast.showToast(msg: "Password changed successfully");
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
            msg: data['message'] ?? "Failed to change password",
          );
        }
      } else {
        Fluttertoast.showToast(msg: "Error: ${response.statusCode}");
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
      debugPrint("Error during change password: $error");
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light background
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with back arrow and title
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Image.asset(
                      'assets/back_updated.png',
                      height: 40,
                      width: 34,
                      fit: BoxFit.contain,
                      // color: const Color.fromRGBO(255, 130, 16, 1.0), // Orange tint
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 30),

              AppConstants.currentPasswordField(
                controller: _currentPasswordController,
                obscureText: !_currentPasswordVisible,
                toggleObscure:
                    () => setState(() {
                      _currentPasswordVisible = !_currentPasswordVisible;
                    }),
              ),
              SizedBox(height: 15),
              AppConstants.newPasswordField(
                controller: _newPasswordController,
                obscureText: !_newPasswordVisible,
                toggleObscure:
                    () => setState(() {
                      _newPasswordVisible = !_newPasswordVisible;
                    }),
              ),
              SizedBox(height: 15),
              AppConstants.confirmPasswordField(
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                toggleObscure:
                    () => setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    }),
              ),
              const Spacer(),

              // Update Password button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(255, 130, 16, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Update Password",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable widget to build a password field.
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
