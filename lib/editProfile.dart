import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;

  // Profile picture path: can be a URL (if from server) or a local file path
  String profilePic = "";
  bool _isUpdating = false; // Loader state
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the passed profile data from arguments (if any).
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    firstNameController = TextEditingController(text: args['firstName'] ?? "");
    lastNameController = TextEditingController(text: args['lastName'] ?? "");
    emailController = TextEditingController(text: args['email'] ?? "");
    profilePic = args['profilePic'] ?? "";
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  /// Retrieve the token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Opens the gallery and lets the user pick an image.
  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        // Save the file path so we can show it in the avatar.
        profilePic = image.path;
      });
    }
  }

  /// Update profile via API (multipart/form-data).
  Future<void> _updateProfile() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = '';
    });

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _isUpdating = false;
      });
      Fluttertoast.showToast(msg: "No token found. Please login again.");
      return;
    }

    final url = Uri.parse("http://165.232.152.77/mobi/api/vendor/profile/update");

    try {
      // Use MultipartRequest to handle file upload (profile image)
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      // If your server expects 'application/json' for non-file fields,
      // you can leave out the 'Content-Type' here. It's automatically set for multipart.
      // For extra safety, you can do:
      // request.headers['Content-Type'] = 'multipart/form-data';

      // Add text fields. Adjust field names as needed by your backend.
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['email'] = email;

      // If profilePic is a local path (not an HTTP URL), upload the file.
      if (profilePic.isNotEmpty && !profilePic.startsWith('http')) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image', // Adjust if your backend uses a different key
            profilePic,
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isUpdating = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check success condition based on your API
        if (data['status'] == 'success') {
          Fluttertoast.showToast(msg: data['message'] ?? 'Profile updated!');
          // Optionally save updated data locally
          // e.g., store new name/email in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('email', email);
          // If you want to store the new server image path, parse data['profile_image'] or similar
          // For demonstration, we just store the local or old path:
          await prefs.setString('profilePic', profilePic);

          // Return to previous screen with updated data
          Navigator.pop(context, {
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'profilePic': profilePic,
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Profile update failed.';
          });
          Fluttertoast.showToast(msg: _errorMessage);
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode} updating profile.';
        });
        Fluttertoast.showToast(msg: _errorMessage);
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _errorMessage = 'Network error: $e';
      });
      Fluttertoast.showToast(msg: _errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Screen background.
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back arrow and title.
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Profile avatar with camera icon.
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: profilePic.isNotEmpty
                              ? (profilePic.startsWith('http')
                                  ? NetworkImage(profilePic)
                                  : FileImage(File(profilePic)) as ImageProvider)
                              : null,
                          child: profilePic.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.orange,
                              child: IconButton(
                                onPressed: _selectImage,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // First Name field.
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Last Name field.
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Email field.
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Error message (if any)
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const Spacer(),
                  // Update button.
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Update',
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
          // Loading overlay
          if (_isUpdating)
            Container(
              color: Colors.white54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
