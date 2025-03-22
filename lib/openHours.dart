import 'package:flutter/material.dart';

class OpenHoursScreen extends StatefulWidget {
  const OpenHoursScreen({Key? key}) : super(key: key);

  @override
  State<OpenHoursScreen> createState() => _OpenHoursScreenState();
}

class _OpenHoursScreenState extends State<OpenHoursScreen> {
  // Sample data for days of the week
  final List<Map<String, dynamic>> _days = [
    {"day": "Mon", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Tue", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Wed", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Thu", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Fri", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Sat", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
    {"day": "Sun", "isOpen": false, "openTime": "00:00", "closeTime": "00:00"},
  ];

  // Currently selected venue for the dropdown
  String _selectedVenue = "Brew Barrels";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Light background, if desired
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

            // Dropdown for "Brew Barrels"
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
                  child: DropdownButton<String>(
                    value: _selectedVenue,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: <String>[
                      "Brew Barrels",
                      "Venue 2",
                      "Venue 3",
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedVenue = newValue ?? _selectedVenue;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List of days
            Expanded(
              child: ListView.builder(
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final dayInfo = _days[index];
                  return _buildDayRow(dayInfo, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds each row: Day label, Switch, time range, icon
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
            // Day label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                dayInfo["day"],
                style: const TextStyle(fontSize: 16),
              ),
            ),

            // Switch
            Switch(
              value: dayInfo["isOpen"],
              activeColor: Colors.orange,
              onChanged: (value) {
                setState(() {
                  _days[index]["isOpen"] = value;
                });
              },
            ),

            // Time range
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

            // Icon button to set times
            IconButton(
              icon: const Icon(
                Icons.remove_red_eye,
                color: Colors.orange,
              ),
              onPressed: () {
                _showDayDialog(dayInfo["day"], index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Shows a dialog for the selected day
  void _showDayDialog(String day, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                // Set Opening Time
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle setting opening time
                      // e.g., showTimePicker
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Set Opening Time"),
                  ),
                ),
                const SizedBox(height: 8),
                // Set Closing Time
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle setting closing time
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Set Closing Time"),
                  ),
                ),
                const SizedBox(height: 8),
                // Close
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



