import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AddMemberScreen extends StatefulWidget {
  final Map<String, String>? existingMember;
  const AddMemberScreen({Key? key, this.existingMember}) : super(key: key);

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  bool _obscurePassword = true;
  bool _obscureText = true;
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
      _selectedPermissions = widget.existingMember!['permission']?.split(',') ?? [];
    }
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final dio = Dio();

    try {
      final venueResponse = await dio.get(
        'http://165.232.152.77/mobi/api/vendor/venues',
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
        'http://165.232.152.77/mobi/api/vendor/permissions',
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
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
        if (_passwordController.text.isNotEmpty) "password": _passwordController.text,
        "contact": _phoneController.text,
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
          ? "http://165.232.152.77/mobi/api/vendor/teams/${widget.existingMember!['id']}"
          : "http://165.232.152.77/mobi/api/vendor/teams";

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
            SnackBar(content: Text(widget.existingMember != null ? "Member updated successfully!" : "Member added successfully!")),
          );
          Navigator.pop(context, true);
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown error';
        final errors = response.data['errors']?.toString() ?? 'No details provided';
        _showError('Failed to save member: $errorMessage\nDetails: $errors');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error saving member: $e');
    }
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Member',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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
                    backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                    child: _pickedImage == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.orange,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: _pickImage,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
     SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    hintText: 'First Name',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _lastNameController, // Fixed: was using _firstNameController
                  decoration: const InputDecoration(
                    hintText: 'Last Name',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Enter email address',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              hintText: 'Enter phone number',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: 'Enter password',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: MultiSelectDialogField(
            items: _venueList.map((venue) {
              return MultiSelectItem<String>(venue["id"].toString(), venue["name"].toString());
            }).toList(),
            initialValue: _selectedVenues,
            onConfirm: (values) {
              setState(() {
                _selectedVenues = values.cast<String>();
              });
            },
            chipDisplay: MultiSelectChipDisplay(
              chipColor: Colors.orange,
              textStyle: TextStyle(color: Colors.white),
            ),
            buttonText: Text(
              "Assign venues",
              style: TextStyle(color: Colors.grey),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
        SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: MultiSelectDialogField(
            items: _permissionList.map((permission) {
              return MultiSelectItem<String>(permission["id"].toString(), permission["name"].toString());
            }).toList(),
            initialValue: _selectedPermissions,
            onConfirm: (values) {
              setState(() {
                _selectedPermissions = values.cast<String>();
              });
            },
            chipDisplay: MultiSelectChipDisplay(
              chipColor: Colors.orange,
              textStyle: TextStyle(color: Colors.white),
            ),
            buttonText: Text(
              "Assign permissions",
              style: TextStyle(color: Colors.grey),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            buttonIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
            // Container(
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.grey),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: MultiSelectDialogField(
            //     items: _permissionList.map((permission) {
            //       return MultiSelectItem<String>(permission["id"].toString(), permission["name"].toString());
            //     }).toList(),
            //     initialValue: _selectedPermissions,
            //     onConfirm: (values) {
            //       setState(() {
            //         _selectedPermissions = values.cast<String>();
            //       });
            //     },
            //     chipDisplay: MultiSelectChipDisplay(
            //       chipColor: Colors.orange,
            //       textStyle: TextStyle(color: Colors.white),
            //     ),
            //     buttonText: Text("Assign permissions", style: TextStyle(color: Colors.grey)),
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Submit',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}