import 'dart:convert';
import 'package:flock/custom_scaffold.dart';
import 'package:flock/venue.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For formatting dates

// Assuming CustomScaffold is in a separate file

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool loader = false;
  List<dynamic> historyData = [];

  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  Future<void> checkAuthentication() async {
    final token = await getToken();
    if (token.isEmpty) {
      // Redirect to LoginScreen if not authenticated
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      fetchHistory(); // Fetch data if authenticated
    }
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> fetchHistory() async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Use the correct endpoint for transactions
      final response = await http
          .get(
            Uri.parse('http://165.232.152.77/api/vendor/transactions'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          historyData = data['data'] ?? [];
          loader = false;
        });
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: 'Failed to load history: $e');
    }
  }

  Widget buildHistoryItem(Map<String, dynamic> item) {
    // Format the timestamp to "yyyy-MM-dd hh:mm a" (e.g., "2025-03-13 05:20 pm")
    final timestamp = DateTime.parse(item['datetime']);
    final formattedTime = DateFormat('yyyy-MM-dd hh:mm a').format(timestamp);
    final image=item['image'] as String; 

    // Determine points sign and color based on transaction_type
    final points = item['feather_points'] as int;
    final transactionType = item['transaction_type'] as String;
    final isPositive = transactionType == '+';
    final pointsText = isPositive ? '+ $points pts' : '- $points pts';
    final pointsColor = isPositive ? Colors.green : Colors.red;

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
      child: Row(
        children: [
          // Bird Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              'assets/bird.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // Title and Timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Points
          Text(
            pointsText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: pointsColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      currentIndex:
          2, // Assuming History is accessible from Check-Ins (index 2)
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color.fromRGBO(255, 130, 16, 1.0),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "History",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Space for alignment
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child:
                      loader
                          ? Container(
                            color: Colors.white.withOpacity(0.19),
                            child: Center(
                              child: Image.asset(
                                'assets/Bird_Full_Eye_Blinking.gif',
                                width: 100, // Adjust size as needed
                                height: 100,
                              ),
                            ),
                          )
                          : historyData.isEmpty
                          ? const Center(child: Text('No History Found'))
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: historyData.length,
                            itemBuilder: (context, index) {
                              final item = historyData[index];
                              return buildHistoryItem(item);
                            },
                          ),
                ),
              ],
            ),
            //             if (loader)
            //               Container(
            //   color: Colors.white.withOpacity(0.19),
            //   child: Center(
            //     child: Image.asset(
            //       'assets/Bird_Full_Eye_Blinking.gif',
            //       width: 100, // Adjust size as needed
            //       height: 100,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
