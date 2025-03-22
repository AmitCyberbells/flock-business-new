import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multiselect/multiselect.dart';

// Placeholder for your design tokens, images, and r logic
class Design {
  static const Color primaryColorOrange = Colors.orange;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color lightPurple = Color(0xFFF0F0F5);
  static const double font15 = 15;
  static const double font16 = 16;
  static const double font18 = 18;
  static const double font20 = 20;

  // ... Add more as needed
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

// Example server endpoints
class Server {
  static const String addVenue = "https://yourserver.com/addvenue";
  static const String venueTags = "https://yourserver.com/venue_tags";
  static const String categoryList = "https://yourserver.com/categorylist";
  // ... etc.
}

// Main widget
class AddEggScreen extends StatefulWidget {
  // If you need to pass parameters, add them here
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
  // React Native states converted to Dart variables:
  bool loader = false;
  bool dialogAlert = false;         // For "Take a Photo" or "Photo from Gallery" dialog
  bool confirmPopup = false;        // For success confirmation popup
  bool confirmPaymentTerms = false; // For "How do I list a venue?" dialog

  // Example form fields:
  String name = '';
  String suburb = '';
  String location = 'Location';
  String notice = '';
  String description = '';

  // Category (was "nameofegg")
  bool nameofeggStatus = false;     // toggles the dropdown open/close
  String nameofegg = '';
  String catId = '';

  // Amenities
  bool reportStatus = false;        // toggles the "Select Amenities" dropdown
  List<dynamic> allAmenities = [];  // from server
  List<String> arrOfAmenities = []; // selected amenities

  // Category list
  List<dynamic> allCategory = [];

  // Tags
  List<dynamic> tags = [];
  List<String> selectedTags = [];

  // Photos
  final ImagePicker _picker = ImagePicker();
  List<XFile> photos = []; // to store actual XFile objects

  // For location lat/lng
  double lat = 0.0;
  double lng = 0.0;

  @override
  void initState() {
    super.initState();
    // If the user passed in category/amenities from props, set them
    if (widget.allCategory != null) {
      allCategory = widget.allCategory!;
    }
    if (widget.allAmenities != null) {
      allAmenities = widget.allAmenities!;
    }

    // If we have existing data from "allDetail", populate fields
    if (widget.allDetail != null) {
      populateExistingVenue(widget.allDetail);
    }

    getUserId();
    getVenueTags();
    getCategoriesAmenties();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    // do something with userId if needed
  }

  // Example function to fetch tags
  Future<void> getVenueTags() async {
    // TODO: Replace with real server call
    // final response = await ApiRequest.postRequestWithoutToken(Server.venueTags, {});
    // if (response['status'] == 'success') {
    //   setState(() { tags = response['data']; });
    // }
    // For now, mock data:
    setState(() {
      tags = [
        {'id': 1, 'name': 'Live Music'},
        {'id': 2, 'name': 'Rooftop'},
        {'id': 3, 'name': 'Kid Friendly'},
        {'id': 4, 'name': 'Outdoor Seating'},
      ];
    });
  }

  // Example function to fetch categories/amenities
  Future<void> getCategoriesAmenties() async {
    if (allCategory.isNotEmpty && allAmenities.isNotEmpty) return;
    // TODO: Replace with real server call
    // final response = await ApiRequest.postRequestWithoutToken(Server.categoryList, {});
    // if (response['status'] == 'success') {
    //   setState(() {
    //     allCategory = response['Category'];
    //     allAmenities = response['Amenties'];
    //   });
    // }
    // For now, mock data if not already set:
    if (allCategory.isEmpty) {
      allCategory = [
        {'id': '1', 'name': 'Bar'},
        {'id': '2', 'name': 'Restaurant'},
        {'id': '3', 'name': 'Cafe'},
      ];
    }
    if (allAmenities.isEmpty) {
      allAmenities = [
        {'id': '101', 'name': 'WiFi'},
        {'id': '102', 'name': 'Parking'},
        {'id': '103', 'name': 'Pet Friendly'},
      ];
    }
    setState(() {});
  }

