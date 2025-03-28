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

  String profilePic = "";
  bool _isUpdating = false;
  String _errorMessage = '';
  File? _selectedImage; // To store the selected image file

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

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
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields as per the API requirements
      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['email'] = email;
      // Add other fields required by the API (as per Postman screenshot)
      request.fields['address'] = ''; // Add actual value if available
      request.fields['lat'] = ''; // Add actual value if available
      request.fields['lon'] = ''; // Add actual value if available
      request.fields['contact'] = ''; // Add actual value if available
      request.fields['dob'] = ''; // Add actual value if available
      request.fields['gender'] = ''; // Add actual value if available
      request.fields['zipcode'] = ''; // Add actual value if available
      request.fields['business_name'] = ''; // Add actual value if available

      // If an image was selected, upload it
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // Changed to match the API's expected field name
            _selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isUpdating = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Profile Update Response: $data"); // Log the response for debugging
        if (data['status'] == 'success') {
          Fluttertoast.showToast(msg: data['message'] ?? 'Profile updated!');

          // Update profilePic with the new image URL from the API response
          String newProfilePic = data['data']?['image']?.toString() ?? profilePic;

          // Save updated data in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('email', email);
          await prefs.setString('profilePic', newProfilePic);

          print("Stored in SharedPreferences - First Name: $firstName, Last Name: $lastName, Email: $email, Profile Pic: $newProfilePic");

          // Return updated data to the previous screen
          Navigator.pop(context, {
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'profilePic': newProfilePic,
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
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.blue),
                      ),
                      Expanded(
                        child: Center(
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24), // To balance the back arrow
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (profilePic.isNotEmpty && profilePic.startsWith('http')
                                  ? NetworkImage(profilePic)
                                  : null),
                          child: (profilePic.isEmpty && _selectedImage == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
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
                  // First Name and Last Name in a Row
                  Row(
                    children: [
                      // First Name TextField
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: firstNameController,
                            decoration: InputDecoration(
                              hintText: 'First Name',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Space between First Name and Last Name
                      // Last Name TextField
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: lastNameController,
                            decoration: InputDecoration(
                              hintText: 'Last Name',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Email TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Password TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(255, 130, 16, 1), // Orange color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'UPDATE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
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