import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckinHistoryScreen extends StatefulWidget {
  const CheckinHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CheckinHistoryScreen> createState() => _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends State<CheckinHistoryScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _allCheckins = [];
  List<dynamic> _filteredCheckins = [];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchCheckins();
  }

  /// Retrieve token from SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch check-in history from the API
  Future<void> _fetchCheckins() async {
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

    final url = Uri.parse('http://165.232.152.77/mobi/api/vendor/venues-checkins');
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
          setState(() {
            _allCheckins = data['data'];
          });
          _applyDateFilter(); // Initially show all
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No checkins found.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Unable to fetch checkins.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Filter _allCheckins by _startDate and _endDate, store results in _filteredCheckins
  void _applyDateFilter() {
    if (_startDate == null && _endDate == null) {
      setState(() {
        _filteredCheckins = List.from(_allCheckins);
      });
      return;
    }

    setState(() {
      _filteredCheckins = _allCheckins.where((item) {
        final dateString = item['created_at'] ?? '';
        final parsedDate = _parseDate(dateString);
        if (parsedDate == null) return false;

        // If we have both start and end date
        if (_startDate != null && _endDate != null) {
          return parsedDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                 parsedDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        // If only start date
        else if (_startDate != null) {
          return parsedDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
        }
        // If only end date
        else if (_endDate != null) {
          return parsedDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        return true;
      }).toList();
    });
  }

  /// Parse a date string (e.g. "2025-03-13 17:20:37") into a DateTime
  DateTime? _parseDate(String dateStr) {
    try {
      // If your date format is "YYYY-MM-DD HH:mm:ss", we can do:
      return DateTime.parse(dateStr.replaceAll(' ', 'T'));
    } catch (e) {
      return null;
    }
  }

  /// Pick a date and set it to _startDate or _endDate
  Future<void> _pickDate(bool isStart) async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2050),
    );
    if (newDate != null) {
      setState(() {
        if (isStart) {
          _startDate = newDate;
        } else {
          _endDate = newDate;
        }
      });
      _applyDateFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date filter row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _startDate == null
                            ? 'Start Date'
                            : _startDate!.toString().split(' ')[0],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _endDate == null
                            ? 'End Date'
                            : _endDate!.toString().split(' ')[0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Error or loading
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            // Checkin list
            Expanded(
              child: _filteredCheckins.isEmpty
                  ? const Center(child: Text('No checkin records found.'))
                  : ListView.builder(
                      itemCount: _filteredCheckins.length,
                      itemBuilder: (context, index) {
                        final item = _filteredCheckins[index];
                        // Adjust field names as needed
                        final venueName = item['venue']?['name'] ?? 'Unknown';
                        final points = item['points'] ?? 0;
                        final dateStr = item['created_at'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Image.asset(
                              'assets/bird.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          title: Text(
                            venueName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(dateStr),
                          trailing: Text(
                            '${points >= 0 ? '+' : ''}$points fts',
                            style: TextStyle(
                              color: points >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
