import 'dart:convert';
import 'dart:io';
import 'package:flock/constants.dart';
import 'package:flock/venue.dart' show Design;
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venuePointsController = TextEditingController();
  final TextEditingController _appPointsController = TextEditingController();
  final TextEditingController _redemptionLimitController = TextEditingController();

  List<Map<String, dynamic>> _venues = [
    {'id': null, 'name': 'Select Venue'},
  ];
  Map<String, dynamic>? _selectedVenue;

  bool _useVenuePoints = false;
  bool _useAppPoints = false;

  XFile? _pickedImage;

  bool _isVenuesLoading = false;
  bool _isSubmitting = false;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedVenue = _venues.first;
    _fetchVenues();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _venuePointsController.dispose();
    _appPointsController.dispose();
    _redemptionLimitController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

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

    final url = Uri.parse('http://165.232.152.77/api/vendor/venues');

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
            {'id': null, 'name': 'Select Venue'},
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
          _errorMessage = 'Error ${response.statusCode}: Unable to fetch venues.';
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToError();
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final venuePoints = _venuePointsController.text.trim();
    final appPoints = _appPointsController.text.trim();
    final redemptionLimit = _redemptionLimitController.text.trim();

    int? redemptionLimitValue;
    if (redemptionLimit.isEmpty) {
      redemptionLimitValue = -1;
    } else {
      redemptionLimitValue = int.tryParse(redemptionLimit);
      if (redemptionLimitValue == null || redemptionLimitValue < -1) {
        setState(() {
          _errorMessage = "Please enter a valid redemption limit (-1 for unlimited).";
        });
        _scrollToError();
        return;
      }
    }

    if (_selectedVenue == null || _selectedVenue!['id'] == null) {
      setState(() {
        // _errorMessage = "Please select a valid venue.";
      });
      _scrollToError();
      return;
    }

    if (!_useVenuePoints && !_useAppPoints) {
      setState(() {
        _errorMessage = "Please select at least one redeem type (Venue/App).";
      });
      _scrollToError();
      return;
    }

    if (_useVenuePoints && venuePoints.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the number of Venue Points.";
      });
      _scrollToError();
      return;
    }

    if (_useAppPoints && appPoints.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the number of App Points.";
      });
      _scrollToError();
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

    final url = Uri.parse('http://165.232.152.77/api/vendor/offers');

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['venue_id'] = _selectedVenue!['id'].toString();

      String redeemBy = '';
      if (_useVenuePoints && _useAppPoints) {
        redeemBy = 'both';
      } else if (_useVenuePoints) {
        redeemBy = 'venue_points';
      } else if (_useAppPoints) {
        redeemBy = 'feather_points';
      }
      request.fields['redeem_by'] = redeemBy;

      if (_useVenuePoints) {
        request.fields['venue_points'] = venuePoints;
      }
      if (_useAppPoints) {
        request.fields['feather_points'] = appPoints;
      }
      request.fields['redemption_limit'] = redemptionLimitValue.toString();

      if (_pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            _pickedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' ||
            (responseData['message'] != null &&
                responseData['message'].toString().toLowerCase().contains('success'))) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Offer added successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to add offer.';
          });
          _scrollToError();
        }
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              'Error ${response.statusCode}: ${responseData['message'] ?? 'Unable to add offer.'}';
        });
        _scrollToError();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
      _scrollToError();
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  void _scrollToError() {
    final context = _formKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppConstants.customAppBar(
        context: context,
        title: 'Add New Offer',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Title of Offer",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 8),
              AppConstants.customTextField(
                controller: _nameController,
                hintText: 'Enter Title of Offer',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the title of the offer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text("Venue", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _isVenuesLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 10,
                              width: 20,
                              child: Stack(
                                children: [
                                  Container(
                                    color: Colors.black.withOpacity(0.14),
                                  ),
                                  Container(
                                    color: Colors.white10,
                                    child: Center(
                                      child: Image.asset(
                                        'assets/Bird_Full_Eye_Blinking.gif',
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Loading venues...",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14.0,
                                fontFamily: 'YourFontFamily',
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<Map<String, dynamic>>(
                            value: _selectedVenue,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: Design.primaryColorOrange,
                              size: 22,
                            ),
                            hint: Text(
                              "Select Venue",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14.0,
                                fontFamily: 'YourFontFamily',
                              ),
                            ),
                            items: _venues.map((venueMap) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: venueMap,
                                child: Text(
                                  venueMap['name'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14.0,
                                    fontFamily: 'YourFontFamily',
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedVenue = newValue;
                              });
                            },
                            underline: Container(),
                            dropdownColor: Colors.white,
                            itemHeight: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(10),
                            elevation: 3,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              const Text("Redeem Type", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        activeColor: const Color.fromRGBO(255, 130, 16, 1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        value: _useVenuePoints,
                        onChanged: (value) {
                          setState(() {
                            _useVenuePoints = value ?? false;
                          });
                        },
                      ),
                      const Text("Venue Points"),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        activeColor: const Color.fromRGBO(255, 130, 16, 1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        value: _useAppPoints,
                        onChanged: (value) {
                          setState(() {
                            _useAppPoints = value ?? false;
                          });
                        },
                      ),
                      const Text("App Points"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (_useVenuePoints || _useAppPoints)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_useVenuePoints)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _venuePointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter Venue Points",
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (_useVenuePoints && (value == null || value.isEmpty)) {
                                  return 'Please enter Venue Points';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    if (_useVenuePoints && _useAppPoints)
                      const SizedBox(width: 16),
                    if (_useAppPoints)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _appPointsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter App Points",
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (_useAppPoints && (value == null || value.isEmpty)) {
                                  return 'Please enter App Points';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (_useVenuePoints || _useAppPoints) const SizedBox(height: 16),
              const Text("Description", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Redemption Limit  ",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    TextSpan(
                      text: "(Leave Blank for unlimited)",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppConstants.customTextField(
                controller: _redemptionLimitController,
                hintText: 'Enter Redemption Limit',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsedValue = int.tryParse(value);
                    if (parsedValue == null || parsedValue < -1) {
                      return 'Please enter a valid redemption limit (-1 for unlimited)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text("Upload Pictures", style: TextStyle(fontSize: 16)),
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
                        icon: const Icon(Icons.camera_alt, size: 50),
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
              if (_errorMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(255, 130, 16, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isSubmitting ? null : _submitOffer,
            child: _isSubmitting
                ? Container(
                    color: Colors.white.withOpacity(0.19),
                    child: Center(
                      child: Image.asset(
                        'assets/Bird_Full_Eye_Blinking.gif',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  )
                : const Text(
                    "Save Offer",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}