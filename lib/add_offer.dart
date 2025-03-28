import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddOfferScreen extends StatefulWidget {
  const AddOfferScreen({Key? key}) : super(key: key);

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  // final TextEditingController _feeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Separate controllers for each type of points
  final TextEditingController _venuePointsController = TextEditingController();
  final TextEditingController _appPointsController = TextEditingController();

  // Venues stored as a list of maps: [{'id': 1, 'name': 'Venue 1'}, ...]
  List<Map<String, dynamic>> _venues = [
    {'id': null, 'name': 'Select Venue'}
  ];
  // Currently selected venue map
  Map<String, dynamic>? _selectedVenue;

  // Checkboxes for redeem type
  bool _useVenuePoints = false; // "feather_points"
  bool _useAppPoints = false;   // "venue_points"

  // Image picking
  XFile? _pickedImage;

  // Loading states
  bool _isVenuesLoading = false;
  bool _isSubmitting = false;

  // Error messages
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedVenue = _venues.first; // default to "Select Venue"
    _fetchVenues();
  }

  @override
  void dispose() {
    _nameController.dispose();
    // _feeController.dispose();
    _descriptionController.dispose();
    _venuePointsController.dispose();
    _appPointsController.dispose();
    super.dispose();
  }

  /// Retrieve token stored during login
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch the list of venues from the API
  Future<void> _fetchVenues() async {
    setState(() {
      _isVenuesLoading = true;
      _errorMessage = '';
    });

    String? token = await _getToken();
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/venues');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> venuesData = data['data'];
          List<Map<String, dynamic>> fetchedVenues = [
            {'id': null, 'name': 'Select Venue'}
          ];

          for (var v in venuesData) {
            fetchedVenues.add({
              'id': v['id'],
              'name': v['name'] ?? 'Unnamed Venue',
            });
          }

          setState(() {
            _venues = fetchedVenues;
            _selectedVenue = _venues.first;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load venues.';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Error ${response.statusCode}: Unable to fetch venues.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }

    setState(() {
      _isVenuesLoading = false;
    });
  }

  /// Pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  /// Validate form and submit the offer (multipart/form-data)
  Future<void> _submitOffer() async {
    final name = _nameController.text.trim();
    // final fee = _feeController.text.trim();
    final description = _descriptionController.text.trim();

    final venuePoints = _venuePointsController.text.trim(); // user input for "Venue Points"
    final appPoints = _appPointsController.text.trim();    // user input for "App Points"

    // Validation
    // if (name.isEmpty || fee.isEmpty || description.isEmpty) {
    //   setState(() {
    //     _errorMessage =
    //         "Please fill all required fields (Name, Fee, Description).";
    //   });
    //   return;
    // }

    if (_selectedVenue == null || _selectedVenue!['id'] == null) {
      setState(() {
        _errorMessage = "Please select a valid venue.";
      });
      return;
    }

    // At least one checkbox must be selected
    if (!_useVenuePoints && !_useAppPoints) {
      setState(() {
        _errorMessage = "Please select at least one redeem type (Venue/App).";
      });
      return;
    }

    // If Venue Points is checked, ensure user enters a value
    if (_useVenuePoints && venuePoints.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the number of Venue Points.";
      });
      return;
    }

    // If App Points is checked, ensure user enters a value
    if (_useAppPoints && appPoints.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the number of App Points.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    String? token = await _getToken();
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/offers');

    try {
      // Using MultipartRequest for file upload
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['name'] = name;
      // request.fields['fee'] = fee;
      request.fields['description'] = description;
      request.fields['venue_id'] = _selectedVenue!['id'].toString();

      // Build redeem_by logic
      //   "feather_points" if only Venue Points,
      //   "venue_points" if only App Points,
      //   "feather_points,venue_points" if both
      String redeemBy = '';
      if (_useVenuePoints && _useAppPoints) {
        redeemBy = 'feather_points,venue_points';
      } else if (_useVenuePoints) {
        redeemBy = 'feather_points';
      } else if (_useAppPoints) {
        redeemBy = 'venue_points';
      }
      request.fields['redeem_by'] = redeemBy;

      // If user checked "Venue Points", we send it in "feather_points"
      if (_useVenuePoints) {
        request.fields['feather_points'] = venuePoints;
      }
      // If user checked "App Points", we send it in "venue_points"
      if (_useAppPoints) {
        request.fields['venue_points'] = appPoints;
      }

      // If user picked an image, attach it
      if (_pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image[]', // Matches your screenshot's field name
            _pickedImage!.path,
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' ||
            (responseData['message'] != null &&
                responseData['message']
                    .toString()
                    .toLowerCase()
                    .contains('success'))) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Offer added successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Dismiss dialog
                    Navigator.pop(context); // Go back to the previous screen
                  },
                  child: const Text('OK'),
                )
              ],
            ),
          );
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to add offer.';
          });
        }
      } else {
        // Handle 422 or other errors
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: '
              '${responseData['message'] ?? 'Unable to add offer.'}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add New Offer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Name of Offer
         const Text(
  "Title of Offer",
  style: TextStyle(fontSize: 16, color: Colors.black),
),
const SizedBox(height: 8),
TextField(
  controller: _nameController,
  style: const TextStyle(color: Colors.black),
  decoration: InputDecoration(
    hintText: "Enter Title of Offer",
    hintStyle: TextStyle(color: Colors.grey.shade600),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    filled: true,
    fillColor: const Color.fromARGB(255, 227, 242, 253),
    // border: OutlineInputBorder(
    //   borderRadius: BorderRadius.circular(8),
    //   borderSide: BorderSide(color: Colors.grey.shade400),
    // ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.blue.shade300),
    ),
  ),
),
            const SizedBox(height: 16),

            // Fee
            // const Text(
            //   "Fee",
            //   style: TextStyle(fontSize: 16),
            // ),
            // const SizedBox(height: 8),
            // TextField(
            //   controller: _feeController,
            //   keyboardType: TextInputType.number,
            //   decoration: InputDecoration(
            //     hintText: "Enter Fee",
            //     contentPadding:
            //         const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),

            // Venue dropdown
            const Text(
              "Venue",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: _isVenuesLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Loading venues..."),
                          ],
                        ),
                      )
                    : DropdownButton<Map<String, dynamic>>(
                        value: _selectedVenue,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _venues.map((venueMap) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: venueMap,
                            child: Text(venueMap['name'] ?? 'Unnamed'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedVenue = newValue;
                          });
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Redeem Type - using Checkboxes
            const Text(
              "Redeem Type",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("Venue Points"),
                    value: _useVenuePoints,
                    onChanged: (value) {
                      setState(() {
                        _useVenuePoints = value ?? false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("App Points"),
                    value: _useAppPoints,
                    onChanged: (value) {
                      setState(() {
                        _useAppPoints = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show "Venue Points" text field only if checked
            if (_useVenuePoints) ...[
              const Text(
                "Venue Points (sends as feather_points)",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _venuePointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter Venue Points",
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Show "App Points" text field only if checked
            if (_useAppPoints) ...[
              const Text(
                "App Points (sends as venue_points)",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _appPointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter App Points",
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            const Text(
              "Description",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Pictures
            const Text(
              "Upload Pictures",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _pickedImage == null
                ? Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 30),
                      onPressed: _pickImage,
                    ),
                  )
                : InkWell(
                    onTap: _pickImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_pickedImage!.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
            const SizedBox(height: 80),

            // Show error message if any
            if (_errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isSubmitting ? null : _submitOffer,
            child: _isSubmitting
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}



