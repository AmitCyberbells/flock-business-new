import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flock/add_offer.dart';
import 'package:flock/add_venue.dart' as addVenue;
import 'package:flock/profile_screen.dart' as profile hide TabEggScreen;
import 'package:flock/send_notifications.dart';
import 'package:flock/venue.dart' as venue;
import 'package:flock/checkIns.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flock/custom_scaffold.dart';

class TabDashboard extends StatefulWidget {
  @override
  _TabDashboardState createState() => _TabDashboardState();
}

class _TabDashboardState extends State<TabDashboard> {
  String averageFeathers = '';
  String totalFeathers = '';
  int todayFeathers = 0;
  int todayVenuePoints = 0;
  String firstName = '';
  String lastName = '';
  bool loader = false;

  List<Map<String, dynamic>> venueList = [];
  Map<String, dynamic>? selectedVenue;

  List<Map<String, dynamic>> hotelList = [
    {
      'id': 1,
      'slug': 'check_ins',
      'category': 'Check Ins',
      'title': 'Total Check Ins Today',
      'points': '',
      'img': 'assets/business_checkin.png',
    },
    {
      'id': 2,
      'slug': 'offers',
      'category': 'Offers',
      'title': 'Total Active Offers',
      'points': '',
      'img': 'assets/points.png',
    },
    {
      'id': 3,
      'slug': 'venues',
      'category': 'Venues',
      'title': 'Total Venues',
      'points': '',
      'img': 'assets/business_eggs.png',
    },
    {
      'id': 4,
      'slug': 'faq',
      'category': 'FAQ',
      'title': 'Open FAQ',
      'points': '',
      'img': 'assets/feather.png',
    },
  ];

