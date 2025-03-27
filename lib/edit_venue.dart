import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Basic design tokens
class Design {
  static const Color white = Colors.white;
  static const Color darkPink = Color(0xFFD81B60);
  static const Color lightGrey = Colors.grey;
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color primaryColorOrange = Colors.orange;
  static const double font15 = 15;
  static const double font17 = 17;
  static const double font20 = 20;
}

// Your server constants
class Server {
  static const String updateVenue = 'http://165.232.152.77/mobi/api/vendor/venues';
}

class EditVenueScreen extends StatefulWidget {
  final Map<String, dynamic> venueData; // The existing venue info
  final String categoryId;              // Category ID for the venue

  const EditVenueScreen({
    Key? key,
    required this.venueData,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  late TextEditingController _nameController;
  late TextEditingController _suburbController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _noticeController;
  late TextEditingController _featherPointsController;
  late TextEditingController _venuePointsController;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  List<int> selectedTagIds = [];
  List<int> selectedAmenityIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    try {
      _nameController = TextEditingController(text: widget.venueData['name']?.toString() ?? '');
      _suburbController = TextEditingController(text: widget.venueData['suburb']?.toString() ?? '');
      _descriptionController = TextEditingController(text: widget.venueData['description']?.toString() ?? '');
      _locationController = TextEditingController(text: widget.venueData['location']?.toString() ?? '');
      _latController = TextEditingController(text: widget.venueData['lat']?.toString() ?? '');
      _lonController = TextEditingController(text: widget.venueData['lon']?.toString() ?? '');
      _noticeController = TextEditingController(text: widget.venueData['notice']?.toString() ?? '');
      _featherPointsController = TextEditingController(text: widget.venueData['feather_points']?.toString() ?? '');
      _venuePointsController = TextEditingController(text: widget.venueData['venue_points']?.toString() ?? '');
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error initializing venue data: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _suburbController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _noticeController.dispose();
    _featherPointsController.dispose();
    _venuePointsController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token') ?? '';
    } catch (e) {
      throw Exception('Failed to retrieve token: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking image from gallery: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error taking photo: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateVenue() async {
    // Basic validation
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _latController.text.isEmpty ||
        _lonController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all required fields',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validate latitude and longitude
    if (double.tryParse(_latController.text) == null || double.tryParse(_lonController.text) == null) {
      Fluttertoast.showToast(
        msg: 'Invalid latitude or longitude',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final venueId = widget.venueData['id']?.toString() ?? '';
      if (venueId.isEmpty) {
        throw Exception('No venue ID found');
      }

      final url = Uri.parse('${Server.updateVenue}/$venueId');
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = _nameController.text;
      request.fields['suburb'] = _suburbController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['location'] = _locationController.text;
      request.fields['lat'] = _latController.text;
      request.fields['lon'] = _lonController.text;
      request.fields['notice'] = _noticeController.text;
      request.fields['feather_points'] = _featherPointsController.text;
      request.fields['venue_points'] = _venuePointsController.text;
      request.fields['category_id'] = widget.categoryId;
      request.fields['id'] = venueId;

      for (final tagId in selectedTagIds) {
        request.fields['tag_ids[]'] = tagId.toString();
      }
      for (final amId in selectedAmenityIds) {
        request.fields['amenity_ids[]'] = amId.toString();
      }

      if (_selectedImage != null) {
        try {
          final fileStream = http.ByteStream(_selectedImage!.openRead());
          final length = await _selectedImage!.length();
          final multipartFile = http.MultipartFile(
            'images[]',
            fileStream,
            length,
            filename: _selectedImage!.name,
          );
          request.files.add(multipartFile);
        } catch (e) {
          throw Exception('Failed to process image: ${e.toString()}');
        }
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      try {
        final responseData = json.decode(responseString) as Map<String, dynamic>;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final updatedVenue = Map<String, dynamic>.from(widget.venueData)
            ..addAll({
              'name': _nameController.text,
              'suburb': _suburbController.text,
              'description': _descriptionController.text,
              'location': _locationController.text,
              'lat': _latController.text,
              'lon': _lonController.text,
              'notice': _noticeController.text,
              'feather_points': _featherPointsController.text,
              'venue_points': _venuePointsController.text,
              'category_id': widget.categoryId,
            });

          Navigator.pop(context, updatedVenue);
          Fluttertoast.showToast(
            msg: responseData['message'] ?? 'Venue updated successfully',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          final errorMsg = responseData['message'] ?? 'Failed to update venue';
          throw Exception(errorMsg);
        }
      } catch (e) {
        throw Exception('Failed to parse server response: ${e.toString()}');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error updating venue: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImageWidget = _selectedImage != null
        ? Image.file(
            File(_selectedImage!.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          )
        : const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Venue'),
        backgroundColor: Design.primaryColorOrange,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Venue ID: ${widget.venueData['id']}',
                //   style: const TextStyle(
                //     fontSize: Design.font15,
                //     color: Design.lightGrey,
                //   ),
                // ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Venue Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _suburbController,
                  decoration: const InputDecoration(
                    labelText: 'Suburb',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _lonController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noticeController,
                  decoration: const InputDecoration(
                    labelText: 'Notice',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _featherPointsController,
                        decoration: const InputDecoration(
                          labelText: 'Feather Points',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _venuePointsController,
                        decoration: const InputDecoration(
                          labelText: 'Venue Points',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _showImagePickerSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Design.primaryColorOrange,
                      ),
                      child: const Text("Pick Image"),
                    ),
                    const SizedBox(width: 16),
                    selectedImageWidget,
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateVenue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Design.primaryColorOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: Design.font17),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}