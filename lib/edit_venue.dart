import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flock/location.dart';
import 'package:flock/venue.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock/constants.dart'; // Assumed to contain Design, Server, etc.
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditVenueScreen extends StatefulWidget {
  final Map<String, dynamic> venueData;
  final String categoryId;

  const EditVenueScreen({
    Key? key,
    required this.venueData,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _suburbController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _noticeController;
  late TextEditingController _featherPointsController;
  late TextEditingController _venuePointsController;

  // Dropdown data lists
  List<dynamic> _allCategories = [];
  List<dynamic> _allTags = [];
  List<dynamic> _allAmenities = [];
  List<String> _existingImageUrls = [];

  // Selected values
  String? _selectedCategoryId;
  List<int> _selectedTagIds = [];
  List<int> _selectedAmenityIds = [];

  // For tags and amenities search
  String _tagSearchText = '';
  String _amenitySearchText = '';

  // Image picker and selected images list
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  bool _isLoading = false;

  // Dropdown toggle flag
  bool _showVenueDropdown = false;
  // edit dietary tags
  List<dynamic> _allDietaryTags = [];
  List<int> _selectedDietaryTagIds = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing venueData
    _nameController = TextEditingController(
      text: widget.venueData['name']?.toString() ?? '',
    );
    _suburbController = TextEditingController(
      text: widget.venueData['suburb']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.venueData['description']?.toString() ?? '',
    );
    _locationController = TextEditingController(
      text: widget.venueData['location']?.toString() ?? '',
    );
    _latController = TextEditingController(
      text: widget.venueData['lat']?.toString() ?? '',
    );
    _lonController = TextEditingController(
      text: widget.venueData['lon']?.toString() ?? '',
    );
    _noticeController = TextEditingController(
      text: widget.venueData['notice']?.toString() ?? '',
    );
    _featherPointsController = TextEditingController(
      text: widget.venueData['feather_points']?.toString() ?? '',
    );
    _venuePointsController = TextEditingController(
      text: widget.venueData['venue_points']?.toString() ?? '',
    );

    // Set selected category
    _selectedCategoryId =
        widget.venueData['category_id']?.toString() ?? widget.categoryId;

    // Pre-select tags if available
    if (widget.venueData['tags'] != null) {
      _selectedTagIds =
          (widget.venueData['tags'] as List)
              .map((tag) => tag['id'] as int)
              .toList();
    }

    // Pre-select amenities if available
    if (widget.venueData['amenities'] != null) {
      _selectedAmenityIds =
          (widget.venueData['amenities'] as List)
              .map((am) => am['id'] as int)
              .toList();
    }
    // pre-select dietary
    if (widget.venueData['dietary_tags'] != null) {
      _selectedDietaryTagIds =
          (widget.venueData['dietary_tags'] as List)
              .map((tag) => tag['id'] as int)
              .toList();
    }

    // Fetch dropdown data
    _fetchCategories();
    _fetchTags();
    _fetchAmenities();
    _fetchDietaryTags();

    if (widget.venueData['images'] != null) {
      _existingImageUrls =
          (widget.venueData['images'] as List)
              .map((img) => img['image'].toString())
              .toList();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(Server.categoryList),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allCategories = data['data'] ?? data['categories'] ?? [];
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to fetch categories');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching categories: $e');
    }
  }

  // method to fetch dietary
  Future<void> _fetchDietaryTags() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
          "https://api.getflock.io/api/vendor/dietary-tags",
        ), // Replace with your actual endpoint URL
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allDietaryTags =
              data['data'] ?? []; // Adjust according to your response structure
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to fetch dietary tags');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching dietary tags: $e');
    }
  }

  Future<void> _fetchTags() async {
    try {
      final token = await _getToken();
      const tagsUrl = 'https://api.getflock.io/api/vendor/tags';
      final response = await http.get(
        Uri.parse(tagsUrl),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allTags = data['data'] ?? data['tags'] ?? [];
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to fetch tags');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching tags: $e');
    }
  }

  Future<void> _fetchAmenities() async {
    try {
      final token = await _getToken();
      const amenitiesUrl = 'https://api.getflock.io/api/vendor/amenities';
      final response = await http.get(
        Uri.parse(amenitiesUrl),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allAmenities = data['data'] ?? data['amenities'] ?? [];
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to fetch amenities');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching amenities: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
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

  // Updated: Pick multiple images from gallery and add to _selectedImages
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error picking images: $e');
    }
  }

  // Updated: Pick a single image from camera and add to _selectedImages
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error taking photo: $e');
    }
  }

  // Updated: Show image picker sheet (gallery & camera)
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

  void _openImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
      ),
    );
  }

  void _openLocalImageViewer(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(child: Image.file(imageFile)),
              ),
            ),
      ),
    );
  }

  Widget _buildSelectedImages() {
    List<Widget> imageWidgets = [];

    // Existing images
    // Existing images portion in _buildSelectedImages()
    for (int i = 0; i < _existingImageUrls.length; i++) {
      final String imageUrl = _existingImageUrls[i];
      imageWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openImageViewer(imageUrl),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Remove the image URL from the list so it's not sent to the backend.
                      _existingImageUrls.remove(imageUrl);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 130, 16, 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // New images picked by user
    for (int i = 0; i < _selectedImages.length; i++) {
      // XFile xfile = _selectedImages[i];
      final XFile currentFile = _selectedImages[i]; // capture by value
      File imageFile = File(currentFile.path);

      imageWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openLocalImageViewer(imageFile),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      imageFile,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.remove(currentFile);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 130, 16, 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imageWidgets.isEmpty) return const SizedBox();

    return SizedBox(
      height: 80,
      child: ListView(scrollDirection: Axis.horizontal, children: imageWidgets),
    );
  }

  /// Custom Category Dropdown Widget
  Widget _buildCategoryDropdown() {
    final selectedCategory = _allCategories.firstWhere(
      (cat) => cat['id'].toString() == _selectedCategoryId,
      orElse: () => {'name': 'Select Category'},
    );
    final selectedCategoryName = selectedCategory['name'].toString();

    return InkWell(
      onTap: _showCategorySelectionDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Design.primaryColorOrange),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Design.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Design.primaryColorOrange,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
          // You may adjust focusedBorder properties as needed.
        ),
        child: Text(
          selectedCategoryName,
          style: TextStyle(color: Design.black),
        ),
      ),
    );
  }

  /// Dialog to select a category with search functionality.
  void _showCategorySelectionDialog() {
    String localSearchText = '';
    List filteredCategories = _allCategories;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                "Select Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 220,
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Search Categories',
                        labelStyle: const TextStyle(fontSize: 14),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Design.primaryColorOrange,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Design.primaryColorOrange,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          localSearchText = value;
                          filteredCategories =
                              _allCategories
                                  .where(
                                    (cat) => cat['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                  )
                                  .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final catId = category['id'].toString();
                          final catName = category['name'].toString();
                          final isSelected = _selectedCategoryId == catId;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = catId;
                              });
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              color:
                                  isSelected
                                      ? Design.primaryColorOrange.withOpacity(
                                        0.1,
                                      )
                                      : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      color: Design.primaryColorOrange,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTagsDropdown() {
    final selectedTagNames =
        _allTags
            .where((tag) => _selectedTagIds.contains(tag['id']))
            .map((tag) => tag['name'].toString())
            .toList();

    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            String localSearchText = _tagSearchText;
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                final filteredTags =
                    _allTags.where((tag) {
                      final tagName =
                          tag['name']?.toString().toLowerCase() ?? '';
                      return tagName.contains(localSearchText.toLowerCase());
                    }).toList();
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text(
                    "Select Tags",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: Column(
                      children: [
                        TextField(
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Search Tags',
                            labelStyle: const TextStyle(fontSize: 14),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Design.primaryColorOrange,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Design.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Design.primaryColorOrange,
                                width: 2.0,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2.0,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setStateDialog(() {
                              localSearchText = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = filteredTags[index];
                              final tagId = tag['id'] as int;
                              final tagName = tag['name'].toString();
                              final isSelected = _selectedTagIds.contains(
                                tagId,
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1,
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.75,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: Design.primaryColorOrange,
                                        visualDensity: const VisualDensity(
                                          vertical: -4,
                                          horizontal: -4,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (bool? value) {
                                          setStateDialog(() {
                                            setState(() {
                                              if (value == true) {
                                                _selectedTagIds.add(tagId);
                                              } else {
                                                _selectedTagIds.remove(tagId);
                                              }
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tagName,
                                        style: const TextStyle(fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tagSearchText = localSearchText;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Tags",
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Design.primaryColorOrange),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Design.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Design.primaryColorOrange,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
        child: Text(
          selectedTagNames.isNotEmpty
              ? selectedTagNames.join(", ")
              : "Select Tags",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
  // dietary dropdown

  // build dietary build
  Widget _buildDietaryTagsDropdown() {
    // Convert currently selected IDs to their names (if any)
    final selectedDietaryNames =
        _allDietaryTags
            .where((tag) => _selectedDietaryTagIds.contains(tag['id']))
            .map((tag) => tag['name'].toString())
            .toList();

    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            String localSearchText = '';
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                final filteredDietary =
                    _allDietaryTags.where((tag) {
                      final tagName =
                          tag['name']?.toString().toLowerCase() ?? '';
                      return tagName.contains(localSearchText.toLowerCase());
                    }).toList();
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text(
                    "Select Dietary Tags",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 150,
                    child: Column(
                      children: [
                        TextField(
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Search Dietary Tags',
                            labelStyle: const TextStyle(fontSize: 14),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Design.primaryColorOrange,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Design.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Design.primaryColorOrange,
                                width: 2.0,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setStateDialog(() {
                              localSearchText = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredDietary.length,
                            itemBuilder: (context, index) {
                              final tag = filteredDietary[index];
                              final tagId = tag['id'] as int;
                              final tagName = tag['name'].toString();
                              final isSelected = _selectedDietaryTagIds
                                  .contains(tagId);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1,
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.75,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: Design.primaryColorOrange,
                                        visualDensity: const VisualDensity(
                                          vertical: -4,
                                          horizontal: -4,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (bool? value) {
                                          setStateDialog(() {
                                            setState(() {
                                              if (value == true) {
                                                _selectedDietaryTagIds.add(
                                                  tagId,
                                                );
                                              } else {
                                                _selectedDietaryTagIds.remove(
                                                  tagId,
                                                );
                                              }
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tagName,
                                        style: const TextStyle(fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Done"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Dietary Tags",
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Design.primaryColorOrange),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Design.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Design.primaryColorOrange,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
        child: Text(
          selectedDietaryNames.isNotEmpty
              ? selectedDietaryNames.join(", ")
              : "Select Dietary Tags",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  /// Updated Amenities Dropdown Widget (using a similar style as Tags)
  Widget _buildAmenitiesDropdown() {
    final selectedAmenityNames =
        _allAmenities
            .where((am) => _selectedAmenityIds.contains(am['id']))
            .map((am) => am['name'].toString())
            .toList();

    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            String localSearchText = _amenitySearchText;
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                final filteredAmenities =
                    _allAmenities.where((am) {
                      final name = am['name']?.toString().toLowerCase() ?? '';
                      return name.contains(localSearchText.toLowerCase());
                    }).toList();
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text(
                    "Select Amenities",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: Column(
                      children: [
                        TextField(
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Search Amenities',
                            labelStyle: const TextStyle(fontSize: 14),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Design.primaryColorOrange,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Design.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Design.primaryColorOrange,
                                width: 2.0,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2.0,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setStateDialog(() {
                              localSearchText = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredAmenities.length,
                            itemBuilder: (context, index) {
                              final amenity = filteredAmenities[index];
                              final amenityId = amenity['id'] as int;
                              final amenityName = amenity['name'].toString();
                              final isSelected = _selectedAmenityIds.contains(
                                amenityId,
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1,
                                ),
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.75,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: Design.primaryColorOrange,
                                        visualDensity: const VisualDensity(
                                          vertical: -4,
                                          horizontal: -4,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (bool? value) {
                                          setStateDialog(() {
                                            setState(() {
                                              if (value == true) {
                                                _selectedAmenityIds.add(
                                                  amenityId,
                                                );
                                              } else {
                                                _selectedAmenityIds.remove(
                                                  amenityId,
                                                );
                                              }
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        amenityName,
                                        style: const TextStyle(fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _amenitySearchText = localSearchText;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Amenities",
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Design.primaryColorOrange),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Design.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Design.primaryColorOrange,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
        child: Text(
          selectedAmenityNames.isNotEmpty
              ? selectedAmenityNames.join(", ")
              : "Select Amenities",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  // (Optional) Use _showAmenitiesSelectionDialog if you want the grid style.
  // Currently, _buildAmenitiesDropdown uses a list style similar to tags.
  void _showAmenitiesSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Amenities'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _allAmenities.length,
                  itemBuilder: (context, index) {
                    final amenity = _allAmenities[index];
                    final amenityId = amenity['id'];
                    final amenityName = amenity['name'].toString();
                    final isSelected = _selectedAmenityIds.contains(amenityId);
                    return InkWell(
                      onTap: () {
                        setStateDialog(() {
                          setState(() {
                            if (isSelected) {
                              _selectedAmenityIds.remove(amenityId);
                            } else {
                              _selectedAmenityIds.add(amenityId);
                            }
                          });
                        });
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        color:
                            isSelected
                                ? Design.primaryColorOrange.withOpacity(0.2)
                                : Colors.white,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              amenityName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isSelected
                                        ? Design.primaryColorOrange
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // In edit_venue.dart, replace the _updateVenue method with this:
  Future<void> _updateVenue() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _latController.text.isEmpty ||
        _lonController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all required fields',
        backgroundColor: Colors.red,
      );
      return;
    }
    if (double.tryParse(_latController.text) == null ||
        double.tryParse(_lonController.text) == null) {
      Fluttertoast.showToast(
        msg: 'Invalid latitude or longitude',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final venueId = widget.venueData['id']?.toString() ?? '';
      if (venueId.isEmpty) throw Exception('No venue ID found');

      final url = Uri.parse('${Server.updateVenue}/$venueId');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Basic fields
      request.fields['name'] = _nameController.text;
      request.fields['suburb'] = _suburbController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['location'] = _locationController.text;
      request.fields['lat'] = _latController.text;
      request.fields['lon'] = _lonController.text;
      request.fields['notice'] = _noticeController.text;
      request.fields['venue_points'] = _venuePointsController.text;
      request.fields['category_id'] = _selectedCategoryId ?? '';
      request.fields['id'] = venueId;

      // Add selected tags, amenities, and dietary tags
      request.fields['tag_ids'] = jsonEncode(_selectedTagIds);
      request.fields['amenity_ids'] = jsonEncode(_selectedAmenityIds);
      request.fields['dietary_ids'] = jsonEncode(_selectedDietaryTagIds);

      // Attach old images
      for (int i = 0; i < _existingImageUrls.length; i++) {
        request.fields['old_images[$i]'] = _existingImageUrls[i];
      }

      // Attach new images
      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          final stream = http.ByteStream(image.openRead());
          final length = await image.length();
          debugPrint("Image ${image.name} size:$length bytes");
          final multipartFile = http.MultipartFile(
            'images[]',
            stream,
            length,
            filename: image.name,
          );
          request.files.add(multipartFile);
        }
      }

      final response = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          // Optionally you can show a message or cancel the request here
          throw TimeoutException("Image upload timed out. Please try again.");
        },
      );

      final respStr = await response.stream.bytesToString();
      final respData = json.decode(respStr);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Extract new images from response, assuming backend returns updated venue data
        List<String> newImageUrls = [];
        if (respData['data'] != null && respData['data']['images'] != null) {
          newImageUrls =
              (respData['data']['images'] as List)
                  .map((img) => img['image'].toString())
                  .toList();
        }

        // Update local state with new image URLs
        setState(() {
          _existingImageUrls = newImageUrls;
          _selectedImages
              .clear(); // Clear newly uploaded images since they're now in _existingImageUrls
        });

        // Create updated venue data map
        final updatedVenue = {
          'id': venueId,
          'name': _nameController.text,
          'suburb': _suburbController.text,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'lat': _latController.text,
          'lon': _lonController.text,
          'notice': _noticeController.text,
          'venue_points': _venuePointsController.text,
          'category_id': _selectedCategoryId,
          'tags':
              _allTags
                  .where((tag) => _selectedTagIds.contains(tag['id']))
                  .map((tag) => {'id': tag['id'], 'name': tag['name']})
                  .toList(),
          'amenities':
              _allAmenities
                  .where((am) => _selectedAmenityIds.contains(am['id']))
                  .map((am) => {'id': am['id'], 'name': am['name']})
                  .toList(),
          'dietary_tags':
              _allDietaryTags
                  .where((tag) => _selectedDietaryTagIds.contains(tag['id']))
                  .map((tag) => {'id': tag['id'], 'name': tag['name']})
                  .toList(),
          'images': newImageUrls.map((url) => {'image': url}).toList(),
          'approval': widget.venueData['approval'],
          'posted_at': widget.venueData['posted_at'],
        };

        Fluttertoast.showToast(
          msg: respData['message'] ?? 'Venue updated successfully',
          backgroundColor: Colors.green,
        );

        // Pop the screen and return the updated venue data
        Navigator.pop(context, updatedVenue);
      } else {
        final errorMsg = respData['message'] ?? 'Failed to update venue';
        throw Exception(errorMsg);
      }
    } on TimeoutException catch (e) {
      // Handle timeout: Show feedback or retry mechanism
      Fluttertoast.showToast(
        msg: 'Error updating venue: ${e.message}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error updating venue: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImagesWidget = _buildSelectedImages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Venue',
          style: TextStyle(
            color: Colors.black,
          ), // Optional: make title text visible on white background
        ),
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(
              8.0,
            ), // Optional padding for better tap area
            child: Image.asset(
              'assets/back_updated.png',
              height: 40,
              width: 34,
              fit: BoxFit.contain,
            ),
          ),
        ),
        elevation: 0, // Optional: remove AppBar shadow
      ),

      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Venue Name',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Custom Category Dropdown
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  // Suburb
                  TextField(
                    controller: _suburbController,
                    decoration: InputDecoration(
                      labelText: 'Suburb',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),
                  // Location (read-only with onTap for LocationPicker)
                  TextField(
                    controller: _locationController,
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => LocationPicker(
                                initialPosition:
                                    _latController.text.isNotEmpty &&
                                            _lonController.text.isNotEmpty
                                        ? LatLng(
                                          double.parse(_latController.text),
                                          double.parse(_lonController.text),
                                        )
                                        : null,
                              ),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          _locationController.text = result['address'] ?? '';
                          _latController.text = result['lat']?.toString() ?? '';
                          _lonController.text = result['lng']?.toString() ?? '';
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Latitude and Longitude Row
                  //               Row(
                  //                 children: [
                  //                   Expanded(
                  //                     child: TextField(
                  //                       controller: _latController,
                  //                       decoration: InputDecoration(
                  //                         labelText: 'Latitude',
                  //                         border: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange),
                  // ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.black),
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange, width: 2.0),
                  // ),
                  // errorBorder: OutlineInputBorder(
                  //   borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  // ),

                  //                       ),
                  //                       keyboardType: TextInputType.number,
                  //                     ),
                  //                   ),
                  //                   const SizedBox(width: 16),
                  //                   Expanded(
                  //                     child: TextField(
                  //                       controller: _lonController,
                  //                       decoration: InputDecoration(
                  //                         labelText: 'Longitude',
                  //                          border: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange),
                  // ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.black),
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange, width: 2.0),
                  // ),
                  // errorBorder: OutlineInputBorder(
                  //   borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  // ),

                  //                       ),
                  //                       keyboardType: TextInputType.number,
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //               const SizedBox(height: 16),
                  // Notice
                  TextField(
                    controller: _noticeController,
                    decoration: InputDecoration(
                      labelText: 'Notice',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Design.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Feather Points and Venue Points Row
                  //               Row(
                  //                 children: [
                  //                   Expanded(
                  //                     child: TextField(
                  //                       controller: _featherPointsController,
                  //                       decoration: InputDecoration(
                  //                         labelText: 'Feather Points',
                  //                         border: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange),
                  // ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.black),
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange, width: 2.0),
                  // ),
                  // errorBorder: OutlineInputBorder(
                  //   borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  // ),
                  //                       ),
                  //                       keyboardType: TextInputType.number,
                  //                     ),
                  //                   ),
                  //                   const SizedBox(width: 16),
                  //                   Expanded(
                  //                     child: TextField(
                  //                       controller: _venuePointsController,
                  //                       decoration: InputDecoration(
                  //                         labelText: 'Venue Points',
                  //                         border: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange),
                  // ),
                  // enabledBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.black),
                  // ),
                  // focusedBorder: OutlineInputBorder(
                  //   borderSide: BorderSide(color: Design.primaryColorOrange, width: 2.0),
                  // ),
                  // errorBorder: OutlineInputBorder(
                  //   borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  // ),
                  //                       ),
                  //                       keyboardType: TextInputType.number,
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  // const SizedBox(height: 16),
                  // Tags Dropdown
                  _buildTagsDropdown(),
                  const SizedBox(height: 16),
                  // Amenities Dropdown
                  _buildAmenitiesDropdown(),
                  const SizedBox(height: 16),
                  _buildDietaryTagsDropdown(),
                  const SizedBox(height: 20),

                  // Image Picker Row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔝 Label with camera icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: _showImagePickerSheet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Design.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                                  EdgeInsets
                                      .zero, // Remove inner padding to align icon properly
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 2,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      // color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(
                                            0.4,
                                          ), // 👈 Grey shadow
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Add Image(s)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Image.asset(
                                          'assets/camera.png',
                                          height: 30,
                                          width: 36,
                                          fit: BoxFit.contain,
                                          color: const Color.fromRGBO(
                                            255,
                                            130,
                                            16,
                                            1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),
                          // 🖼 Image preview list
                          Expanded(child: _buildSelectedImages()),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateVenue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Design.primaryColorOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Design.font17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Stack(
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
            ),
        ],
      ),
    );
  }
}