  Timer? _timer;
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchName();
    getUserId();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? '';
      lastName = prefs.getString('lastName') ?? '';
    });
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userid') ?? '';
    dashboardApi();
    getVenueList();
  }

  void startLoader() {
    setState(() {
      loader = true;
    });
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 1), () {
      setState(() {
        loader = false;
      });
    });
  }

  Future<void> dashboardApi() async {
    startLoader();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Fluttertoast.showToast(msg: 'No token found, please login again.');
      setState(() => loader = false);
      return;
    }
    final url = Uri.parse("http://165.232.152.77/mobi/api/vendor/dashboard");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      setState(() {
        loader = false;
      });
      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson != null && responseJson['status'] == 'success') {
          final data = responseJson['data'];
          setState(() {
            averageFeathers = data['averageFeathers']?.toString() ?? '';
            totalFeathers = data['totalFeathers']?.toString() ?? '';
            todayFeathers = data['today_feathers'] ?? 0;
            todayVenuePoints = data['today_venue_points'] ?? 0;
            hotelList[0]['points'] = '${data['checkin_count'] ?? 0} Check Ins';
            hotelList[1]['points'] = '${data['offers_count'] ?? 0} Active offers';
            hotelList[2]['points'] = '${data['venues_count'] ?? 0} Venues';
          });
        } else {
          Fluttertoast.showToast(msg: responseJson['message'] ?? 'Error');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        loader = false;
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> getVenueList() async {
    startLoader();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Fluttertoast.showToast(msg: 'No token found, please login again.');
      setState(() => loader = false);
      return;
    }

    final url = Uri.parse("http://165.232.152.77/mobi/api/vendor/venues");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      setState(() {
        loader = false;
      });
      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson != null && responseJson['status'] == 'success') {
          setState(() {
            venueList = List<Map<String, dynamic>>.from(responseJson['data'] ?? []);
            if (venueList.isNotEmpty) {
              selectedVenue = venueList[0];
            }
          });
        } else {
          Fluttertoast.showToast(msg: responseJson['message'] ?? 'Error fetching venues');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        loader = false;
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  bool hasPermission(String permission) {
    return true; // Replace with your actual permission logic.
  }

  String getPermissionName(String field) {
    switch (field) {
      case "offers":
        return "create_offer";
      case "check_ins":
        return "checkins_history";
      case "feathers":
        return "feathers_history";
      case "venues":
        return "venues_list";
      default:
        return "";
    }
  }

  Future<void> clickCard(Map<String, dynamic> item) async {
    if (!hasPermission(getPermissionName(item['slug']))) {
      Fluttertoast.showToast(msg: "You don't have access to this feature!");
      return;
    }
    String slug = item['slug'];
    if (slug == "offers") {
      Navigator.pushNamed(context, '/offers');
    } else if (slug == "check_ins") {
      Navigator.pushNamed(context, '/tab_checkin');
    } else if (slug == "feathers") {
      await totalFeatherApi();
    } else if (slug == "venues") {
      Navigator.pushNamed(context, '/tab_egg');
    } else if (slug == "faq") {
      Navigator.pushNamed(context, '/faq');
    }
  }

  Future<void> totalFeatherApi() async {
    startLoader();
    var url = Uri.parse("https://yourserver.com/dashboard");
    var request = http.MultipartRequest('POST', url);
    request.fields['user_id'] = userId;
    try {
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseJson = json.decode(responseString);
      setState(() {
        loader = false;
      });
      if (responseJson != null && responseJson['status'] == 'success') {
        Navigator.pushNamed(context, '/feathers', arguments: {
          'totalfeathers': responseJson['totalfeathers'],
          'totalvenuepoints': responseJson['total_venue_points'],
        });
      } else {
        Fluttertoast.showToast(msg: responseJson['message'] ?? 'Error');
      }
    } catch (e) {
      setState(() {
        loader = false;
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> verifyOffer() async {
    if (!hasPermission('verify_voucher')) {
      Fluttertoast.showToast(msg: 'Permission Denied!');
      return;
    }
    var status = await Permission.camera.request();
    if (status.isGranted) {
      Navigator.pushNamed(context, '/qrcode');
    } else {
      Fluttertoast.showToast(msg: 'Camera Permission Denied!');
    }
  }
Widget venueListWithQRCodes() {
  if (!hasPermission('verify_voucher') || venueList.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
        // child: Text(
        //   "Select Venue",
        //   style: TextStyle(
        //     fontSize: 16,
        //     color: Colors.grey,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: selectedVenue,
            isExpanded: true,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
              size: 30,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            items: venueList.map((Map<String, dynamic> venue) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: venue,
                child: Text(
                  venue['name'] ?? 'Unknown Venue',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: (Map<String, dynamic>? newValue) {
              setState(() {
                selectedVenue = newValue;
              });
            },
            hint: const Text(
              'Select Venue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 15),
      if (selectedVenue != null)
        Card(
          color: Colors.white,
          elevation: Platform.isIOS ? 2.5 : 7,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVenue!['name'] ?? 'Unknown Venue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: selectedVenue!['id'].toString(),
                      version: QrVersions.auto,
                      size: 150.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final black = Colors.black;
    final lightGrey = Colors.grey;
    return CustomScaffold(
      currentIndex: 0,
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              color: Colors.white, // Set main container background to white
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: Platform.isIOS ? 55 : 15,
                      bottom: Platform.isIOS ? 30 : 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Hello, ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '$firstName $lastName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/scan_qr.png',
                            width: Platform.isIOS ? 45 : 40,
                            height: Platform.isIOS ? 45 : 40,
                          ),
                          onPressed: verifyOffer,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Card(
                            color: Colors.white, // Set card background to white
                            elevation: Platform.isIOS ? 2.5 : 7,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Platform.isIOS ? 20 : 15,
                                vertical: Platform.isIOS ? 10 : 7,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Feathers Rewarded Today',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'SFProText',
                                         color: Color(0xFFB4B4B4),

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: Platform.isIOS ? 10 : 0),
                                  Text(
                                    '$todayFeathers fts',
                                    style: TextStyle(
                                      fontSize: 23,
                                      color: black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.grey,
                                    thickness: Platform.isIOS ? 0.6 : 0.3,
                                    height: Platform.isIOS ? 10 : 5,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Venue Points Rewarded Today: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFB4B4B4),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$todayVenuePoints pts',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: Platform.isIOS ? 20 : 15),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 10,
childAspectRatio: Platform.isIOS ? 160 / 140 : 140 / 120, 
                              ),
                              itemCount: hotelList.length,
                              itemBuilder: (context, index) {
                                final item = hotelList[index];
                                return GestureDetector(
                                  onTap: () => clickCard(item),
                                  child: Card(
                                    color: Colors.white, // Set card background to white
                                    elevation: Platform.isIOS ? 2.5 : 7,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 25,
                                        horizontal: 15,
                                      ),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    item['img'],
                                                    width: Platform.isIOS ? 25 : 25,
                                                    height: Platform.isIOS ? 25 : 25,
                                                    color: const Color.fromRGBO(255, 130, 16, 1),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    item['category'],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: Platform.isIOS ? 14 : 7),
                                              Text(
                                                item['title'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              SizedBox(height: Platform.isIOS ? 15 : 0),
                                              Text(
                                                item['points'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: -10,
                                            right: -15,
                                            child: IconButton(
                                              icon: Image.asset(
                                                'assets/side_arrow.png',
                                                width: Platform.isIOS ? 18 : 15,
                                                height: Platform.isIOS ? 18 : 15,
                                              ),
                                              onPressed: () => clickCard(item),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          venueListWithQRCodes(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loader)
            Container(
              color: Colors.white.withOpacity(0.19), // Semi-transparent overlay
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}