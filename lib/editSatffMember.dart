import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

// import your custom constants or fields
import 'constants.dart';

class EditStaffMemberScreen extends StatefulWidget {
  final String staffId; // The ID of the staff member to edit

  const EditStaffMemberScreen({Key? key, required this.staffId})
    : super(key: key);

  @override
  State<EditStaffMemberScreen> createState() => _EditStaffMemberScreenState();
}

class _EditStaffMemberScreenState extends State<EditStaffMemberScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> _selectedVenues = [];
  List<String> _selectedPermissions = [];
  List<dynamic> _venueList = [];
  List<dynamic> _permissionList = [];
  String? _currentImageUrl;

  File? _pickedImage;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStaffData();
  }

  Future<void> _fetchStaffData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = Dio();

    try {
      // 1) Fetch existing staff data
      final response = await dio.get(
        'https://api.getflock.io/api/vendor/teams/${widget.staffId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        print("Staff Data: $data");

        _firstNameController.text = data["first_name"] ?? '';
        _lastNameController.text = data["last_name"] ?? '';
        _emailController.text = data["email"] ?? '';
        _phoneController.text = data["contact"] ?? '';
        _currentImageUrl =
            data["image"]; // or data["profile_image"] depending on API response

        // 🔹 Convert venue IDs and permission IDs to Strings
        _selectedVenues =
            (data["assigned_venues"] as List<dynamic>?)
                ?.map(
                  (venue) => venue["id"].toString(),
                ) // Extract only the ID as a string
                .toList() ??
            [];

        _selectedPermissions =
            (data["permissions"] as List<dynamic>?)
                ?.map(
                  (permission) => permission["id"].toString(),
                ) // Extract only the ID as a string
                .toList() ??
            [];
        print("Selected Venues: $_selectedVenues");
        print("Selected Permissions: $_selectedPermissions");
      } else {
        _showError("Failed to load staff data. Status: ${response.statusCode}");
      }

      // 2) Fetch Venues
      final venueResponse = await dio.get(
        'https://api.getflock.io/api/vendor/venues',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (venueResponse.statusCode == 200) {
        _venueList = venueResponse.data['data'] ?? [];
      }

      // 3) Fetch Permissions
      final permissionResponse = await dio.get(
        'https://api.getflock.io/api/vendor/permissions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (permissionResponse.statusCode == 200) {
        _permissionList = permissionResponse.data['data'] ?? [];
      }

      // 🔹 Ensure UI updates after data fetch
      setState(() {});
    } catch (e) {
      _showError("Error fetching staff data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _pickedImage = File(pickedFile.path);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _pickedImage = File(pickedFile.path);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _submitForm() async {
    // Check minimal fields
    if (_firstNameController.text.isEmpty || _emailController.text.isEmpty) {
      _showError("Please fill in the required fields.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final dio = Dio();

      Map<String, dynamic> formDataMap = {
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "email": _emailController.text,
        "contact": _phoneController.text,
      };

      // Only update password if user entered one
      if (_passwordController.text.isNotEmpty) {
        formDataMap["password"] = _passwordController.text;
      }

      for (var i = 0; i < _selectedPermissions.length; i++) {
        formDataMap["permission_ids[$i]"] = _selectedPermissions[i];
      }

      for (var i = 0; i < _selectedVenues.length; i++) {
        formDataMap["venue_ids[$i]"] = _selectedVenues[i];
      }

      // If an image is picked, attach it
      if (_pickedImage != null) {
        formDataMap["image"] = await MultipartFile.fromFile(
          _pickedImage!.path,
          filename: p.basename(_pickedImage!.path),
        );
      }

      FormData formData = FormData.fromMap(formDataMap);

      final response = await dio.post(
        'https://api.getflock.io/api/vendor/teams/${widget.staffId}',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member updated successfully!")),
        );
        Navigator.pop(context, true); // return 'true' to refresh list
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown error';
        final errors =
            response.data['errors']?.toString() ?? 'No details provided';
        _showError('Failed to update member: $errorMessage\nDetails: $errors');
      }
    } catch (e) {
      _showError('Error updating member: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppConstants.customAppBar(
        backgroundColor: Colors.white,
        context: context,
        title: 'Edit Member',
      ),
      body:
          _isLoading
              ? Stack(
                children: [
                  // Semi-transparent dark overlay
                  Container(
                    color: Colors.black.withOpacity(0.14), // Dark overlay
                  ),

                  // Your original container with white tint and loader
                  Container(
                    color: Colors.white10,
                    child: Center(
                      child: Image.asset(
                        'assets/Bird_Full_Eye_Blinking.gif',
                        width: 100, // Adjust size as needed
                        height: 100,
                      ),
                    ),
                  ),
                ],
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile image
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                _pickedImage != null
                                    ? FileImage(_pickedImage!)
                                    : (_currentImageUrl != null
                                        ? NetworkImage(_currentImageUrl!)
                                            as ImageProvider
                                        : null),
                            child:
                                (_pickedImage == null &&
                                        _currentImageUrl == null)
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),

                          Positioned(
                            bottom: -4,
                            right: -7,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color.fromRGBO(
                                255,
                                130,
                                16,
                                1,
                              ),
                              child: IconButton(
                                icon: const Icon(
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
                    const SizedBox(height: 30),
                    // First + Last Name
                    Row(
                      children: [
                        Expanded(
                          child: AppConstants.firstNameField(
                            controller: _firstNameController,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppConstants.lastNameField(
                            controller: _lastNameController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Email
                    AppConstants.emailField(controller: _emailController),
                    const SizedBox(height: 15),
                    // Phone
                    AppConstants.phoneField(controller: _phoneController),
                    const SizedBox(height: 15),
                    // Password (only if user wants to change it)
                    AppConstants.passwordField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      toggleObscure: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Venues
                    AppConstants.assignVenuesDropdown(
                      venueList: _venueList,
                      selectedVenues: _selectedVenues,
                      onConfirm: (values) {
                        setState(() {
                          _selectedVenues = values.cast<String>();
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Permissions
                    AppConstants.assignPermissionsDropdown(
                      permissionList: _permissionList,
                      selectedPermissions: _selectedPermissions,
                      onConfirm: (values) {
                        setState(() {
                          _selectedPermissions = values.cast<String>();
                        });
                      },
                      context: context,
                    ),
                    const SizedBox(height: 40),

                    // Submit
                    AppConstants.fullWidthButton(
                      text: "Update",
                      onPressed: _submitForm,
                    ),
                  ],
                ),
              ),
    );
  }
}
