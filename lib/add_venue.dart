import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:http/http.dart' as http;

// Design tokens and constants
class Design {
  static const Color primaryColorOrange = Colors.orange;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color lightPurple = Color(0xFFF0F0F5);
  static const double font15 = 15;
  static const double font16 = 16;
  static const double font18 = 18;
  static const double font20 = 20;
}

// Example image references
class GlobalImages {
  static const String camera = 'assets/camera.png';
  static const String closeBtn = 'assets/closebtn.png';
  static const String dropDown = 'assets/drop_down.png';
  static const String dropUp = 'assets/drop_up.png';
  static const String requestSent = 'assets/request_sent.png';
  static const String photoGallery = 'assets/gallery.png';
  static const String openCamera = 'assets/camera.png';
}

// Server endpoints
class Server {
  static const String venues = "http://165.232.152.77/mobi/api/vendor/venues";
  static const String tags = "http://165.232.152.77/mobi/api/vendor/tags";
  static const String categoryList = "http://165.232.152.77/mobi/api/vendor/categories";
  static const String amenities = "http://165.232.152.77/mobi/api/vendor/amenities";
}

class AddEggScreen extends StatefulWidget {
  final dynamic allDetail;
  final List<dynamic>? allCategory;
  final List<dynamic>? allAmenities;

  const AddEggScreen({
    Key? key,
    this.allDetail,
    this.allCategory,
    this.allAmenities,
  }) : super(key: key);

  @override
  State<AddEggScreen> createState() => _AddEggScreenState();
}

class _AddEggScreenState extends State<AddEggScreen> {
  bool loader = false;
  bool dialogAlert = false;
  bool confirmPopup = false;
  bool confirmPaymentTerms = false;

  String name = '';
  String suburb = '';
  String location = '';
  String notice = '';
  String description = '';

  bool nameofeggStatus = false;
  String nameofegg = '';
  String catId = '';

  bool reportStatus = false;
  List<dynamic> allAmenities = [];
  List<String> arrOfAmenities = [];

  List<dynamic> allCategory = [];
  List<dynamic> tags = [];
  List<String> selectedTags = [];

  final ImagePicker _picker = ImagePicker();
  List<XFile> photos = [];

