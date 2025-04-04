import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
   _nameController = TextEditingController(text: widget.venueData['name']?.toString() ?? '');
   _suburbController = TextEditingController(text: widget.venueData['suburb']?.toString() ?? '');
   _descriptionController = TextEditingController(text: widget.venueData['description']?.toString() ?? '');
   _locationController = TextEditingController(text: widget.venueData['location']?.toString() ?? '');
   _latController = TextEditingController(text: widget.venueData['lat']?.toString() ?? '');
   _lonController = TextEditingController(text: widget.venueData['lon']?.toString() ?? '');
   _noticeController = TextEditingController(text: widget.venueData['notice']?.toString() ?? '');
   _featherPointsController = TextEditingController(text: widget.venueData['feather_points']?.toString() ?? '');
   _venuePointsController = TextEditingController(text: widget.venueData['venue_points']?.toString() ?? '');


   // Set selected category
   _selectedCategoryId = widget.venueData['category_id']?.toString() ?? widget.categoryId;


   // Pre-select tags if available
   if (widget.venueData['tags'] != null) {
     _selectedTagIds = (widget.venueData['tags'] as List).map((tag) => tag['id'] as int).toList();
   }


   // Pre-select amenities if available
   if (widget.venueData['amenities'] != null) {
     _selectedAmenityIds = (widget.venueData['amenities'] as List).map((am) => am['id'] as int).toList();
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
     const tagsUrl = 'http://165.232.152.77/mobi/api/vendor/tags';
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
     const amenitiesUrl = 'http://165.232.152.77/mobi/api/vendor/amenities';
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


 Widget _buildTagsDropdown() {
   final selectedTagNames = _allTags
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
               final filteredTags = _allTags.where((tag) {
                 final tagName = tag['name']?.toString().toLowerCase() ?? '';
                 return tagName.contains(localSearchText.toLowerCase());
               }).toList();


               return AlertDialog(
                 title: const Text("Select Tags"),
                 content: SizedBox(
                   width: double.maxFinite,
                   height: 300,
                   child: Column(
                     children: [
                       TextField(
                         decoration: const InputDecoration(
                           labelText: 'Search Tags',
                           border: OutlineInputBorder(),
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
                             final isSelected = _selectedTagIds.contains(tagId);
                             return CheckboxListTile(
                               title: Text(tagName),
                               value: isSelected,
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
       decoration: const InputDecoration(
         labelText: "Tags",
         border: OutlineInputBorder(),
       ),
       child: Text(
         selectedTagNames.isNotEmpty ? selectedTagNames.join(", ") : "Select Tags",
         style: const TextStyle(color: Colors.black),
       ),
     ),
   );
 }


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
                 title: const Text("Select Amenities"),
                 content: SizedBox(
                   width: double.maxFinite,
                   height: 300,
                   child: Column(
                     children: [
                       TextField(
                         decoration: const InputDecoration(
                           labelText: 'Search Amenities',
                           border: OutlineInputBorder(),
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
                             final amenityName = amenity['name']?.toString() ?? '';
                             final isSelected = _selectedAmenityIds.contains(amenityId);
                             return CheckboxListTile(
                               title: Text(amenityName),
                               value: isSelected,
                               onChanged: (bool? value) {
                                 setStateDialog(() {
                                   setState(() {
                                     if (value == true) {
                                       _selectedAmenityIds.add(amenityId);
                                     } else {
                                       _selectedAmenityIds.remove(amenityId);
                                     }
                                   });
                                 });
                               },
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
       decoration: const InputDecoration(
         labelText: "Amenities",
         border: OutlineInputBorder(),
       ),
       child: Text(
         selectedAmenityNames.isNotEmpty ? selectedAmenityNames.join(", ") : "Select Amenities",
         style: const TextStyle(color: Colors.black),
       ),
     ),
   );
 }


 Future<void> _updateVenue() async {
   if (_nameController.text.isEmpty ||
       _descriptionController.text.isEmpty ||
       _locationController.text.isEmpty ||
       _latController.text.isEmpty ||
       _lonController.text.isEmpty) {
     Fluttertoast.showToast(
         msg: 'Please fill in all required fields', backgroundColor: Colors.red);
     return;
   }
   if (double.tryParse(_latController.text) == null ||
       double.tryParse(_lonController.text) == null) {
     Fluttertoast.showToast(
         msg: 'Invalid latitude or longitude', backgroundColor: Colors.red);
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
// Add selected tags (encode the list as JSON)
   request.fields['tag_ids'] = jsonEncode(_selectedTagIds);


   // Add selected amenities (encode the list as JSON)
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
         textColor: Colors.white);
   } finally {
     setState(() {
       _isLoading = false;
     });
   }
 }


 @override
 Widget build(BuildContext context) {
   final categoryDropdownItems = _allCategories.map((cat) {
     final catId = cat['id'].toString();
     final catName = cat['name'].toString();
     return DropdownMenuItem<String>(
       value: catId,
       child: Text(catName),
     );
   }).toList();


   final selectedImageWidget = _selectedImage != null
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
                 TextField(
                   controller: _nameController,
                   decoration: const InputDecoration(
                     labelText: 'Venue Name',
                     border: OutlineInputBorder(),
                   ),
                 ),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                   decoration: const InputDecoration(
                     labelText: 'Category',
                     border: OutlineInputBorder(),
                   ),
                   value: _selectedCategoryId,
                   items: categoryDropdownItems,
                   onChanged: (value) {
                     setState(() {
                       _selectedCategoryId = value;
                     });
                   },
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
                 const SizedBox(height: 16),
                 _buildTagsDropdown(),
                 const SizedBox(height: 16),
                 _buildAmenitiesDropdown(),
                 const SizedBox(height: 16),
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
                       style: TextStyle(color: Colors.white, fontSize: Design.font17),
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


