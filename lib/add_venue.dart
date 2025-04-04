import 'dart:convert';
import 'dart:io';


import 'package:flock/constants.dart';
import 'package:flock/location.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';


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
 static const Color blue = Colors.blue; // Added for link color
 static const double font14 = 14; // Added for dialog
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
 static const String categoryList =
     "http://165.232.152.77/mobi/api/vendor/categories";
 static const String amenities =
     "http://165.232.152.77/mobi/api/vendor/amenities";
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
  String tagSearchQuery = ''; // For searching tags
 final GlobalKey _categoryFieldKey = GlobalKey();
 final GlobalKey _amenityFieldKey=GlobalKey();
bool showCategoryDropdown = false; //
 bool loader = false;
 bool dialogAlert = false; // For image dialog
 bool confirmPopup = false; // For confirmation after submission
 bool showVenueDialog = false; // New state for "How do I list a venue?" dialog
final GlobalKey _tagsFieldKey = GlobalKey(); // For positioning the tags dropdown
bool showAmenityDropdown = false;


 bool showTagsDropdown = false; // To toggle the tags dropdown visibility
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


   // Show the "How do I list a venue?" dialog on screen entry
   WidgetsBinding.instance.addPostFrameCallback((_) {
     setState(() {
       showVenueDialog = true;
     });
   });
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
       Fluttertoast.showToast(
         msg: "Failed to load tags: ${response.statusCode}",
       );
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


     final categoriesResponse = await http.get(
       Uri.parse(Server.categoryList),
       headers: headers,
     );
     final amenitiesResponse = await http.get(
       Uri.parse(Server.amenities),
       headers: headers,
     );


     if (categoriesResponse.statusCode == 200) {
       final categoriesJson = jsonDecode(categoriesResponse.body);
       setState(() {
         allCategory = categoriesJson['data'] ?? [];
       });
     } else {
       Fluttertoast.showToast(
         msg: "Failed to load categories: ${categoriesResponse.statusCode}",
       );
     }


     if (amenitiesResponse.statusCode == 200) {
       final amenitiesJson = jsonDecode(amenitiesResponse.body);
       setState(() {
         allAmenities = amenitiesJson['data'] ?? [];
       });
     } else {
       Fluttertoast.showToast(
         msg: "Failed to load amenities: ${amenitiesResponse.statusCode}",
       );
     }
   } catch (e) {
     Fluttertoast.showToast(msg: "Error fetching categories/amenities: $e");
   }
 }


 // Populate from existing venue (Edit scenario)
 void populateExistingVenue(dynamic detail) {
   final existingName = detail['venue_name'] ?? '';
   final existingSuburb = detail['suburb'] ?? '';
   final existingLocation = detail['location'] ?? '';
   final existingNotice = detail['important_notice'] ?? '';
   final existingDescription = detail['description'] ?? '';


   nameController.text = existingName;
   suburbController.text = existingSuburb;
   noticeController.text = existingNotice;
   descriptionController.text = existingDescription;


   catId = detail['cat_id']?.toString() ?? '';
   nameofegg = '';


   lat = double.tryParse('${detail['lat']}') ?? 0.0;
   lng = double.tryParse('${detail['lon']}') ?? 0.0;


   location = existingLocation;


   final aList = detail['amenties'] as List<dynamic>? ?? [];
   arrOfAmenities = aList.map((e) => e['id'].toString()).toList();
 }


 // TAGS logic
