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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isDeleting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails(); // Load user details when the screen initializes
  }

  /// Retrieve user details from SharedPreferences
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String firstName = prefs.getString('firstName') ?? '';
      String lastName = prefs.getString('lastName') ?? '';
      _nameController.text = '$firstName $lastName'.trim(); // Combine names
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
    });
  }

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
    if (name.isEmpty || email.isEmpty || reason.isEmpty) {
      Fluttertoast.showToast(msg: 'Please fill name, email, and reason fields');
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
      Fluttertoast.showToast(msg: 'No token found. Please login again.');
      return;
    }

    final url = Uri.parse('https://api.getflock.io/api/vendor/profile/delete');

    final body = {
      'name': name,
      'email': email,
      if (phone.isNotEmpty) 'phone': phone, // Include phone only if provided
      'reason': reason,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      setState(() {
        _isDeleting = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          Fluttertoast.showToast(msg: data['message'] ?? 'Account deleted.');
          if (mounted) Navigator.pop(context);
        } else {
          Fluttertoast.showToast(msg: data['message'] ?? 'Delete failed.');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      Fluttertoast.showToast(msg: 'An error occurred. Please try again.');
      debugPrint('Delete account error: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Image.asset(
                            'assets/back_updated.png',
                            height: 40,
                            width: 34,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Delete Account",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.redAccent
                                  : Colors.red,
                        ),
                      ),

                    // Name field (read-only)
                    TextField(
                      controller: _nameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Name",
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: Theme.of(context).inputDecorationTheme.border,
                        focusedBorder:
                            Theme.of(
                              context,
                            ).inputDecorationTheme.focusedBorder,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Email field (read-only)
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: Theme.of(context).inputDecorationTheme.border,
                        focusedBorder:
                            Theme.of(
                              context,
                            ).inputDecorationTheme.focusedBorder,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Phone field (read-only)
                    TextField(
                      controller: _phoneController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Phone Number (Optional)",
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: Theme.of(context).inputDecorationTheme.border,
                        focusedBorder:
                            Theme.of(
                              context,
                            ).inputDecorationTheme.focusedBorder,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Reason to delete (editable)
                    TextField(
                      controller: _reasonController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Enter the reason to delete the account",
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: Theme.of(context).inputDecorationTheme.border,
                        focusedBorder:
                            Theme.of(
                              context,
                            ).inputDecorationTheme.focusedBorder,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _deleteAccount,
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: const Text(
                          "Confirm Deletion",
                          style: TextStyle(fontSize: 16),
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
            Stack(
              children: [
                Container(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.14),
                ),
                Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Image.asset(
                      'assets/Bird_Full_Eye_Blinking.gif',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
