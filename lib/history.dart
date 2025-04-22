import 'dart:convert';
import 'package:flock/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
    final token = await _getToken();
    if (token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _fetchHistory();
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> _fetchHistory() async {
    setState(() => loader = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

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
        throw Exception(
            'API Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: 'Failed to load history: $e');
    }
  }

  /// ----------  ITEM UI  ----------
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    // Parse & format timestamp
    final inputFormat = DateFormat('MMMM-dd-yyyy hh:mm a');
    final timestamp = inputFormat.parse(item['datetime']);
    final formattedTime =
        DateFormat('MMMM-dd-yyyy hh:mm a').format(timestamp);

    // Points sign & colour
    final points = item['feather_points'] as int? ?? 0;

     final points1 = item['venue_points'] as int? ?? 0;
    
    final transactionType = item['transaction_type'] as String? ?? '+';
    final isPositive = transactionType == '+';
    final pointsText = isPositive ? '+ $points fts' : '- $points fts';

    final pointsText1 = isPositive ? '+ $points1 pts' : '- $points1 pts';

    final pointsColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 👈 top‑align icon
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              'assets/bird.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // ----- TITLE / VENUE / DATE -----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Offer Redeemed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                      const SizedBox(height: 4),
           item['offer_name'] == null || item['offer_name'].toString().trim().isEmpty
  ? Row(
      children: [
        const Icon(Icons.apartment, size: 16, color: Color.fromRGBO(255, 130, 16, 1)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            item['venue_name'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )
  : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['offer_name'],
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.apartment, size: 16, color: Color.fromRGBO(255, 130, 16, 1)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item['venue_name'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    )
,
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Color.fromRGBO(255, 130, 16, 1)),
            const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ----- POINTS -----
//           Column(
//   crossAxisAlignment: CrossAxisAlignment.end,
//   children: [
//     Text(
//       pointsText,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: pointsColor,
//       ),
//     ),
//     const SizedBox(height: 10), // Space between points
//     Text(
//       pointsText1,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: pointsColor,
//       ),
//     ),
//   ],
// ),

        ],
      ),
    );
  }

  /// ----------  PAGE UI  ----------
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      currentIndex: 2, // History tab
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ---------- HEADER ----------
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/back_updated.png',
                          height: 40,
                          width: 34,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Image.asset(
                              //   'assets/bird.png', // 👈 bird icon on top
                              //   height: 28,
                              //   width: 28,
                              // ),
                              // const SizedBox(width: 8),
                              const Text(
                                'Transaction History',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 34), // balance back‑button width
                    ],
                  ),
                ),
                // ---------- LIST ----------
                Expanded(
                  child: loader
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
                      : historyData.isEmpty
                          ? const Center(child: Text('No History Found'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: historyData.length,
                              itemBuilder: (context, index) =>
                                  _buildHistoryItem(historyData[index]),
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



