import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// We'll store venues as a list of maps: [{'id': 65, 'name': 'Venue Name'}, ...]
  List<Map<String, dynamic>> _venues = [];
  /// We'll store the selected venue object (with id & name)
  Map<String, dynamic>? _selectedVenue;

  /// We'll store report types as a list of strings (e.g. ['Boost', 'Complaint', ...])
  /// If your API also provides an ID for each report type, you can store it similarly to venues.
  List<String> _reportTypes = [];
  String? _selectedReportType;

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
          final List<dynamic> venueData = data['data'];
          setState(() {
            // Instead of just storing names, store a map with { 'id': ..., 'name': ... }
            _venues = venueData
                .map((venue) => {
                      'id': venue['id'],
                      'name': venue['name']?.toString() ?? 'Unnamed Venue',
                    })
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

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/report-types');
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
          final List<dynamic> reportTypeData = data['data'];
          setState(() {
            // Convert each object into the "label" string
            _reportTypes = reportTypeData
                .map((rt) => rt['label'].toString())
                .toList();
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

    // The API endpoint from your screenshot
    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/feedbacks');

    try {
      // We'll send multipart/form-data just like your screenshot
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Fill out the fields
      request.fields['venue_id'] = _selectedVenue!['id'].toString();
      request.fields['report_type'] = _selectedReportType ?? '';
      request.fields['description'] = _descriptionController.text.trim();

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Report submitted successfully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Report submitted!')),
          );
          Navigator.pop(context); // Return to previous screen or do whatever
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to submit report.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Matches your screenshot
      body: SafeArea(
        child: SingleChildScrollView(
          // Ensures screen is scrollable if content grows
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
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Report",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subtitle
                const Text(
                  "Enter Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // "Choose venue" label
                const Text(
                  "Choose venue",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),

                // Venue Dropdown
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: const Text("Choose Venue"),
                  value: _selectedVenue,
                  items: _venues.map((venue) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: venue,
                      child: Text(venue['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVenue = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // "Choose report type" label
                const Text(
                  "Choose report type",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),

                // Report Type Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: const Text("Choose report type"),
                  value: _selectedReportType,
                  items: _reportTypes.map((reportType) {
                    return DropdownMenuItem<String>(
                      value: reportType,
                      child: Text(reportType),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReportType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // "Description" label
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),

                // Multiline TextField for Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "",
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Show any error messages from the fetch calls or validations
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
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
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
