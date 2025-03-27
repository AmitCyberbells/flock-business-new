import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenHoursScreen extends StatefulWidget {
  const OpenHoursScreen({Key? key}) : super(key: key);

  @override
  State<OpenHoursScreen> createState() => _OpenHoursScreenState();
}

class _OpenHoursScreenState extends State<OpenHoursScreen> {
  // List of venues fetched from API. Each venue: { 'id': <int>, 'name': <String> }
  List<Map<String, dynamic>> _venues = [];

  // Currently selected venue
  Map<String, dynamic>? _selectedVenue;

  // Opening hours data for the selected venue.
  // Default local values for 7 days.
  List<Map<String, dynamic>> _days = [
    {"day": "Mon", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Tue", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Wed", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Thu", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Fri", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Sat", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Sun", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
  ];

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVenues();
  }

  /// Retrieve token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch the list of venues from the API
  Future<void> _fetchVenues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'No token found. Please login again.';
        _isLoading = false;
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
          List<Map<String, dynamic>> loadedVenues = venueData.map((v) {
            return {
              'id': v['id'],
              'name': v['name'] ?? 'Unnamed Venue',
            };
          }).toList();
          setState(() {
            _venues = loadedVenues;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load venues.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Error ${response.statusCode}: Unable to fetch venues.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  /// Fetch existing opening hours for the selected venue (GET).
  Future<void> _fetchOpeningHours(int venueId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'No token found. Please login again.';
        _isLoading = false;
      });
      return;
    }
    final url = Uri.parse(
      'http://165.232.152.77/mobi/api/vendor/venues/$venueId/opening-hours',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> hoursData = data['data'];
          final Map<String, String> dayMap = {
            "Monday": "Mon",
            "Tuesday": "Tue",
            "Wednesday": "Wed",
            "Thursday": "Thu",
            "Friday": "Fri",
            "Saturday": "Sat",
            "Sunday": "Sun",
          };
          List<Map<String, dynamic>> updatedDays = [];
          for (var item in hoursData) {
            final serverDay = item['day'] ?? '';
            final localDay = dayMap[serverDay] ?? serverDay;
            final openTime = item['open'] ?? '00:00';
            final closeTime = item['close'] ?? '00:00';
            bool isOpen = (openTime != '00:00' || closeTime != '00:00');
            updatedDays.add({
              "day": localDay,
              "isOpen": isOpen,
              "openTime": openTime,
              "closeTime": closeTime,
            });
          }
          // Ensure all 7 days are present
          for (var d in _days) {
            final exists = updatedDays.any((ud) => ud["day"] == d["day"]);
            if (!exists) {
              updatedDays.add(d);
            }
          }
          // Sort by the order of Mon, Tue, ... Sun.
          final order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
          updatedDays.sort((a, b) =>
              order.indexOf(a["day"]) - order.indexOf(b["day"]));
          setState(() {
            _days = updatedDays;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load opening hours.';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Error ${response.statusCode}: Unable to fetch hours.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  /// Save updated opening hours for the selected venue using form-data.
  /// 
Future<void> _saveOpeningHours() async {
  if (_selectedVenue == null) {
    setState(() {
      _errorMessage = 'Please select a venue first.';
    });
    return;
  }
  final venueId = _selectedVenue!['id'];
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });
  final token = await _getToken();
  if (token == null || token.isEmpty) {
    setState(() {
      _errorMessage = 'No token found. Please login again.';
      _isLoading = false;
    });
    return;
  }

  final Map<String, String> dayMap = {
    "Mon": "Monday",
    "Tue": "Tuesday",
    "Wed": "Wednesday",
    "Thu": "Thursday",
    "Fri": "Friday",
    "Sat": "Saturday",
    "Sun": "Sunday",
  };

  final url = Uri.parse(
    'http://165.232.152.77/mobi/api/vendor/venues/$venueId/opening-hours',
  );
  final request = http.MultipartRequest('POST', url);
  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'application/json';

  for (int i = 0; i < _days.length; i++) {
    final d = _days[i];
    final String serverDay = dayMap[d["day"]] ?? d["day"];
    final String openT = d["isOpen"] ? d["openTime"].toString() : "00:00";
    final String closeT = d["isOpen"] ? d["closeTime"].toString() : "00:00";

    request.fields['opening_hours[$i][day]'] = serverDay;
    request.fields['opening_hours[$i][start_time]'] = openT;  // Already corrected
    request.fields['opening_hours[$i][end_time]'] = closeT;   // Changed from 'close' to 'end_time'
  }

  try {
    print('Request fields: ${request.fields}');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    setState(() {
      _isLoading = false;
    });

    print('Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Hours updated successfully!'),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to update hours.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Error ${response.statusCode}: ${response.body}';
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Network error: $e';
    });
  }
}
  @override

Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView( // Wrap Column in SingleChildScrollView
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Open Hours",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Venue dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedVenue,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        hint: const Text("Select a venue"),
                        items: _venues.map((v) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: v,
                            child: Text(v['name'] ?? 'Unnamed Venue'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedVenue = newValue;
                          });
                          if (newValue != null) {
                            _fetchOpeningHours(newValue['id']);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error message with constrained height
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 100), // Limit height
                      child: SingleChildScrollView(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),

                // List of days
                SizedBox(
                  height: 400, // Fixed height for ListView
                  child: ListView.builder(
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      final dayInfo = _days[index];
                      return _buildDayRow(dayInfo, index);
                    },
                  ),
                ),

                // Save button at bottom
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saveOpeningHours,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.white54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}

  Widget _buildDayRow(Map<String, dynamic> dayInfo, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                dayInfo["day"],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Switch(
              value: dayInfo["isOpen"],
              activeColor: Colors.orange,
              onChanged: (value) {
                setState(() {
                  _days[index]["isOpen"] = value;
                  if (!value) {
                    _days[index]["openTime"] = "00:00";
                    _days[index]["closeTime"] = "00:00";
                  }
                });
              },
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayInfo["openTime"]),
                  const Text(" - "),
                  Text(dayInfo["closeTime"]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.access_time, color: Colors.orange),
              onPressed: () {
                _showDayDialog(dayInfo["day"], index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDialog(String day, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempOpen = _days[index]["openTime"];
        String tempClose = _days[index]["closeTime"];
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _parseTimeOfDay(tempOpen),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            tempOpen = picked.format(context);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Set Opening Time: $tempOpen"),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _parseTimeOfDay(tempClose),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            tempClose = picked.format(context);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Set Closing Time: $tempClose"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _days[index]["openTime"] =
                                    _convertTo24HrFormat(tempOpen);
                                _days[index]["closeTime"] =
                                    _convertTo24HrFormat(tempClose);
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("OK"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    // If "HH:MM" in 24h, parse directly
    if (timeStr.contains(':') && !timeStr.contains('AM') && !timeStr.contains('PM')) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } else {
      // default
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _convertTo24HrFormat(String timeStr) {
    // If already "HH:MM" 24h, just return
    if (timeStr.contains(':') && !timeStr.contains('AM') && !timeStr.contains('PM')) {
      return timeStr;
    }
    try {
      final parts = timeStr.split(' ');
      final hhmm = parts[0].split(':');
      int hour = int.parse(hhmm[0]);
      final minute = int.parse(hhmm[1]);
      final ampm = parts[1].toUpperCase();
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      final hourStr = hour.toString().padLeft(2, '0');
      final minStr = minute.toString().padLeft(2, '0');
      return '$hourStr:$minStr';
    } catch (_) {
      return '00:00';
    }
  }
}



