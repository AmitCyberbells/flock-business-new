import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

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
      Fluttertoast.showToast(msg: "New password and confirm password do not match");
      return;
    }

    final url = Uri.parse("http://165.232.152.77/mobi/api/vendor/reset-password");
    final payload = {
      "current_password": currentPassword,
      "new_password": newPassword,
      "confirm_password": confirmPassword,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null &&
            data['message'].toString().toLowerCase().contains("success")) {
          Fluttertoast.showToast(msg: "Password changed successfully");
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(msg: data['message'] ?? "Failed to change password");
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
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Change password",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Current Password
              _buildPasswordField(
                controller: _currentPasswordController,
                hintText: "Enter current password",
                isObscured: !_currentPasswordVisible,
                onToggle: () => setState(() {
                  _currentPasswordVisible = !_currentPasswordVisible;
                }),
              ),
              const SizedBox(height: 15),

              // New Password
              _buildPasswordField(
                controller: _newPasswordController,
                hintText: "Enter new password",
                isObscured: !_newPasswordVisible,
                onToggle: () => setState(() {
                  _newPasswordVisible = !_newPasswordVisible;
                }),
              ),
              const SizedBox(height: 15),

              // Confirm New Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: "Confirm new password",
                isObscured: !_confirmPasswordVisible,
                onToggle: () => setState(() {
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
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Update Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
