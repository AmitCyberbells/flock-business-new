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
import 'package:flock/constants.dart'; // Assuming this contains Design, Server, etc.

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

  // Selected values
  String? _selectedCategoryId;
  List<int> _selectedTagIds = [];
  List<int> _selectedAmenityIds = [];

  // For tags and amenities search
  String _tagSearchText = '';
  String _amenitySearchText = '';

  // Image picker
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  bool _isLoading = false;

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

    // Fetch dropdown data
    _fetchCategories();
    _fetchTags();
    _fetchAmenities();
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

  Future<void> _fetchTags() async {
    try {
      final token = await _getToken();
      const tagsUrl = 'http://165.232.152.77/api/vendor/tags';
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
      const amenitiesUrl = 'http://165.232.152.77/api/vendor/amenities';
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error taking photo: $e');
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

  /// Custom Category Dropdown Widget:
  /// When tapped, this opens a dialog with a simple list of categories.
  Widget _buildCategoryDropdown() {
    // Determine the name for the currently selected category.
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
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Design.primaryColorOrange,
              width: 20.0,
            ),
          ),
        ),
        child: Text(
          selectedCategoryName,
          style: TextStyle(color: Design.black),
        ),
      ),
    );
  }

  /// The dialog opens with a list of categories.
 void _showCategorySelectionDialog() {
  String localSearchText = '';
  List filteredCategories = _allCategories;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Select Category",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
                      filteredCategories = _allCategories
                          .where((cat) => cat['name']
                              .toString()
                              .toLowerCase()
                              .contains(value.toLowerCase()))
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
                          color: isSelected
                              ? Design.primaryColorOrange.withOpacity(0.1)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
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
                                Icon(Icons.check,
                                    color: Design.primaryColorOrange, size: 18),
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
      });
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
  style: TextStyle(
    fontSize: 18, // or whatever size you want
    fontWeight: FontWeight.w600, // optional
  ),
),

                  content: SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: Column(
                      children: [
                        TextField(
                          style: const TextStyle(fontSize: 12), // Smaller text
                          decoration: InputDecoration(
                            labelText: 'Search Tags',
                            labelStyle: const TextStyle(
                              fontSize: 14,
                            ), // Smaller label
                            isDense: true, // Reduces vertical height
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 10,
                            ), // Tight padding
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
                                      scale: 0.75, // Shrinks the checkbox
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
                                    const SizedBox(
                                      width: 8,
                                    ), // Small spacing between checkbox and text
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
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Design.primaryColorOrange,
              width: 2.0,
            ),
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
// Updated Amenities Dropdown Widget
// Updated Amenities Dropdown Widget
Widget _buildAmenitiesDropdown() {
  final selectedAmenityNames = _allAmenities
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
              final filteredAmenities = _allAmenities.where((am) {
                final name = am['name']?.toString().toLowerCase() ?? '';
                return name.contains(localSearchText.toLowerCase());
              }).toList();

              return AlertDialog(
                backgroundColor: Colors.white,
                   title: const Text(
  "Select Amenities",
  style: TextStyle(
    fontSize: 18, // or whatever size you want
    fontWeight: FontWeight.w600, // optional
  ),
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
                            borderSide:
                                BorderSide(color: Design.primaryColorOrange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Design.primaryColorOrange, width: 2.0),
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
                            final isSelected =
                                _selectedAmenityIds.contains(amenityId);
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.75, // Shrink the checkbox
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
                                              _selectedAmenityIds.add(amenityId);
                                            } else {
                                              _selectedAmenityIds
                                                  .remove(amenityId);
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
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Design.primaryColorOrange, width: 2.0),
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





// Updated Amenities Selection Dialog
void _showAmenitiesSelectionDialog() {
  showDialog(
    context: context,
    barrierDismissible: true, // Allows dismissal without an explicit "OK" button
    builder: (context) {
      return AlertDialog(
        title: const Text('Select Amenities'),
        content: Container(
          width: double.maxFinite,
          height: 300, // Adjust to display 4 items at a time (2 rows in a 2-column grid)
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  childAspectRatio: 3, // Shorter card height
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
                      color: isSelected 
                          ? Design.primaryColorOrange.withOpacity(0.2)
                          : Colors.white,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            amenityName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected 
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
      request.fields['feather_points'] = _featherPointsController.text;
      request.fields['venue_points'] = _venuePointsController.text;
      request.fields['category_id'] = _selectedCategoryId ?? '';
      request.fields['id'] = venueId;

      // Add selected tags and amenities as JSON-encoded arrays
      request.fields['tag_ids'] = jsonEncode(_selectedTagIds);
      request.fields['amenity_ids'] = jsonEncode(_selectedAmenityIds);

      // Attach image if selected
      print('Debugging fields: ${request.fields}');

      if (_selectedImage != null) {
        final stream = http.ByteStream(_selectedImage!.openRead());
        final length = await _selectedImage!.length();
        final multipartFile = http.MultipartFile(
          'images[]',
          stream,
          length,
          filename: _selectedImage!.name,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final respData = json.decode(respStr);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Fluttertoast.showToast(
          msg: respData['message'] ?? 'Venue updated successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, {
          ...widget.venueData,
          'name': _nameController.text,
          'suburb': _suburbController.text,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'lat': _latController.text,
          'lon': _lonController.text,
          'notice': _noticeController.text,
          'feather_points': _featherPointsController.text,
          'venue_points': _venuePointsController.text,
          'category_id': _selectedCategoryId,
          'tags': _selectedTagIds.map((id) => {'id': id}).toList(),
          'amenities': _selectedAmenityIds.map((id) => {'id': id}).toList(),
        });
      } else {
        final errorMsg = respData['message'] ?? 'Failed to update venue';
        throw Exception(errorMsg);
      }
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
    final selectedImageWidget =
        _selectedImage != null
            ? Image.file(
              File(_selectedImage!.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            )
            : const SizedBox();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Edit Venue'),
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
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Location
                TextField(
  controller: _locationController,
  readOnly: true, // Prevent manual editing
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPicker()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _locationController.text = result['address'] ?? '';
      // You can also access lat/lng here:
      // double lat = result['lat'];
      // double lng = result['lng'];
    }
  },
  decoration: InputDecoration(
    labelText: 'Location',
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Design.primaryColorOrange),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Design.primaryColorOrange,
        width: 2.0,
      ),
    ),
  ),
),

                  const SizedBox(height: 16),
                  // Latitude and Longitude Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _latController,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
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
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _lonController,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
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
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Design.primaryColorOrange,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Feather Points and Venue Points Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _featherPointsController,
                          decoration: InputDecoration(
                            labelText: 'Feather Points',
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
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _venuePointsController,
                          decoration: InputDecoration(
                            labelText: 'Venue Points',
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
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tags Dropdown
                  _buildTagsDropdown(),
                  const SizedBox(height: 16),
                  // Amenities Dropdown
                  _buildAmenitiesDropdown(),
                  const SizedBox(height: 16),
                  // Image Picker Row
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _showImagePickerSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Design.primaryColorOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Pick Image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      selectedImageWidget,
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
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
