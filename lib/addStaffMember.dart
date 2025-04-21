import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flock/constants.dart'; // Adjust the import path as needed.

class AddMemberScreen extends StatefulWidget {
  final Map<String, String>? existingMember;
  const AddMemberScreen({Key? key, this.existingMember}) : super(key: key);

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  bool _obscurePassword = true;
  List<String> _selectedVenues = [];
  List<String> _selectedPermissions = [];

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<dynamic> _venueList = [];
  List<dynamic> _permissionList = [];
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMember != null) {
      _firstNameController.text = widget.existingMember!['firstName'] ?? '';
      _lastNameController.text = widget.existingMember!['lastName'] ?? '';
      _emailController.text = widget.existingMember!['email'] ?? '';
      _phoneController.text = widget.existingMember!['phone'] ?? '';
      _selectedVenues = widget.existingMember!['venue']?.split(',') ?? [];
      _selectedPermissions =
          widget.existingMember!['permission']?.split(',') ?? [];
    }
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = Dio();

    try {
      final venueResponse = await dio.get(
        'http://165.232.152.77/api/vendor/venues',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (venueResponse.statusCode == 200) {
        setState(() {
          _venueList = venueResponse.data['data'] ?? [];
        });
      }
    } catch (e) {
      _showError('Error fetching venues: $e');
    }

    try {
      final permissionResponse = await dio.get(
        'http://165.232.152.77/api/vendor/permissions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (permissionResponse.statusCode == 200) {
        setState(() {
          _permissionList = permissionResponse.data['data'] ?? [];
        });
      }
    } catch (e) {
      _showError('Error fetching permissions: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_firstNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        (_passwordController.text.isEmpty && widget.existingMember == null)) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      Map<String, dynamic> formDataMap = {
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "email": _emailController.text,
        "contact": _phoneController.text,
        if (_passwordController.text.isNotEmpty)
          "password": _passwordController.text,
      };

      for (var i = 0; i < _selectedPermissions.length; i++) {
        formDataMap["permission_ids[$i]"] = _selectedPermissions[i];
      }

      for (var i = 0; i < _selectedVenues.length; i++) {
        formDataMap["venue_ids[$i]"] = _selectedVenues[i];
      }

      if (_pickedImage != null) {
        formDataMap["image"] = await MultipartFile.fromFile(
          _pickedImage!.path,
          filename: p.basename(_pickedImage!.path),
        );
      }

      FormData formData = FormData.fromMap(formDataMap);

      final dio = Dio();
      final String url =
          widget.existingMember != null && widget.existingMember!['id'] != null
              ? "http://165.232.152.77/api/vendor/teams/${widget.existingMember!['id']}"
              : "http://165.232.152.77/api/vendor/teams";

      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingMember != null
                    ? "Member updated successfully!"
                    : "Member added successfully!",
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown error';
        final errors =
            response.data['errors']?.toString() ?? 'No details provided';
        _showError('Failed to save member: $errorMessage\nDetails: $errors');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error saving member: $e');
    }
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppConstants.customAppBar(
        context: context,
        title: 'Add Member',
        // Optionally, if you want a different back icon, you can pass:
        // backIconAsset: 'assets/your_custom_back.png',
      ), // 'back' is a String holding the asset path, e.g., 'assets/images/back_icon.png'

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        _pickedImage != null ? FileImage(_pickedImage!) : null,
                    child:
                        _pickedImage == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                  ),
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color.fromRGBO(255, 130, 16, 1),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _pickImage,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // First Name and Last Name in one row
            Row(
              children: [
                Expanded(
                  child: AppConstants.firstNameField(
                    controller: _firstNameController,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: AppConstants.lastNameField(
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            // Reusable Email Field
            AppConstants.emailField(controller: _emailController),
            SizedBox(height: 15),
            // Reusable Phone Number Field
            AppConstants.phoneField(controller: _phoneController),
            SizedBox(height: 15),
            // Reusable Password Field
            AppConstants.passwordField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              toggleObscure: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            SizedBox(height: 15),
            // For assigning venues:
            AppConstants.assignVenuesDropdown(
              venueList: _venueList,
              selectedVenues: _selectedVenues,
              onConfirm: (values) {
                setState(() {
                  print("Selected Venues: $_selectedVenues");

                  _selectedVenues = values.cast<String>();
                });
              },
            ),
            SizedBox(height: 15),

            // For assigning permissions:
            AppConstants.assignPermissionsDropdown(
              permissionList: _permissionList,
              selectedPermissions: _selectedPermissions,
              onConfirm: (values) {
                setState(() {
                  print("Selected permission: $_selectedPermissions");
                  _selectedPermissions = values.cast<String>();
                });
              },
            ),

            const SizedBox(height: 40),
            AppConstants.fullWidthButton(
              text: "Submit",
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