void handleTagChange(List<int?> selectedValues) {
 // Filter out any null values.
 final validValues = selectedValues.whereType<int>().toList();
 if (validValues.length > 5) {
   Fluttertoast.showToast(msg: "You can select up to 5 tags!");
   return;
 }
 setState(() {
   selectedTags = validValues.map((e) => e.toString()).toList();
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
void pickLocation() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => LocationPicker()),
  );
  if (result != null && result is Map) {
    setState(() {
      location = result['address'] ?? "";
      lat = result['lat'] ?? 0.0;
      lng = result['lng'] ?? 0.0;
    });
  }
}




 Future<void> useCurrentLocation() async {
   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //  if (!serviceEnabled) {
  //    Fluttertoast.showToast(msg: "Location services are disabled.");
  //    return;
  //  }


  //  LocationPermission permission = await Geolocator.checkPermission();
  //  if (permission == LocationPermission.denied) {
  //    permission = await Geolocator.requestPermission();
  //    if (permission == LocationPermission.denied) {
  //      Fluttertoast.showToast(msg: "Location permission denied");
  //      return;
  //    }
  //  }


  //  if (permission == LocationPermission.deniedForever) {
  //    Fluttertoast.showToast(msg: "Location permission permanently denied");
  //    return;
  //  }


  //  final position = await Geolocator.getCurrentPosition(
  //    desiredAccuracy: LocationAccuracy.high,
  //  );
  //  setState(() {
  //    lat = position.latitude;
  //    lng = position.longitude;
  //    location = "Current Location ($lat, $lng)";
  //  });
 }


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


    //  for (var tagId in selectedTags) {
    //    request.fields['tag_ids[]'] = tagId;
    //  }

  for (var i = 0; i < selectedTags.length; i++) {
        request.fields["tag_ids[$i]"] = selectedTags[i];
      }

       for (var i = 0; i < arrOfAmenities.length; i++) {
        request.fields["amenity_ids[$i]"] = arrOfAmenities[i];
      }

    //  for (var amenityId in arrOfAmenities) {
    //    request.fields['amenity_ids[]'] = amenityId;
    //  }


     for (var photo in photos) {
       final fileStream = http.ByteStream(photo.openRead());
       final length = await photo.length();
       final multipartFile = http.MultipartFile(
         'images[]',
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


 void _handleResponseStatus(
   http.StreamedResponse response,
   String responseString,
 ) {
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
         msg:
             "Error: ${response.statusCode} - ${responseJson['message'] ?? 'Something went wrong.'}",
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


 // Method to launch URL
Future<void> _launchURL(String url) async {
 final Uri uri = Uri.parse(url);
 try {
   if (await canLaunchUrl(uri)) {
     await launchUrl(
       uri,
       mode: LaunchMode.externalApplication, // Use external app (e.g., browser)
     );
   } else {
     Fluttertoast.showToast(msg: "Could not launch $url");
   }
 } catch (e) {
   Fluttertoast.showToast(msg: "Error launching $url: $e");
 }
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
                 padding: const EdgeInsets.only(
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
                           style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                         // const SizedBox(height: 20),
                         // const Text('Name of Venue', style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 18),
                         AppConstants.customTextField(
                           controller: nameController,
                           hintText: 'Enter venue name',
                         ),


                         const SizedBox(height: 18),
                        // Add a GlobalKey to position the dropdown




// Replace the MultiSelectBottomSheetField with a custom dropdown
// Select Category field with dropdown

Container(
 decoration: BoxDecoration(
   color: Design.lightPurple,
   borderRadius: BorderRadius.circular(5),
 ),
 child: Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
     GestureDetector(
       key: _categoryFieldKey,
       onTap: () {
         setState(() {
           showCategoryDropdown = !showCategoryDropdown;
         });
       },
       child: Container(
         padding: const EdgeInsets.symmetric(
           horizontal: 15,
           vertical: 10,
         ),
         decoration: BoxDecoration(
           color: Design.lightPurple,
           borderRadius: BorderRadius.circular(5),
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(
               nameofegg.isEmpty ? "Select Category" : nameofegg,
               style: const TextStyle(fontSize: 15),
             ),
             Icon(
               showCategoryDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
               color: Colors.grey,
             ),
           ],
         ),
       ),
     ),
     if (showCategoryDropdown)
       Container(
         constraints: BoxConstraints(
           maxHeight: 50 * 5, // Show 4 items (each ListTile is ~48px tall)
         ),
         decoration: BoxDecoration(
           color: Design.lightPurple,
           borderRadius: const BorderRadius.only(
             bottomLeft: Radius.circular(5),
             bottomRight: Radius.circular(5),
           ),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Flexible(
               child: ListView.builder(
                 shrinkWrap: true,
                 itemCount: allCategory.length,
                 itemBuilder: (context, index) {
                   final category = allCategory[index];
                   final isSelected = catId == category['id'].toString();
                  return ListTile(
  dense: true, // Reduces ListTile height
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), // Less padding
  visualDensity: VisualDensity.compact, // Makes it even more compact
  title: Text(
    category['name'],
    style: const TextStyle(fontSize: 15),
  ),
  onTap: () {
    setState(() {
      catId = category['id'].toString();
      nameofegg = category['name'];
      showCategoryDropdown = false;
    });
  },
);

                 },
               ),
             ),
             Padding(
               padding: const EdgeInsets.all(6.0),
               child: SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {
                     setState(() {
                       showCategoryDropdown = false;
                     });
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Design.primaryColorOrange,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(5),
                     ),
                   ),
                   child: const Text(
                     "Done",
                     style: TextStyle(color: Colors.white),
                   ),
                 ),
               ),
             ),
           ],
         ),
       ),
   ],
 ),
),
                         // const Text('Tags', style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 18),
                         
       Container(
  decoration: BoxDecoration(
    color: Design.lightPurple,
    borderRadius: BorderRadius.circular(5),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        key: _tagsFieldKey,
        onTap: () {
          setState(() {
            showTagsDropdown = !showTagsDropdown;
            tagSearchQuery = ''; // Reset the search query when opening
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Design.lightPurple,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedTags.isEmpty
                    ? "Select Tags"
                    : selectedTags
                        .map((id) => tags.firstWhere(
                              (tag) => tag['id'].toString() == id,
                              orElse: () => {'name': 'Unknown'},
                            )['name'])
                        .join(", "),
                style: const TextStyle(fontSize: 15),
              ),
              Icon(
                showTagsDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
      if (showTagsDropdown)
        Container(
          constraints: BoxConstraints(
            maxHeight: 38 * 7 + 48, // 6 items (32px each) + search bar height (~48px)
          ),
          decoration: BoxDecoration(
            color: Design.lightPurple,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Search tags...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            tagSearchQuery = value;
                          });
                        },
                      ),
                    ),
                    const Icon(
                      Icons.arrow_back,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
              // List of filtered tags
              Builder(
                builder: (context) {
                  final filteredTags = tags.where((tag) {
                    final tagName = tag['name'].toString().toLowerCase();
                    return tagName.contains(tagSearchQuery.toLowerCase());
                  }).toList();
                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = filteredTags[index];
                        final isSelected =
                            selectedTags.contains(tag['id'].toString());
                     return ListTile(
  dense: true, // Reduces height
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1), // Reduced spacing
  visualDensity: VisualDensity.compact, // Even more compact
  title: Text(
    tag['name'],
    style: TextStyle(
      fontSize: 15, // Slightly bigger text for better readability
      color: isSelected ? Design.primaryColorOrange : Colors.black, // Orange when selected
      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, // Medium weight for selected
    ),
  ),
  trailing: isSelected
      ? Icon(Icons.check, color: Design.primaryColorOrange, size: 18) // Orange tick
      : null,
  onTap: () {
    setState(() {
      if (selectedTags.contains(tag['id'].toString())) {
        selectedTags.remove(tag['id'].toString());
      } else {
        if (selectedTags.length >= 5) {
          Fluttertoast.showToast(msg: "You can select up to 5 tags!");
          return;
        }
        selectedTags.add(tag['id'].toString());
      }
    });
  },
);


                      },
                    ),
                  );
                },
              ),
              // Done button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showTagsDropdown = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Design.primaryColorOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Done",
                      style:
                          TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  ),
),




                         // const SizedBox(height: 20),
                         // const Text('Suburb', style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 18),
                         AppConstants.suburbField(
                           controller: suburbController,
                         ),


                         // const SizedBox(height: 20),
                         // const Text('Location', style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 18),
                         GestureDetector(
                           onTap: pickLocation,
                           child: Container(
                             padding: const EdgeInsets.symmetric(
                               horizontal: 15,
                               vertical: 15,
                             ),
                             decoration: AppConstants.textFieldBoxDecoration.copyWith(
                               // You can also add border decoration if needed,
                               // but here we simply use the same boxDecoration.
                             ),
                             child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible(  // Wrap the text in Flexible to allow it to adjust within the available space
      child: Text(
        location.isEmpty ? "Pick location" : location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14.0,
          fontFamily: 'YourFontFamily',
          color: Colors.grey,
        ),
      ),
    ),
    const Icon(
      Icons.location_on,
      color: Colors.grey,
    ),
  ],
),

                           ),
                         ),


                         // const SizedBox(height: 20),
                         // const Text('Type of Amenities', style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 18),
                      Container(
 decoration: BoxDecoration(
   color: Design.lightPurple,
   borderRadius: BorderRadius.circular(5),
 ),
 child: Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
     GestureDetector(
       key: _amenityFieldKey,
       onTap: () {
         setState(() {
           showAmenityDropdown = !showAmenityDropdown;
         });
       },
       child: Container(
         padding: const EdgeInsets.symmetric(
           horizontal: 15,
           vertical: 15,
         ),
         decoration: BoxDecoration(
           color: Design.lightPurple,
           borderRadius: BorderRadius.circular(5),
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(
               arrOfAmenities.isEmpty
                   ? "Select Amenities"
                   : arrOfAmenities
                       .map((id) => allAmenities.firstWhere(
                             (amenity) => amenity['id'].toString() == id,
                           )['name'])
                       .join(", "),
               style: const TextStyle(fontSize: 15),
             ),
             Icon(
               showAmenityDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
               color: Colors.grey,
             ),
           ],
         ),
       ),
     ),
     if (showAmenityDropdown)
       Container(
         constraints: BoxConstraints(
           maxHeight: 32 * 6 + 48, // 6 items (32px each) + search bar height (~48px)
         ),
         decoration: BoxDecoration(
           color: Design.lightPurple,
           borderRadius: const BorderRadius.only(
             bottomLeft: Radius.circular(5),
             bottomRight: Radius.circular(5),
           ),
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
           
             Flexible(
               child: ListView.builder(
                 shrinkWrap: true,
                 itemCount: allAmenities.length,
                 itemBuilder: (context, index) {
                   final amenity = allAmenities[index];
                   final isSelected = arrOfAmenities.contains(amenity['id'].toString());
                   return ListTile(
  dense: true, // Reduces ListTile height
  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1), // Compact spacing
  visualDensity: VisualDensity.compact, // Reduces extra spacing
  title: Text(
    amenity['name'],
    style: TextStyle(
      fontSize: 14,
      color: arrOfAmenities.contains(amenity['id'].toString()) 
          ? Design.primaryColorOrange 
          : Colors.black, // Orange when selected
      fontWeight: arrOfAmenities.contains(amenity['id'].toString()) 
          ? FontWeight.w500 
          : FontWeight.normal, // Medium weight for selected
    ),
  ),
  trailing: arrOfAmenities.contains(amenity['id'].toString())
      ? Icon(Icons.check, color: Design.primaryColorOrange, size: 18) // Orange tick for selected
      : null,
  onTap: () {
    setState(() {
      if (arrOfAmenities.contains(amenity['id'].toString())) {
        arrOfAmenities.remove(amenity['id'].toString());
      } else {
        arrOfAmenities.add(amenity['id'].toString());
      }
    });
  },
);

                 },
               ),
             ),
             // Done button
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
               child: SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {
                     setState(() {
                       showAmenityDropdown = false;
                     });
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Design.primaryColorOrange,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(5),
                     ),
                     padding: const EdgeInsets.symmetric(vertical: 12),
                   ),
                   child: const Text(
                     "Done",
                     style: TextStyle(color: Colors.white, fontSize: 14),
                   ),
                 ),
               ),
             ),
           ],
         ),
       ),
   ],
 ),
),


                         // const SizedBox(height: 20),
                         // const Text('Notice', style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 18),
                         AppConstants.noticeField(
                           controller: noticeController,
                         ),


                         const SizedBox(height: 20),
                         const Text(
                           'Description',
                           style: TextStyle(fontSize: 16),
                         ),
                         const SizedBox(height: 18),
                         Container(
                           decoration: AppConstants.textFieldBoxDecoration,
                           child: TextField(
                             controller: descriptionController,
                             maxLines: 5,
                             style: const TextStyle(
                               color: Colors.black,
                               fontSize: 14.0,
                               fontFamily: 'YourFontFamily',
                             ),
                             decoration: AppConstants.textFieldDecoration
                                 .copyWith(hintText: "Description"),
                           ),
                         ),


                         const SizedBox(height: 20),
                         const Text(
                           'Upload Pictures',
                           style: TextStyle(fontSize: 16),
                         ),
                         const SizedBox(height: 18),
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
                                       margin: const EdgeInsets.only(
                                         right: 10,
                                       ),
                                       decoration: BoxDecoration(
                                         color: Design.white,
                                         borderRadius: BorderRadius.circular(
                                           5,
                                         ),
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
                                             borderRadius:
                                                 BorderRadius.circular(5),
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
                                                 decoration:
                                                     const BoxDecoration(
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
                               padding: const EdgeInsets.symmetric(
                                 vertical: 14,
                               ),
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
                 boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
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
                   const SizedBox(height: 18),
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
                           padding: const EdgeInsets.symmetric(
                             horizontal: 24,
                             vertical: 12,
                           ),
                         ),
                         child: const Text("Done"),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           ),
         // "How do I list a venue?" Dialog
         if (showVenueDialog)
           if (showVenueDialog)
 Positioned.fill(
   child: Container(
     color: Colors.black54, // semi-transparent overlay
     child: Center(
       child: Container(
         width: deviceWidth - 30,
         padding: const EdgeInsets.symmetric(vertical: 20),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(8),
           boxShadow: const [
             BoxShadow(color: Colors.black26, blurRadius: 8),
           ],
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.center,
           children: [
             const Text(
               "How do I list a venue?",
               style: TextStyle(
                 fontSize: Design.font18,
                 fontWeight: FontWeight.w500,
                 color: Design.black,
               ),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 10),
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 16),
               child: Text(
                 "Users that subscribe their venues to Flock can manage them here in the app.",
                 style: TextStyle(
                   fontSize: Design.font14,
                   color: Design.black,
                 ),
                 textAlign: TextAlign.left,
               ),
             ),
             const SizedBox(height: 10),
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 16),
               child: Text(
                 "For more information visit here",
                 style: TextStyle(
                   fontSize: Design.font14,
                   color: Design.black,
                 ),
               ),
             ),
             GestureDetector(
               onTap: () => launchUrl(Uri.parse('https://getflock.io/business/')),
               child: const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 16),
                 child: Text(
                   "https://getflock.io/business/",
                   style: TextStyle(
                     fontSize: Design.font14,
                     color: Design.blue,
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 20),
             GestureDetector(
               onTap: () {
                 setState(() {
                   showVenueDialog = false; // Close dialog
                 });
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(
                   vertical: 10,
                   horizontal: 20,
                 ),
                 decoration: BoxDecoration(
                   color: Design.white,
                   borderRadius: BorderRadius.circular(5),
                 ),
                 child: const Text(
                   "Got it!",
                   style: TextStyle(
                     color: Design.primaryColorOrange,
                     fontSize: Design.font15,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ),
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


// Minimal Location Picker Screen using Google Maps
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
         ),
       ],
     ),
     body: GoogleMap(
       initialCameraPosition: CameraPosition(target: pickedPosition, zoom: 14),
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
         ),
       },
     ),
   );
 }
}




