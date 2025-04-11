import 'dart:convert';
import 'package:flock/feedback.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OpenHoursScreen extends StatefulWidget {
  const OpenHoursScreen({Key? key}) : super(key: key);

  @override
  State<OpenHoursScreen> createState() => _OpenHoursScreenState();
}

class _OpenHoursScreenState extends State<OpenHoursScreen> {
  List<Map<String, dynamic>> _venues = [];
  Map<String, dynamic>? _selectedVenue;

  // _baseDays now includes an "updated" flag.
  final List<Map<String, dynamic>> _baseDays = [
    {
      "day": "Mon",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
    {
      "day": "Tue",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
    {
      "day": "Wed",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
    {
      "day": "Thu",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
    {
      "day": "Fri",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
    {
      "day": "Sat",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
    {
      "day": "Sun",
      "isOpen": false,
      "openTime": "12:00 AM",
      "closeTime": "12:00 AM",
      "updated": false,
    },
  ];

  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _days = _baseDays.map((e) => Map<String, dynamic>.from(e)).toList();
    _fetchVenues();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

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
          List<Map<String, dynamic>> loadedVenues =
              venueData.map((v) {
                return {'id': v['id'], 'name': v['name'] ?? 'Unnamed Venue'};
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

    // ✅ Auto-select the first venue
    if (_venues.isNotEmpty && _selectedVenue == null) {
      setState(() {
        _selectedVenue = _venues.first;
        _fetchOpeningHours(_selectedVenue!['id']);
      });
    }
  }

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
      'http://165.232.152.77/api/vendor/venues/$venueId/opening-hours',
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

          List<Map<String, dynamic>> updatedDays =
              _baseDays.map((e) => Map<String, dynamic>.from(e)).toList();

          for (var item in hoursData) {
            final serverDay = item['start_day'] ?? '';
            final localDay = dayMap[serverDay] ?? serverDay;
            final openTime = item['start_time'] ?? '00:00';
            final closeTime = item['end_time'] ?? '00:00';
            bool isOpen = (openTime != '00:00' || closeTime != '00:00');
            final bool isUpdated = item['updated_at'] != null;

            final index = updatedDays.indexWhere((d) => d['day'] == localDay);
            if (index != -1) {
              updatedDays[index] = {
                "day": localDay,
                "isOpen": isOpen,
                "openTime": _convertTo12HrFormat(openTime),
                "closeTime": _convertTo12HrFormat(closeTime),
                "updated": isUpdated,
              };
            }
          }

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
      'http://165.232.152.77/api/vendor/venues/$venueId/opening-hours',
    );
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    for (int i = 0; i < _days.length; i++) {
      final d = _days[i];
      final String serverDay = dayMap[d["day"]] ?? d["day"];
      final String openT = d["isOpen"] ? d["openTime"].toString() : "12:00 AM";
      final String closeT =
          d["isOpen"] ? d["closeTime"].toString() : "12:00 AM";
      final String status = d["isOpen"] ? "1" : "0";

      request.fields['opening_hours[$i][day]'] = serverDay;
      request.fields['opening_hours[$i][start_time]'] = openT;
      request.fields['opening_hours[$i][end_time]'] = closeT;
      request.fields['opening_hours[$i][status]'] = status;
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

  String _convertTo12HrFormat(String time24) {
    try {
      if (time24.toLowerCase().contains('am') ||
          time24.toLowerCase().contains('pm')) {
        return time24;
      }
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final hourStr = hour.toString().padLeft(2, '0');
      final minStr = minute.toString().padLeft(2, '0');
      return "$hourStr:$minStr $period";
    } catch (_) {
      return "12:00 AM";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color.fromRGBO(255, 130, 16, 1.0),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Open Hours",
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
                  ),
                  const SizedBox(height: 24),
                  // Venue dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: InkWell(
                      onTap: _showVenueSelectionDialog,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedVenue?['name'] ?? 'Select a venue',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
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
                    height: 520,
                    child: ListView.builder(
                      itemCount: _days.length,
                      itemBuilder: (context, index) {
                        final dayInfo = _days[index];
                        return _buildDayRow(dayInfo, index);
                      },
                    ),
                  ),
                  // Save button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
              color: Colors.white.withOpacity(0.19),
              child: Center(
                child: Image.asset(
                  'assets/Bird_Full_Eye_Blinking.gif',
                  width: 100, // Adjust size as needed
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showVenueSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Select Venue",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: ListView.builder(
              itemCount: _venues.length,
              itemBuilder: (context, index) {
                final venue = _venues[index];
                final isSelected = _selectedVenue?['id'] == venue['id'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVenue = venue;
                      _fetchOpeningHours(venue['id']);
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    color:
                        isSelected
                            ? Design.primaryColorOrange.withOpacity(0.1)
                            : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue['name'] ?? 'Unnamed Venue',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: Design.primaryColorOrange,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dayInfo, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(dayInfo["day"], style: const TextStyle(fontSize: 16)),
            ),
            SizedBox(
              width: 60,
              child: Container(
                alignment: Alignment.center,
                child: Switch(
                  value: dayInfo["isOpen"],
                  activeColor:
                      dayInfo["updated"] == true ? Colors.green : Colors.orange,
                  onChanged: (value) {
                    setState(() {
                      _days[index]["isOpen"] = value;
                      if (!value) {
                        _days[index]["openTime"] = "12:00 AM";
                        _days[index]["closeTime"] = "12:00 AM";
                      }
                      _days[index]["updated"] = false;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayInfo["openTime"],
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Text(" - "),
                  Text(
                    dayInfo["closeTime"],
                    style: const TextStyle(fontSize: 14),
                  ),
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

  Future<void> _showDayDialog(String day, int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String tempOpen = _days[index]["openTime"];
        String tempClose = _days[index]["closeTime"];
        bool applyToAllDays = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(day),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _parseTimeOfDay(tempOpen),
                        initialEntryMode: TimePickerEntryMode.input,
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          tempOpen = _formatTo12Hour(picked);
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
                        initialEntryMode: TimePickerEntryMode.input,
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          tempClose = _formatTo12Hour(picked);
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
                      Checkbox(
                        value: applyToAllDays,
                        onChanged: (bool? value) {
                          setStateDialog(() {
                            applyToAllDays = value ?? false;
                          });
                        },
                      ),
                      const Text("Apply to all days"),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'tempOpen': tempOpen,
                      'tempClose': tempClose,
                      'applyToAllDays': applyToAllDays,
                      'index': index,
                    });
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        if (result['applyToAllDays'] == true) {
          for (int i = 0; i < _days.length; i++) {
            _days[i]["openTime"] = result['tempOpen'];
            _days[i]["closeTime"] = result['tempClose'];
            _days[i]["isOpen"] = true;
            _days[i]["updated"] = true;
          }
        } else {
          _days[index]["openTime"] = result['tempOpen'];
          _days[index]["closeTime"] = result['tempClose'];
          _days[index]["isOpen"] = true;
          _days[index]["updated"] = true;
        }
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final hhmm = parts[0].split(':');
      int hour = int.parse(hhmm[0]);
      final minute = int.parse(hhmm[1]);
      final period = parts[1].toUpperCase();
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _formatTo12Hour(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }
}
