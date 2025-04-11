import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: "Amit Kumar",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "iitianamit2019@gmail.com",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "0987654321",
  );
  final TextEditingController _reasonController = TextEditingController();

  bool _isDeleting = false;
  String _errorMessage = '';

  /// Retrieve token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Send POST request to delete account
  Future<void> _deleteAccount() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String reason = _reasonController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || reason.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = '';
    });

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _isDeleting = false;
      });
      Fluttertoast.showToast(msg: "No token found. Please login again.");
      return;
    }

    final url = Uri.parse("http://165.232.152.77/api/vendor/profile/delete");

    // Adjust keys if your backend expects different field names
    final body = {
      "name": name,
      "email": email,
      "phone": phone,
      "reason": reason,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      setState(() {
        _isDeleting = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // If your API always returns status = 'success' on a successful delete
          Fluttertoast.showToast(msg: data['message'] ?? 'Account deleted.');
          // Possibly log out the user or pop to login
          Navigator.pop(context);
        } else {
          // Show message from server
          Fluttertoast.showToast(msg: data['message'] ?? 'Delete failed.');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      Fluttertoast.showToast(msg: "An error occurred. Please try again.");
      debugPrint("Delete account error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              // Allows scrolling if needed
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar with back arrow and title
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color.fromRGBO(255, 130, 16, 1.0),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Delete Account",
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
                    const SizedBox(height: 24),

                    // Show error if any
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),

                    // Name field
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Name",
                        hintStyle: const TextStyle(fontSize: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Email field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(fontSize: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Phone field
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: "Phone Number",
                        hintStyle: const TextStyle(fontSize: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Reason to delete (multiline)
                    TextField(
                      controller: _reasonController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Enter the reason to delete the account",
                        hintStyle: const TextStyle(fontSize: 16),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isDeleting)
            Container(
              color: Colors.white.withOpacity(0.19),
              child: Center(
                child: Image.asset(
                  'assets/Bird_Full_Eye_Blinking.gif',
                  width: 100, // Adjust size as needed
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
