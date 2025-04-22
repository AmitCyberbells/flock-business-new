import 'dart:convert';
import 'package:flock/constants.dart';
import 'package:flock/custom_scaffold.dart';
import 'package:flock/venue.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Assuming CustomScaffold is in a separate file
// Remove the import for HistoryScreen if no longer needed.

class CheckInsScreen extends StatefulWidget {
  const CheckInsScreen({Key? key}) : super(key: key);

  @override
  State<CheckInsScreen> createState() => _CheckInsScreenState();
}

class _CheckInsScreenState extends State<CheckInsScreen> {
  bool loader = false;
  List<dynamic> checkInData = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    final token = await getToken();
    if (token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      fetchCheckIns();
    }
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> fetchCheckIns() async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final queryParams =
          selectedDate != null
              ? {'date': DateFormat('yyyy-MM-dd').format(selectedDate!)}
              : null;

      final uri = Uri.parse(
        'http://165.232.152.77/api/vendor/venues-checkins',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          checkInData = data['data'] ?? [];
          loader = false;
        });
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: 'Failed to load check-ins: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchCheckIns();
    }
  }

  Widget buildCheckInItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: image + category name
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  item['image'] ?? 'https://picsum.photos/50',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Bottom row: "Today's Check-Ins" + "Feathers Earn"
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color.fromRGBO(255, 130, 16, 1.0),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Check-Ins",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['total_checkins'].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 130, 16, 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Feathers Allotted",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${item['total_feather_points']} fts",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      currentIndex: 3, //2
      body: SafeArea(
        child: Column(
          children: [
            // 👇 Manually include the app bar as a widget
            AppConstants.customAppBar(context: context, title: 'Check-Ins'),

            // Date selector aligned to the right
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: TextButton(
                  onPressed: () => _selectDate(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedDate == null
                            ? "Choose Date"
                            : DateFormat('MMM d, yyyy').format(selectedDate!),
                        style: const TextStyle(
                          color: Color.fromRGBO(255, 130, 16, 1.0),
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color.fromRGBO(255, 130, 16, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Main content area
            Expanded(
              child:
                  loader
                      ? Stack(
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
                      )
                      : checkInData.isEmpty
                      ? const Center(child: Text('No Check-Ins Found'))
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: checkInData.length,
                        itemBuilder: (context, index) {
                          final item = checkInData[index];
                          return buildCheckInItem(item);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