  void populateExistingVenue(dynamic detail) {
    // If editing an existing venue:
    setState(() {
      name = detail['venue_name'] ?? '';
      suburb = detail['suburb'] ?? '';
      location = detail['location'] ?? 'Location';
      lat = double.tryParse('${detail['lat']}') ?? 0.0;
      lng = double.tryParse('${detail['lon']}') ?? 0.0;
      notice = detail['important_notice'] ?? '';
      description = detail['description'] ?? '';

      // Category
      catId = detail['cat_id'] ?? '';
      // find matching category name
      // (assuming allCategory is already loaded or will be loaded soon)
      nameofegg = ''; // will fill once we have the category list

      // Amenities
      // Convert from detail['amenties'] array to a list of strings
      // so we can show them in arrOfAmenities
      final aList = detail['amenties'] as List<dynamic>? ?? [];
      arrOfAmenities = aList.map((e) => e['name'].toString()).toList();

      // If there are existing images
      final multiImage = detail['multiimage'] as List<dynamic>? ?? [];
      for (var img in multiImage) {
        // We can’t directly create XFile from a URL, but we can store the URL.
        // For demonstration, we just store them in a list as placeholders
        // If you need to display them in an Image widget, you can store the URL
        // or fetch them via network.
        // For now, just store them in a string list or do a custom approach
        // photos[] in Flutter typically holds XFiles from user picks
      }
    });
  }

  // For the multi-select tags
  void handleTagChange(List<dynamic> selectedValues) {
    // Limit to 5
    if (selectedValues.length > 5) {
      Fluttertoast.showToast(msg: "You can select up to 5 tags!");
      return;
    }
    setState(() {
      selectedTags = selectedValues.map((e) => e.toString()).toList();
    });
  }

  // Toggling the "Category" dropdown
  void toggleNameOfEggStatus() {
    setState(() {
      nameofeggStatus = !nameofeggStatus;
    });
  }

  // Selecting a category from the list
  void selectCategory(Map<String, dynamic> item) {
    setState(() {
      nameofegg = item['name'];
      catId = item['id'];
      nameofeggStatus = false;
    });
  }

  // Toggling the "Amenities" dropdown
  void toggleReportStatus() {
    setState(() {
      reportStatus = !reportStatus;
    });
  }

  // Selecting an amenity
  void selectAmenity(Map<String, dynamic> item) {
    final name = item['name'];
    // If already selected, do nothing
    if (!arrOfAmenities.contains(name)) {
      setState(() {
        arrOfAmenities.add(name);
      });
    }
  }

  // Removing an amenity
  void removeAmenity(String item) {
    setState(() {
      arrOfAmenities.remove(item);
    });
  }

  // Show a "Camera or Gallery" dialog
  void showImageDialog() {
    setState(() {
      dialogAlert = true;
    });
  }

  // Pick from camera
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

  // Pick from gallery
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

  // Removing an image
  void removePhoto(int index) {
    setState(() {
      photos.removeAt(index);
    });
  }

  // The "Continue" button
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
    if (location == 'Location' || location.isEmpty) {
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
    // All good, call addVenueApi
    addVenueApi();
  }

