import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock/constants.dart';
import 'package:flock/app_colors.dart';

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

  // Validation error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _venuesError;

  @override
  void initState() {
    super.initState();
    if (widget.existingMember != null) {
      _firstNameController.text = widget.existingMember!['firstName'] ?? '';
      _lastNameController.text = widget.existingMember!['lastName'] ?? '';
      _emailController.text = widget.existingMember!['email'] ?? '';
      _phoneController.text = widget.existingMember!['phone'] ?? '';
      _selectedVenues = widget.existingMember!['venue']?.split(',') ?? [];
      _selectedPermissions = widget.existingMember!['permission']?.split(',') ?? [];
      if (!_selectedPermissions.contains('2')) {
        _selectedPermissions.add('2');
      }
    } else {
      _selectedPermissions = ['2'];
    }
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = Dio();

    try {
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
        setState(() {
          _venueList = venueResponse.data['data'] ?? [];
        });
      }
    } catch (e) {
      _showError('Error fetching venues');
    }

    try {
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
        setState(() {
          _permissionList = permissionResponse.data['data'] ?? [];
          if (_permissionList.any((p) => p['id'].toString() == '2') && !_selectedPermissions.contains('2')) {
            _selectedPermissions.add('2');
          }
        });
      }
    } catch (e) {
      _showError('Error fetching permissions');
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
    // Reset error messages
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _venuesError = null;
    });

    // Validate required fields
    bool hasError = false;
    if (_firstNameController.text.isEmpty) {
      setState(() {
        _firstNameError = 'First name is required';
      });
      hasError = true;
    }
    if (_lastNameController.text.isEmpty) {
      setState() {
        _lastNameError = 'Last name is required';
      };
      hasError = true;
    }
    if (_phoneController.text.isEmpty) {
      setState(() {
        _phoneError = 'Phone number is required';
      });
      hasError = true;
    }
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Incorrect email format';
      });
      hasError = true;
    }
    if (_passwordController.text.isEmpty && widget.existingMember == null) {
      setState(() {
        _passwordError = 'Password is required';
      });
      hasError = true;
    }
    if (_selectedVenues.isEmpty) {
      setState(() {
        _venuesError = 'Please assign at least one venue';
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    // Ensure id=2 is always included
    if (!_selectedPermissions.contains('2')) {
      _selectedPermissions.add('2');
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
        if (_passwordController.text.isNotEmpty) "password": _passwordController.text,
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
      final String url = widget.existingMember != null && widget.existingMember!['id'] != null
          ? "https://api.getflock.io/api/vendor/teams/${widget.existingMember!['id']}"
          : "https://api.getflock.io/api/vendor/teams";

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
              backgroundColor: Theme.of(context).colorScheme.primary,
              content: Text(
                widget.existingMember != null ? "Member updated successfully!" : "Member added successfully!",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown error';
        final errors = response.data['errors']?.toString() ?? 'No details provided';
        _showError('Failed to save member, Please Check fields');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error saving member');
    }
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppConstants.customAppBar(
        context: context,
        title: 'Add Member',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                        child: _pickedImage == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).iconTheme.color,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: -10,
                        right: -10,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: Theme.of(context).colorScheme.onPrimary,
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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppConstants.firstNameField(
                            controller: _firstNameController,
                          ),
                          if (_firstNameError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
                              child: Text(
                                _firstNameError!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppConstants.lastNameField(
                            controller: _lastNameController,
                          ),
                          if (_lastNameError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 12),
                              child: Text(
                                _lastNameError!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppConstants.emailField(controller: _emailController),
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          _emailError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppConstants.phoneField(controller: _phoneController),
                    if (_phoneError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          _phoneError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppConstants.passwordField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      toggleObscure: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          _passwordError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppConstants.assignVenuesDropdown(
                      venueList: _venueList,
                      selectedVenues: _selectedVenues,
                      onConfirm: (values) {
                        setState(() {
                          _selectedVenues = values.cast<String>();
                          _venuesError = null;
                        });
                      },
                    ),
                    if (_venuesError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(
                          _venuesError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                AppConstants.assignPermissionsDropdown(
                  permissionList: _permissionList,
                  selectedPermissions: _selectedPermissions,
                  mandatoryPermissionId: '2',
                  onConfirm: (values) {
                    setState(() {
                      _selectedPermissions = values.cast<String>();
                      if (!_selectedPermissions.contains('2')) {
                        _selectedPermissions.add('2');
                      }
                    });
                  },
                  context: context,
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : AppConstants.fullWidthButton(
                        text: "Submit",
                        onPressed: _submitForm,
                      ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}