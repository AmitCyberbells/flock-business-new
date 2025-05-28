import 'dart:convert';
import 'package:flock/feedback.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock/app_colors.dart'; // Import AppColors for primary color

class OpenHoursScreen extends StatefulWidget {
  const OpenHoursScreen({Key? key}) : super(key: key);

  @override
  State<OpenHoursScreen> createState() => _OpenHoursScreenState();
}

class _OpenHoursScreenState extends State<OpenHoursScreen> {
  List<Map<String, dynamic>> _venues = [];
  Map<String, dynamic>? _selectedVenue;

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
    final url = Uri.parse('https://api.getflock.io/api/vendor/venues');
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
      'https://api.getflock.io/api/vendor/venues/$venueId/opening-hours',
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
            final status = item['status']?.toString();
            bool isOpen = status == '1';
            final bool isUpdated = item['updated_at'] != null;

            final index = updatedDays.indexWhere((d) => d['day'] == localDay);
            if (index != -1) {
              updatedDays[index] = {
                "day": localDay,
                "isOpen": isOpen,
                "openTime":
                    isOpen ? _convertTo12HrFormat(openTime) : "12:00 AM",
                "closeTime":
                    isOpen ? _convertTo12HrFormat(closeTime) : "12:00 AM",
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
      'https://api.getflock.io/api/vendor/venues/$venueId/opening-hours',
    );
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    for (int i = 0; i < _days.length; i++) {
      final d = _days[i];
      final String serverDay = dayMap[d["day"]] ?? d["day"];
      final String openT = d["isOpen"] ? d["openTime"].toString() : "00:00";
      final String closeT = d["isOpen"] ? d["closeTime"].toString() : "00:00";
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
              content: Text(
                data['message'] ?? 'Hours updated successfully!',
                style: Theme.of(context).snackBarTheme.contentTextStyle,
              ),
              backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
            ),
          );
          setState(() {
            for (var day in _days) {
              if (day['isOpen']) {
                day['updated'] = true;
              }
            }
          });
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
      if (time24 == "00:00") {
        return "12:00 AM";
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Image.asset(
                            'assets/back_updated.png',
                            height: 40,
                            width: 34,
                            fit: BoxFit.contain,
                            // color: Theme.of(context).iconTheme.color, // Adapt icon color
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Open Hours",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedVenue?['name'] ?? 'Select a venue',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        child: SingleChildScrollView(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                    ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveOpeningHours,
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: Text(
                          "Save",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
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
          if (_isLoading)
            Stack(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.14),
                ),
                Container(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
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
        ],
      ),
    );
  }

  void _showVenueSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Select Venue",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.primary,
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                dayInfo["day"],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
            ),
            SizedBox(
              width: 60,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _days[index]["isOpen"] = !_days[index]["isOpen"];
                    if (!_days[index]["isOpen"]) {
                      _days[index]["updated"] = false;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: dayInfo["isOpen"]
                        ? (dayInfo["updated"] ? AppColors.primary : AppColors.primary)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dayInfo["isOpen"] ? "On" : "Off",
                    style: TextStyle(
                      color: dayInfo["isOpen"]
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayInfo["openTime"],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  Text(
                    " - ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    dayInfo["closeTime"],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.access_time,
                color: dayInfo["isOpen"] ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onPressed: dayInfo["isOpen"]
                  ? () {
                      _showDayDialog(dayInfo["day"], index);
                    }
                  : null,
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                day,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                          return Theme(
                            data: Theme.of(context).copyWith(
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
                                dialHandColor: AppColors.primary,
                                entryModeIconColor: AppColors.primary,
                              ),
                            ),
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
                    style: Theme.of(context).elevatedButtonTheme.style,
                    child: Text(
                      "Set Opening Time: $tempOpen",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _parseTimeOfDay(tempClose),
                        initialEntryMode: TimePickerEntryMode.input,
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
                                dialHandColor: AppColors.primary,
                                entryModeIconColor: AppColors.primary,
                              ),
                            ),
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
                    style: Theme.of(context).elevatedButtonTheme.style,
                    child: Text(
                      "Set Closing Time: $tempClose",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
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
                        activeColor: AppColors.primary,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      Text(
                        "Apply to all days",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    "Cancel",
                    style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve({})?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
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
                  style: Theme.of(context).elevatedButtonTheme.style,
                  child: Text(
                    "OK",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
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
            _days[i]["updated"] = false;
          }
        } else {
          _days[index]["openTime"] = result['tempOpen'];
          _days[index]["closeTime"] = result['tempClose'];
          _days[index]["isOpen"] = true;
          _days[index]["updated"] = false;
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
    final hourStr = time.hourOfPeriod.toString().padLeft(2, '0');
    final minStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr $period';
  }
}