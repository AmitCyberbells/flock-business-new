import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flock/constants.dart'; // Adjust the import path as needed.
import 'package:flock/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;

  String profilePic = "";
  bool _isLoading = false;
  bool _isUpdating = false;
  String _errorMessage = '';
  File? _selectedImage;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No token found. Please login again.';
      });
      Fluttertoast.showToast(msg: _errorMessage);
      return;
    }

    const String profileUrl = 'https://api.getflock.io/api/vendor/profile';
    try {
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint("Profile Fetch Response Status: ${response.statusCode}");
      debugPrint("Profile Fetch Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final userData = data['data'];
          setState(() {
            firstNameController.text = userData['first_name'] ?? '';
            lastNameController.text = userData['last_name'] ?? '';
            emailController.text = userData['email'] ?? '';
            phoneController.text = userData['contact'] ?? '';
            profilePic = userData['image'] ?? '';
            _isLoading = false;
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', userData['first_name'] ?? '');
          await prefs.setString('lastName', userData['last_name'] ?? '');
          await prefs.setString('email', userData['email'] ?? '');
          await prefs.setString('profilePic', userData['image'] ?? '');
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Failed to fetch profile.';
          });
          Fluttertoast.showToast(msg: _errorMessage);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch profile. Please try again.';
        });
        Fluttertoast.showToast(msg: _errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
      Fluttertoast.showToast(msg: _errorMessage);
    }
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      Fluttertoast.showToast(
        msg: 'Camera permission is permanently denied. Please enable it in settings.',
      );
      await openAppSettings();
      return false;
    } else {
      Fluttertoast.showToast(msg: 'Camera permission denied.');
      return false;
    }
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(
                  'Take a Photo',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  bool hasPermission = await _requestCameraPermission();
                  if (hasPermission) {
                    _pickImage(ImageSource.camera);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
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
    final password = passwordController.text.trim();
    final contact = phoneController.text.trim();

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

    final url = Uri.parse("https://api.getflock.io/api/vendor/profile/update");

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['first_name'] = firstName;
      request.fields['last_name'] = lastName;
      request.fields['email'] = email;
      request.fields['contact'] = contact;

      if (password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isUpdating = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          Fluttertoast.showToast(msg: data['message'] ?? 'Profile updated!');
          String newProfilePic = data['data']?['image']?.toString() ?? profilePic;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('email', email);
          await prefs.setString('profilePic', newProfilePic);

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _isLoading
                  ? Stack(
                      children: [
                        Container(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.14),
                        ),
                        Container(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                          child: Center(
                            child: Image.asset(
                              'assets/Bird_Full_Eye_Blinking.gif',
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                             InkWell(
  onTap: () => Navigator.of(context).pop(),
  child: Image.asset(
    'assets/back_updated.png',
    height: 40,
    width: 34,
    // fit: BoxFit.contain,
    // color: Theme.of(context).colorScheme.primary, // Orange tint
  ),
),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "Edit Profile",
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (profilePic.isNotEmpty && profilePic.startsWith('http')
                                          ? NetworkImage(profilePic)
                                          : null) as ImageProvider<Object>?,
                                  child: (profilePic.isEmpty && _selectedImage == null)
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Theme.of(context).iconTheme.color,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: IconButton(
                                        onPressed: _selectImage,
                                        icon: Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.onPrimary,
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
                          Row(
                            children: [
                              Expanded(
                                child: AppConstants.firstNameField(
                                  controller: firstNameController,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppConstants.lastNameField(
                                  controller: lastNameController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          TextField(
                            controller: emailController,
                            readOnly: true,
                            keyboardType: TextInputType.emailAddress,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 14.0,
                                ),
                            decoration: InputDecoration(
                              hintText: 'Enter Email Address',
                              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 14.0,
                                  ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          TextField(
                            controller: phoneController,
                            readOnly: true,
                            keyboardType: TextInputType.phone,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 14.0,
                                ),
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 14.0,
                                  ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          const SizedBox(height: 30),
                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                                    backgroundColor: MaterialStateProperty.all(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                              onPressed: _updateProfile,
                              child: Text(
                                'Update',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontSize: 18,
                                      color: Theme.of(context).colorScheme.onPrimary,
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
            Stack(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.14),
                ),
                Container(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
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
}