  Future<void> addVenueApi() async {
    // Example of how you might send a multi-part form
    setState(() {
      loader = true;
    });

    // final request = http.MultipartRequest('POST', Uri.parse(Server.addVenue));
    // request.fields['userid'] = '...';
    // request.fields['cat_id'] = catId;
    // request.fields['venue_name'] = name;
    // ...
    // for (final XFile photo in photos) {
    //   request.files.add(await http.MultipartFile.fromPath('files[]', photo.path));
    // }
    // final response = await request.send();
    // ...
    // For demonstration, we simulate success after 2 seconds:
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      loader = false;
      confirmPopup = true; // Show success popup
    });
  }

  // Closes the success popup and navigates back
  void onDonePressed() {
    setState(() {
      confirmPopup = false;
    });
    Navigator.pop(context); // or however you want to go back
  }

  // For "How do I list a venue?" popup
  void openPaymentTermsDialog() {
    setState(() {
      confirmPaymentTerms = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      // No appBar, we replicate a custom header
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    left: 10,
                    right: 10,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.allDetail != null
                                ? 'Edit Venue'
                                : 'Add New Venue',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 50), // Placeholder for alignment
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name of Venue
                          const Text(
                            'Name of Venue',
                            style: TextStyle(fontSize: 16),
                          ),
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

                          // Category
                          const Text(
                            'Category',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 12),
                            child: InkWell(
                              onTap: toggleNameOfEggStatus,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    nameofegg.isEmpty
                                        ? "Select Category"
                                        : nameofegg,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  Icon(
                                    nameofeggStatus
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                  ),
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

                          // Tags
                          const Text(
                            'Tags',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Design.lightPurple,
                          //     borderRadius: BorderRadius.circular(5),
                          //   ),
                          //   padding: const EdgeInsets.all(10),
                          //   child: MultiSelectDialogField(
                          //     items: tags
                          //         .map((tag) => MultiSelectItem(
                          //             tag['id'], tag['name'].toString()))
                          //         .toList(),
                          //     title: const Text("Select tags"),
                          //     selectedColor: Design.primaryColorOrange,
                          //     selectedItemsTextStyle:
                          //         const TextStyle(color: Colors.white),
                          //     listType: MultiSelectListType.LIST,
                          //     onConfirm: (values) {
                          //       // values is a List of item IDs
                          //       handleTagChange(values);
                          //     },
                          //     buttonText: const Text("Select Tags"),
                          //     initialValue: selectedTags
                          //         .map((e) => int.tryParse(e))
                          //         .whereType<int>()
                          //         .toList(),
                          //   ),
                          // ),
                          const SizedBox(height: 20),

                          // Suburb
                          const Text(
                            'Suburb',
                            style: TextStyle(fontSize: 16),
                          ),
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
                              onChanged: (value) =>
                                  setState(() => suburb = value),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Location
                          const Text(
                            'Location',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              // Example of navigating to a Google Places screen
                              // Navigator.pushNamed(context, '/GooglePlaces');
                              // For now, just simulate
                              Fluttertoast.showToast(msg: "Select location...");
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Design.lightPurple,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 12),
                              child: Text(location),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Type of Amenities
                          const Text(
                            'Type of Amenities',
                            style: TextStyle(fontSize: 16),
                          ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Select Amenities"),
                                  Icon(
                                    reportStatus
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                  ),
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
                          // Show selected amenities
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: arrOfAmenities.map((item) {
                              return Chip(
                                label: Text(item),
                                backgroundColor: Design.primaryColorOrange,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                deleteIcon: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                                onDeleted: () => removeAmenity(item),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Notice
                          const Text(
                            'Notice',
                            style: TextStyle(fontSize: 16),
                          ),
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
                              onChanged: (value) =>
                                  setState(() => notice = value),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Design.lightPurple,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Description",
                              ),
                              maxLines: 5,
                              onChanged: (value) =>
                                  setState(() => description = value),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Upload Pictures
                          const Text(
                            'Upload Pictures',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Button for gallery
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
                              // Show selected images
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
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          color: Design.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade300,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        // child: Stack(
                                        //   children: [
                                        //     ClipRRect(
                                        //       borderRadius:
                                        //           BorderRadius.circular(5),
                                        //       child: Image.file(
                                        //         // In Flutter web, you'd use .bytes
                                        //         // For mobile, use File(photo.path)
                                        //         // ignoring web vs. mobile detail
                                        //         File(photo.path),
                                        //         fit: BoxFit.cover,
                                        //         width: 90,
                                        //         height: 90,
                                        //       ),
                                        //     ),
                                        //     Positioned(
                                        //       top: 2,
                                        //       right: 2,
                                        //       child: InkWell(
                                        //         onTap: () => removePhoto(index),
                                        //         child: Container(
                                        //           width: 24,
                                        //           height: 24,
                                        //           decoration:
                                        //               const BoxDecoration(
                                        //             shape: BoxShape.circle,
                                        //             color: Colors.black54,
                                        //           ),
                                        //           child: const Icon(
                                        //             Icons.close,
                                        //             color: Colors.white,
                                        //             size: 18,
                                        //           ),
                                        //         ),
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: updateBtn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Design.primaryColorOrange,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
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

          // "Take a Photo" or "Photo from Gallery" dialog
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

          // confirm_popup overlay
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
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: onDonePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Design.primaryColorOrange,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Done"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // confirmPaymentTerms
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
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



