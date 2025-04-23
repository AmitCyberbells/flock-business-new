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
  final TextEditingController _redemptionLimitController =
      TextEditingController();


  List<Map<String, dynamic>> _venues = [
    {'id': null, 'name': 'Select Venue'},
  ];
  Map<String, dynamic>? _selectedVenue;


  bool _useVenuePoints = false;
  bool _useAppPoints = false;
  bool _useFreeOffer = false;


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


  /* ─────────────────────────── Helpers ─────────────────────────── */


  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }


  Future<void> _fetchVenues() async {
    setState(() {
      _isVenuesLoading = true;
      _errorMessage = '';
    });


    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }


    try {
      final response = await http.get(
        Uri.parse('http://165.232.152.77/api/vendor/venues'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> venuesData = data['data'];
          _venues = [
            {'id': null, 'name': 'Select Venue'},
            ...venuesData.map(
              (v) => {'id': v['id'], 'name': v['name'] ?? 'Unnamed Venue'},
            ),
          ];
          _selectedVenue = _venues.first;
        } else {
          _errorMessage = data['message'] ?? 'Failed to load venues.';
        }
      } else {
        _errorMessage =
            'Error ${response.statusCode}: Unable to fetch venues.';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }


    if (mounted) setState(() => _isVenuesLoading = false);
  }


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }


  /* ───────────────────────── Validation & Submit ───────────────────────── */


  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToError();
      return;
    }


    // Shortcuts (made mutable so we can override for Free Offer)
    var venuePoints = _venuePointsController.text.trim();
    var appPoints = _appPointsController.text.trim();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final redemptionLimit = _redemptionLimitController.text.trim();


    // Redemption-limit parsing
    int redemptionLimitValue = -1;
    if (redemptionLimit.isNotEmpty) {
      redemptionLimitValue = int.tryParse(redemptionLimit) ?? -2;
      if (redemptionLimitValue < -1) {
        _errorMessage =
            "Please enter a valid redemption limit (-1 for unlimited).";
        _scrollToError();
        return;
      }
    }


    // Venue check
    if (_selectedVenue == null || _selectedVenue!['id'] == null) {
      _errorMessage = "Please select a valid venue.";
      _scrollToError();
      return;
    }


    // Redeem type checks
    if (!_useFreeOffer && !_useVenuePoints && !_useAppPoints) {
      _errorMessage =
          "Please select at least one redeem type (Venue Points, Feathers, or Free Offer).";
      _scrollToError();
      return;
    }


    /* ── Validation rules for points ── */
    if (_useFreeOffer) {
      venuePoints = '0';
      appPoints = '0';
    } else {
      if (_useVenuePoints) {
        if (venuePoints.isEmpty) {
          _errorMessage = "Please enter the number of Venue Points.";
          _scrollToError();
          return;
        }
        final vp = int.tryParse(venuePoints);
        if (vp == null || vp < 5) {
          _errorMessage = "Venue Points must be at least 5.";
          _scrollToError();
          return;
        }
      }


      if (_useAppPoints) {
        if (appPoints.isEmpty) {
          _errorMessage = "Please enter the number of Feathers.";
          _scrollToError();
          return;
        }
        final ap = int.tryParse(appPoints);
        if (ap == null || ap < 5) {
          _errorMessage = "Feathers must be at least 5.";
          _scrollToError();
          return;
        }
      }
    }


    /* ── Ready to submit ── */
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });


    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }


    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://165.232.152.77/api/vendor/offers'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['venue_id'] = _selectedVenue!['id'].toString();


    /* ── redeem_by mapping ── */
    String redeemBy = 'both';
    if (!_useFreeOffer) {
      if (_useVenuePoints && _useAppPoints) {
        redeemBy = 'both';
      } else if (_useVenuePoints) {
        redeemBy = 'venue_points';
      } else if (_useAppPoints) {
        redeemBy = 'feather_points';
      }
    }
    request.fields['redeem_by'] = redeemBy;


    /* ── always send both fields ── */
    request.fields['venue_points'] = venuePoints;
    request.fields['feather_points'] = appPoints;
    request.fields['redemption_limit'] = redemptionLimitValue.toString();


    if (_pickedImage != null) {
      request.files
          .add(await http.MultipartFile.fromPath('images[]', _pickedImage!.path));
    }


    try {
      final response = await http.Response.fromStream(await request.send());


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' ||
            (data['message'] ?? '')
                .toString()
                .toLowerCase()
                .contains('success')) {
          if (mounted) {
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
          }
        } else {
          _errorMessage = data['message'] ?? 'Failed to add offer.';
          _scrollToError();
        }
      } else {
        final data = jsonDecode(response.body);
        _errorMessage =
            'Error ${response.statusCode}: ${data['message'] ?? 'Unable to add offer.'}';
        _scrollToError();
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      _scrollToError();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  void _scrollToError() {
    final ctx = _formKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }


  /* ─────────────────────────── UI ─────────────────────────── */


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
              /* Title */
              const Text("Title of Offer", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              AppConstants.customTextField(
                controller: _nameController,
                hintText: 'Title of Offer',
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter the title' : null,
              ),


              /* Venue dropdown */
              const SizedBox(height: 16),
              const Text("Venue", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              _buildVenueDropdown(),


              /* Redeem Type */
              const SizedBox(height: 16),
              const Text("Redemption Requirements",
                  style: TextStyle(fontSize: 16)),
              _buildRedeemTypeRow(),


              /* Points fields */
              if (!_useFreeOffer && (_useVenuePoints || _useAppPoints))
                ...[
                  _buildPointsInputs(),
                  const SizedBox(height: 16),
                ],


              /* Description */
              const Text("Description", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              _buildDescriptionField(),


              /* Redemption limit */
              const SizedBox(height: 16),
              _buildRedemptionLimit(),


              /* Image picker */
              const SizedBox(height: 16),
              _buildImagePicker(),


              const SizedBox(height: 80),
              if (_errorMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
      /* Save button */
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


  /* ─────────────────────────── Widget Builders ─────────────────────────── */


  Widget _buildVenueDropdown() {
    return Container(
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
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 10,
                    width: 20,
                    child: Stack(
                      children: [
                        Container(color: Colors.black.withOpacity(0.14)),
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
                  const Text("Loading venues...",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedVenue,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Design.primaryColorOrange, size: 22),
                  items: _venues
                      .map((v) => DropdownMenuItem<Map<String, dynamic>>(
                            value: v,
                            child: Text(v['name'] ?? 'Unnamed',
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedVenue = v),
                  dropdownColor: Colors.white,
                  itemHeight: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  borderRadius: BorderRadius.circular(10),
                  elevation: 3,
                ),
              ),
            ),
    );
  }


  Widget _buildRedeemTypeRow() {
    Color _labelColor(bool enabled) =>
        enabled ? Colors.black : Colors.grey.shade500;


    return Wrap(
      spacing: 24,
      runSpacing: -15,
      children: [
        /* Free Offer */
        Transform.translate(
          offset: const Offset(-8, -6),
          child: Padding(
            padding: const EdgeInsets.only(left: 0, top: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  activeColor: const Color.fromRGBO(255, 130, 16, 1),
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                  value: _useFreeOffer,
                  onChanged: (v) {
                    setState(() {
                      _useFreeOffer = v ?? false;
                      if (_useFreeOffer) {
                        _useVenuePoints = false;
                        _useAppPoints = false;
                        _venuePointsController.text = '0';
                        _appPointsController.text = '0';
                      }
                    });
                  },
                ),
                const Text(
                  "Free Offer (No points required)",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),


        /* Venue Points */
        Transform.translate(
          offset: const Offset(-8, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                activeColor: const Color.fromRGBO(255, 130, 16, 1),
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                value: _useVenuePoints,
                onChanged: _useFreeOffer
                    ? null
                    : (v) => setState(() => _useVenuePoints = v ?? false),
              ),
              Text("Venue Points",
                  style: TextStyle(color: _labelColor(!_useFreeOffer))),
            ],
          ),
        ),


        /* Feathers */
        Transform.translate(
          offset: const Offset(12, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                activeColor: const Color.fromRGBO(255, 130, 16, 1),
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                value: _useAppPoints,
                onChanged: _useFreeOffer
                    ? null
                    : (v) => setState(() => _useAppPoints = v ?? false),
              ),
              Text("Feathers",
                  style: TextStyle(color: _labelColor(!_useFreeOffer))),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildPointsInputs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_useVenuePoints)
          Expanded(
            child: TextFormField(
              controller: _venuePointsController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Venue Points (min 5)"),
              validator: (v) {
                if (_useFreeOffer) return null;
                if (_useVenuePoints) {
                  if (v == null || v.isEmpty) return 'Venue Points';
                  final p = int.tryParse(v);
                  if (p == null || p < 5) return 'Min 5 points';
                }
                return null;
              },
            ),
          ),
        if (_useVenuePoints && _useAppPoints) const SizedBox(width: 16),
        if (_useAppPoints)
          Expanded(
            child: TextFormField(
              controller: _appPointsController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Feathers (min 5)"),
              validator: (v) {
                if (_useFreeOffer) return null;
                if (_useAppPoints) {
                  if (v == null || v.isEmpty) return 'Feathers';
                  final p = int.tryParse(v);
                  if (p == null || p < 5) return 'Min 5 feathers';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }


  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );


  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: "Offer description",
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: InputBorder.none,
        ),
        validator: (v) =>
            v == null || v.isEmpty ? 'Please enter a description' : null,
      ),
    );
  }


  Widget _buildRedemptionLimit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: "Redemption Limit  ",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              TextSpan(
                text: "(Leave blank for unlimited)",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppConstants.customTextField(
          controller: _redemptionLimitController,
          hintText: 'Redemption Limit',
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v != null && v.isNotEmpty) {
              final p = int.tryParse(v);
              if (p == null || p < -1) {
                return 'Invalid redemption limit';
              }
            }
            return null;
          },
        ),
      ],
    );
  }


  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}