  String userId = "";
  double lat = 0.0;
  double lng = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.allCategory != null) {
      allCategory = widget.allCategory!;
    }
    if (widget.allAmenities != null) {
      allAmenities = widget.allAmenities!;
    }
    if (widget.allDetail != null) {
      populateExistingVenue(widget.allDetail);
    }
    getUserId();
    getVenueTags();
    getCategoriesAmenties();
  }

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userid') ?? "";
    });
  }

  Future<void> getVenueTags() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(Server.tags),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final tagsJson = jsonDecode(response.body);
        setState(() {
          tags = tagsJson['data']; // Access the 'data' key from API response
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load tags: ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching tags: $e");
    }
  }

  Future<void> getCategoriesAmenties() async {
    try {
      final token = await getToken();
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      final categoriesResponse = await http.get(Uri.parse(Server.categoryList), headers: headers);
      final amenitiesResponse = await http.get(Uri.parse(Server.amenities), headers: headers);

      if (categoriesResponse.statusCode == 200) {
        final categoriesJson = jsonDecode(categoriesResponse.body);
        setState(() {
          allCategory = categoriesJson['data']; // Access the 'data' key
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load categories: ${categoriesResponse.statusCode}");
      }

      if (amenitiesResponse.statusCode == 200) {
        final amenitiesJson = jsonDecode(amenitiesResponse.body);
        setState(() {
          allAmenities = amenitiesJson['data']; // Access the 'data' key
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load amenities: ${amenitiesResponse.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching categories/amenities: $e");
    }
  }

  void populateExistingVenue(dynamic detail) {
    setState(() {
      name = detail['venue_name'] ?? '';
      suburb = detail['suburb'] ?? '';
      location = detail['location'] ?? '';
      lat = double.tryParse('${detail['lat']}') ?? 0.0;
      lng = double.tryParse('${detail['lon']}') ?? 0.0;
      notice = detail['important_notice'] ?? '';
      description = detail['description'] ?? '';
      catId = detail['cat_id']?.toString() ?? '';
      nameofegg = ''; // Will be set when categories load
      final aList = detail['amenties'] as List<dynamic>? ?? [];
      arrOfAmenities = aList.map((e) => e['id'].toString()).toList();
    });
  }

  void handleTagChange(List<dynamic> selectedValues) {
    if (selectedValues.length > 5) {
      Fluttertoast.showToast(msg: "You can select up to 5 tags!");
      return;
    }
    setState(() {
      selectedTags = selectedValues.map((e) => e.toString()).toList();
    });
  }

  void toggleNameOfEggStatus() {
    setState(() {
      nameofeggStatus = !nameofeggStatus;
    });
  }

  void selectCategory(Map<String, dynamic> item) {
    setState(() {
      nameofegg = item['name'];
      catId = item['id'].toString();
      nameofeggStatus = false;
    });
  }

  void toggleReportStatus() {
    setState(() {
      reportStatus = !reportStatus;
    });
  }

  void selectAmenity(Map<String, dynamic> item) {
    final id = item['id'].toString();
    if (!arrOfAmenities.contains(id)) {
      setState(() {
        arrOfAmenities.add(id);
      });
    }
  }

  void removeAmenity(String item) {
    setState(() {
      arrOfAmenities.remove(item);
    });
  }

  void showImageDialog() {
    setState(() {
      dialogAlert = true;
    });
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        photos.add(image);
      });
    }
    setState(() {
      dialogAlert = false;
    });
  }

  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        photos.add(image);
      });
    }
    setState(() {
      dialogAlert = false;
    });
  }

  void removePhoto(int index) {
    setState(() {
      photos.removeAt(index);
    });
  }

  void showLocationDialog() {
    TextEditingController locController = TextEditingController(text: location);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Location"),
          content: TextField(
            controller: locController,
            decoration: const InputDecoration(
              hintText: "Type your location here",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  location = locController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void updateBtn() {
    if (name.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Venue Name");
      return;
    }
    if (nameofegg.isEmpty) {
      Fluttertoast.showToast(msg: "Select Category");
      return;
    }
    if (suburb.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Suburb");
      return;
    }
    if (location.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Location");
      return;
    }
    if (arrOfAmenities.isEmpty) {
      Fluttertoast.showToast(msg: "Choose Amenities");
      return;
    }
    if (description.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Description");
      return;
    }
    if (photos.isEmpty) {
      Fluttertoast.showToast(msg: "Select at least one image");
      return;
    }
    addVenueApi();
  }

  Future<void> addVenueApi() async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      final uri = Uri.parse(Server.venues);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = name;
      request.fields['category_id'] = catId;
      request.fields['suburb'] = suburb;
      request.fields['location'] = location;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lng.toString();
      request.fields['description'] = description;
      request.fields['important_notice'] = notice;

      for (var tagId in selectedTags) {
        request.fields['tag_ids[]'] = tagId;
      }

      for (var amenityId in arrOfAmenities) {
        request.fields['amenity_ids[]'] = amenityId;
      }

      print('Request Fields: ${request.fields}');

      for (var photo in photos) {
        final fileStream = http.ByteStream(photo.openRead());
        final length = await photo.length();
        final multipartFile = http.MultipartFile(
          'photos[]',
          fileStream,
          length,
          filename: photo.name,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      print('Response: $responseString');

      _handleResponseStatus(response, responseString);
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: "An error occurred: $e");
      print('Exception: $e');
    }
  }

  void _handleResponseStatus(http.StreamedResponse response, String responseString) {
    // If the HTTP status code is less than 300, consider it a success.
    if (response.statusCode < 300) {
      final responseJson = jsonDecode(responseString);
      Fluttertoast.showToast(
        msg: responseJson['message'] ?? "Venue added successfully",
      );
      setState(() {
        loader = false;
        confirmPopup = true;
      });
    } else {
      // For status codes 300 and above, treat it as an error.
      final responseJson = jsonDecode(responseString);
      // Check if the backend updated the internal status from error to 1.
      if (responseJson['status'] != null && responseJson['status'] == 1) {
        Fluttertoast.showToast(
          msg: responseJson['message'] ?? "Venue status updated to success.",
        );
        setState(() {
          loader = false;
          confirmPopup = true;
        });
      } else {
        Fluttertoast.showToast(
          msg: "Error: ${response.statusCode} - ${responseJson['message'] ?? 'Something went wrong.'}",
        );
        print('Error Response: $responseString');
        setState(() => loader = false);
      }
    }
  }

  void onDonePressed() {
    setState(() {
      confirmPopup = false;
    });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.allDetail != null ? 'Edit Venue' : 'Add New Venue',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Enter Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20),
                          const Text('Name of Venue', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Venue Name",
                              ),
                              onChanged: (value) => setState(() => name = value),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Category', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            child: InkWell(
                              onTap: toggleNameOfEggStatus,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    nameofegg.isEmpty ? "Select Category" : nameofegg,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  Icon(nameofeggStatus ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          if (nameofeggStatus)
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Design.lightPurple,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListView.builder(
                                itemCount: allCategory.length,
                                itemBuilder: (context, index) {
                                  final item = allCategory[index];
                                  return ListTile(
                                    title: Text(item['name']),
                                    onTap: () => selectCategory(item),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),
                          const Text('Tags', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          MultiSelectDialogField(
                            items: tags
                                .map((tag) => MultiSelectItem(tag['id'], tag['name'].toString()))
                                .toList(),
                            title: const Text("Select tags"),
                            selectedColor: Design.primaryColorOrange,
                            selectedItemsTextStyle: const TextStyle(color: Colors.white),
                            listType: MultiSelectListType.LIST,
                            onConfirm: handleTagChange,
                            buttonText: const Text("Select Tags"),
                            initialValue: selectedTags
                                .map((e) => int.tryParse(e))
                                .whereType<int>()
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text('Suburb', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Suburb",
                              ),
                              onChanged: (value) => setState(() => suburb = value),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Location', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            readOnly: true,
                            controller: TextEditingController(text: location),
                            onTap: showLocationDialog,
                            decoration: InputDecoration(
                              hintText: "Select location",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              fillColor: Design.lightPurple,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Type of Amenities', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: InkWell(
                              onTap: toggleReportStatus,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Select Amenities"),
                                  Icon(reportStatus ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          if (reportStatus)
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Design.lightPurple,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListView.builder(
                                itemCount: allAmenities.length,
                                itemBuilder: (context, index) {
                                  final item = allAmenities[index];
                                  return ListTile(
                                    title: Text(item['name']),
                                    onTap: () => selectAmenity(item),
                                  );
                                },
                              ),
                            ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: arrOfAmenities.map((amenityId) {
                              final amenity = allAmenities.firstWhere(
                                (a) => a['id'].toString() == amenityId,
                                orElse: () => {'name': 'Unknown'},
                              );
                              return Chip(
                                label: Text(amenity['name']),
                                backgroundColor: Design.primaryColorOrange,
                                labelStyle: const TextStyle(color: Colors.white),
                                deleteIcon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onDeleted: () => removeAmenity(amenityId),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text('Notice', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Notice",
                              ),
                              onChanged: (value) => setState(() => notice = value),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Description', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Description",
                              ),
                              maxLines: 5,
                              onChanged: (value) => setState(() => description = value),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Upload Pictures', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InkWell(
                                onTap: showImageDialog,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: Design.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      GlobalImages.camera,
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: photos.length,
                                    itemBuilder: (context, index) {
                                      final XFile photo = photos[index];
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: Design.white,
                                          borderRadius: BorderRadius.circular(5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade300,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(5),
                                              child: Image.file(
                                                File(photo.path),
                                                fit: BoxFit.cover,
                                                width: 90,
                                                height: 90,
                                              ),
                                            ),
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: InkWell(
                                                onTap: () => removePhoto(index),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.black54,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: updateBtn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Design.primaryColorOrange,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loader)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (dialogAlert)
            Center(
              child: Container(
                width: deviceWidth * 0.8,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Design.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: pickFromCamera,
                      child: Row(
                        children: const [
                          Icon(Icons.camera_alt, size: 24),
                          SizedBox(width: 10),
                          Text("Take a Photo"),
                        ],
                      ),
                    ),
                    const Divider(height: 20),
                    InkWell(
                      onTap: pickFromGallery,
                      child: Row(
                        children: const [
                          Icon(Icons.photo_library, size: 24),
                          SizedBox(width: 10),
                          Text("Photo from Gallery"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => dialogAlert = false),
                        child: const Text("Cancel"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (confirmPopup)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    width: deviceWidth * 0.85,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Design.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          GlobalImages.requestSent,
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.allDetail != null
                              ? 'The venue has been updated successfully.'
                              : 'Venue request sent. Please check your email for further instructions.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: onDonePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Design.primaryColorOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Done"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (confirmPaymentTerms)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    width: deviceWidth * 0.85,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Design.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'How do I list a venue?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Users that subscribe their venues to Flock can manage them here in the app. For more information, visit https://getflock.io/business/',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
