import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:http/http.dart' as http;

// -------------- NEW IMPORTS FOR LOCATION & MAP --------------
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ------------------------------------------------------------

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
  bool dialogAlert = false; // For image dialog
  bool confirmPopup = false; // For confirmation after submission

  // ---------- TEXT CONTROLLERS (Fix reverse typing) ----------
  late TextEditingController nameController;
  late TextEditingController suburbController;
  late TextEditingController noticeController;
  late TextEditingController descriptionController;

  // Category
  bool nameofeggStatus = false; // toggles category dropdown
  String catId = '';
  String nameofegg = ''; // category name

  // Location
  String location = '';
  double lat = 0.0;
  double lng = 0.0;

  // Amenities
  bool reportStatus = false; // toggles amenities dropdown
  List<dynamic> allAmenities = [];
  List<String> arrOfAmenities = [];

  // Category list
  List<dynamic> allCategory = [];

  // Tags
  List<dynamic> tags = [];
  List<String> selectedTags = [];

  // Photos
  final ImagePicker _picker = ImagePicker();
  List<XFile> photos = [];

  // Auth
  String userId = "";

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    nameController = TextEditingController();
    suburbController = TextEditingController();
    noticeController = TextEditingController();
    descriptionController = TextEditingController();

    // Load category & amenities if provided
    if (widget.allCategory != null) {
      allCategory = widget.allCategory!;
    }
    if (widget.allAmenities != null) {
      allAmenities = widget.allAmenities!;
    }

    // If editing an existing venue, populate fields
    if (widget.allDetail != null) {
      populateExistingVenue(widget.allDetail);
    }

    // Get user data, tags, categories, amenities
    getUserId();
    getVenueTags();
    getCategoriesAmenties();
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    nameController.dispose();
    suburbController.dispose();
    noticeController.dispose();
    descriptionController.dispose();
    super.dispose();
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
          tags = tagsJson['data'] ?? [];
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
          allCategory = categoriesJson['data'] ?? [];
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load categories: ${categoriesResponse.statusCode}");
      }

      if (amenitiesResponse.statusCode == 200) {
        final amenitiesJson = jsonDecode(amenitiesResponse.body);
        setState(() {
          allAmenities = amenitiesJson['data'] ?? [];
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load amenities: ${amenitiesResponse.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching categories/amenities: $e");
    }
  }

  // Populate from existing venue (Edit scenario)
  void populateExistingVenue(dynamic detail) {
    // Strings
    final existingName = detail['venue_name'] ?? '';
    final existingSuburb = detail['suburb'] ?? '';
    final existingLocation = detail['location'] ?? '';
    final existingNotice = detail['important_notice'] ?? '';
    final existingDescription = detail['description'] ?? '';

    // Controllers
    nameController.text = existingName;
    suburbController.text = existingSuburb;
    noticeController.text = existingNotice;
    descriptionController.text = existingDescription;

    // Category
    catId = detail['cat_id']?.toString() ?? '';
    nameofegg = ''; // We will set once categories load (matching catId)

    // Coordinates
    lat = double.tryParse('${detail['lat']}') ?? 0.0;
    lng = double.tryParse('${detail['lon']}') ?? 0.0;

    // Location text
    location = existingLocation;

    // Amenities
    final aList = detail['amenties'] as List<dynamic>? ?? [];
    arrOfAmenities = aList.map((e) => e['id'].toString()).toList();
  }

  // TAGS logic
  void handleTagChange(List<dynamic> selectedValues) {
    if (selectedValues.length > 5) {
      Fluttertoast.showToast(msg: "You can select up to 5 tags!");
      return;
    }
    setState(() {
      selectedTags = selectedValues.map((e) => e.toString()).toList();
    });
  }

  // Category logic
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

  // Amenities logic
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

  // Image logic
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

  // -------------- LOCATION PICKING LOGIC --------------

  /// Show a bottom sheet with three options: use current location, pick from map, or enter manually.
  void pickLocation() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text("Use Current Location"),
              onTap: () async {
                Navigator.pop(context);
                await useCurrentLocation();
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.map),
            //   title: const Text("Pick from Map"),
            //   onTap: () async {
            //     Navigator.pop(context);
            //     final LatLng? result = await Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => LocationPickerScreen(
            //           initialPosition: LatLng(lat, lng),
            //         ),
            //       ),
            //     );
            //     if (result != null) {
            //       setState(() {
            //         lat = result.latitude;
            //         lng = result.longitude;
            //         location = "Picked from Map ($lat, $lng)";
            //       });
            //     }
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.edit_location_alt),
              title: const Text("Enter Manually"),
              onTap: () {
                Navigator.pop(context);
                showManualLocationDialog();
              },
            ),
          ],
        );
      },
    );
  }

  /// Use Geolocator to get current device location
  Future<void> useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: "Location permission permanently denied");
      return;
    }

    // Permissions are granted; get location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      lat = position.latitude;
      lng = position.longitude;
      location = "Current Location ($lat, $lng)";
    });
  }

  /// Let user type in a location manually (address or coordinate)
  void showManualLocationDialog() {
    final locController = TextEditingController(text: location);
    final latController = TextEditingController(text: lat.toString());
    final lonController = TextEditingController(text: lng.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Location Details"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: locController,
                  decoration: const InputDecoration(
                    labelText: "Location Name or Address",
                  ),
                ),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(labelText: "Latitude"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: lonController,
                  decoration: const InputDecoration(labelText: "Longitude"),
                  keyboardType: TextInputType.number,
                ),
              ],
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
                  lat = double.tryParse(latController.text) ?? 0.0;
                  lng = double.tryParse(lonController.text) ?? 0.0;
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
  // ----------------------------------------------------

  // Validate form fields and submit
  void updateBtn() {
    if (nameController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Venue Name");
      return;
    }
    if (nameofegg.isEmpty) {
      Fluttertoast.showToast(msg: "Select Category");
      return;
    }
    if (suburbController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter Suburb");
      return;
    }
    if (location.isEmpty) {
      Fluttertoast.showToast(msg: "Select or Enter Location");
      return;
    }
    if (arrOfAmenities.isEmpty) {
      Fluttertoast.showToast(msg: "Choose Amenities");
      return;
    }
    if (descriptionController.text.isEmpty) {
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

      request.fields['name'] = nameController.text;
      request.fields['category_id'] = catId;
      request.fields['suburb'] = suburbController.text;
      request.fields['location'] = location;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lng.toString();
      request.fields['description'] = descriptionController.text;
      request.fields['important_notice'] = noticeController.text;

      // Attach tags
      for (var tagId in selectedTags) {
        request.fields['tag_ids[]'] = tagId;
      }

      // Attach amenities
      for (var amenityId in arrOfAmenities) {
        request.fields['amenity_ids[]'] = amenityId;
      }

      // Attach images
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
      _handleResponseStatus(response, responseString);
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: "An error occurred: $e");
      print('Exception: $e');
    }
  }

  void _handleResponseStatus(http.StreamedResponse response, String responseString) {
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
      final responseJson = jsonDecode(responseString);
      if (responseJson['status'] == 1) {
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
                // Top bar
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
                // Body
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
                          // 1) Venue Name
                          const Text('Name of Venue', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Venue Name",
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 2) Category
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
                          // 3) Tags
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
                          // 4) Suburb
                          const Text('Suburb', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: suburbController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Suburb",
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 5) Location
                          const Text('Location', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: ListTile(
                              title: Text(
                                location.isEmpty ? "Pick location" : location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.location_on),
                              onTap: pickLocation,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 6) Amenities
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
                          // 7) Notice
                          const Text('Notice', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: noticeController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter Notice",
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 8) Description
                          const Text('Description', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: TextField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Description",
                              ),
                              maxLines: 5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 9) Photos
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
                          // 10) Submit Button
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
          // Loader overlay
          if (loader)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          // Dialog for picking images
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
          // Confirmation popup
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
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Minimal Location Picker Screen using Google Maps
// ----------------------------------------------------
class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const LocationPickerScreen({Key? key, required this.initialPosition})
      : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;
  LatLng pickedPosition = const LatLng(33.6844, 73.0479); // Default position

  @override
  void initState() {
    super.initState();
    // If initialPosition is not (0,0), use it
    if (widget.initialPosition.latitude != 0.0 &&
        widget.initialPosition.longitude != 0.0) {
      pickedPosition = widget.initialPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Design.primaryColorOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, pickedPosition);
            },
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickedPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) => mapController = controller,
        onTap: (LatLng latLng) {
          setState(() {
            pickedPosition = latLng;
          });
        },
        markers: {
          Marker(
            markerId: const MarkerId("pickedLocation"),
            position: pickedPosition,
          )
        },
      ),
    );
  }
}
