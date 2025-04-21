import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Define your design tokens. Adjust these values as needed.
class Design {
  static const Color lightPurple = Colors.white;
  static const Color primaryColorOrange = Color.fromRGBO(255, 130, 16, 1);

  static var font14;

  static var white;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Screen Demo',
      debugShowCheckedModeBanner: false,
theme: ThemeData(
  primaryColor: const Color.fromRGBO(255, 130, 16, 1),
),      home: const ReportScreen(),
    );
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// We'll store venues as a list of maps: [{'id': 65, 'name': 'Venue Name'}, ...]
  List<Map<String, dynamic>> _venues = [];

  /// The selected venue object (with id & name)
  Map<String, dynamic>? _selectedVenue;

  /// We'll store report types as a list of strings (e.g. ['Boost', 'Complaint', ...])
  List<String> _reportTypes = [];
  String? _selectedReportType;

  // Controls for the custom dropdowns.
  bool _showVenueDropdown = false;
  bool _showReportTypeDropdown = false;

  final TextEditingController _descriptionController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVenues();
    _fetchReportTypes();
  }

  /// Retrieve the token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch the list of venues from the API
  Future<void> _fetchVenues() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'No token found. Please login again.';
      });
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
          final List<dynamic> venueData = data['data'];
          setState(() {
            _venues =
                venueData
                    .map(
                      (venue) => {
                        'id': venue['id'],
                        'name': venue['name']?.toString() ?? 'Unnamed Venue',
                      },
                    )
                    .toList();
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load venues.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode} loading venues.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }
  }

  /// Fetch the list of report types from the API
  Future<void> _fetchReportTypes() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'No token found. Please login again.';
      });
      return;
    }

    final url = Uri.parse('http://165.232.152.77/api/vendor/report-types');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Debug print the response to check structure
        print("Report types API response: ${response.body}");
        final data = json.decode(response.body);

        // Check if the response is a map with a key 'data'
        if (data is Map &&
            data['status'] == 'success' &&
            data['data'] != null) {
          final List<dynamic> reportTypeData = data['data'];
          setState(() {
            _reportTypes =
                reportTypeData.map((rt) => rt['label'].toString()).toList();
          });
        } else if (data is List) {
          // If the API returns a plain list
          setState(() {
            _reportTypes = data.map((rt) => rt['label'].toString()).toList();
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load report types.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode} loading report types.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }
  }

  /// Handle form submission
  Future<void> _submitReport() async {
    if (_selectedVenue == null) {
      setState(() {
        _errorMessage = 'Please select a venue.';
      });
      return;
    }
    if (_selectedReportType == null) {
      setState(() {
        _errorMessage = 'Please select a report type.';
      });
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a description.';
      });
      return;
    }

    setState(() => _errorMessage = '');

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'No token found. Please login again.';
      });
      return;
    }

    final url = Uri.parse('http://165.232.152.77/api/vendor/feedbacks');
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['venue_id'] = _selectedVenue!['id'].toString();
      request.fields['report_type'] = _selectedReportType ?? '';
      request.fields['description'] = _descriptionController.text.trim();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Report submitted!'),
            ),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Failed to submit report.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }
  }

  /// Custom Venue Dropdown Widget (same as before)
  Widget customVenueDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        // Box shadow for a subtle elevation effect.
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showVenueDropdown = !_showVenueDropdown;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Design.lightPurple,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedVenue == null
                        ? "Select Venue"
                        : _selectedVenue!['name'] ?? "Select Venue",
                    style: const TextStyle(fontSize: 15),
                  ),
                  Icon(
                    _showVenueDropdown
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_showVenueDropdown)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
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
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _venues.length,
                        itemBuilder: (context, index) {
                          final venue = _venues[index];
                          final isSelected =
                              _selectedVenue != null &&
                              _selectedVenue!['id'].toString() ==
                                  venue['id'].toString();
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedVenue = venue;
                                _showVenueDropdown = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              color:
                                  isSelected
                                      ? Design.primaryColorOrange.withOpacity(
                                        0.1,
                                      )
                                      : Colors.transparent,
                              child: Text(
                                venue['name'] ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SizedBox(
                      width: double.infinity,
                      // child: ElevatedButton(
                      //   onPressed: () {
                      //     setState(() {
                      //       _showVenueDropdown = false;
                      //     });
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Design.primaryColorOrange,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(5),
                      //     ),
                      //     padding: const EdgeInsets.symmetric(vertical: 8),
                      //   ),
                      //   child: const Text(
                      //     "Done",
                      //     style: TextStyle(color: Colors.white),
                      //   ),
                      // ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Custom Report Type Dropdown Widget with similar styling as the venue dropdown.
  Widget customReportTypeDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        // Same box shadow.
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showReportTypeDropdown = !_showReportTypeDropdown;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Design.lightPurple,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedReportType == null
                        ? "Select Report Type"
                        : _selectedReportType!,
                    style: const TextStyle(fontSize: 15),
                  ),
                  Icon(
                    _showReportTypeDropdown
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_showReportTypeDropdown)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
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
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _reportTypes.length,
                        itemBuilder: (context, index) {
                          final rt = _reportTypes[index];
                          final isSelected =
                              _selectedReportType != null &&
                              _selectedReportType == rt;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedReportType = rt;
                                _showReportTypeDropdown = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              color:
                                  isSelected
                                      ? Design.primaryColorOrange.withOpacity(
                                        0.1,
                                      )
                                      : Colors.transparent,
                              child: Text(
                                rt,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SizedBox(
                      width: double.infinity,
                      // child: ElevatedButton(
                      //   onPressed: () {
                      //     setState(() {
                      //       _showReportTypeDropdown = false;
                      //     });
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Design.primaryColorOrange,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(5),
                      //     ),
                      //     padding: const EdgeInsets.symmetric(vertical: 8),
                      //   ),
                      //   child: const Text(
                      //     "Done",
                      //     style: TextStyle(color: Colors.white),
                      //   ),
                      // ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Image.asset(
                        'assets/back_updated.png',
                        height: 40,
                        width: 34,
                        fit: BoxFit.contain,
                        // color: const Color.fromRGBO(255, 130, 16, 1.0), // Orange tint
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Report",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 20),
                // Subtitle
                // const Text(
                //   "Enter Details",
                //   style: TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                const SizedBox(height: 16),
                // "Choose venue" label
                const Text(
                  "Choose venue",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                // Custom Venue Dropdown
                customVenueDropdown(),
                const SizedBox(height: 16),
                // "Choose report type" label
                const Text(
                  "Choose report type",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                // Custom Report Type Dropdown
                customReportTypeDropdown(),
                const SizedBox(height: 16),
                // "Description" label
                const Text("Description", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                // Multiline TextField for Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "",
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Show any error messages
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(255, 130, 16, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
