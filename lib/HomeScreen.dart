import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flock/add_offer.dart';
import 'package:flock/add_venue.dart' as addVenue; // Alias for add_venue.dart
import 'package:flock/profile_screen.dart' as profile hide TabEggScreen;
import 'package:flock/send_notifications.dart';
import 'package:flock/venue.dart' as venue; // Alias for venue.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flock/checkIns.dart';

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

  // Venue-related state
  String selectedVenue = '';
  dynamic selectedVenueId;
  List<dynamic> venueList = [];

  // Example list similar to hotelList in React code
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

  // Dummy dashboard list (if needed for additional features)
  List<Map<String, dynamic>> dashboardList = [
    {
      'id': 1,
      'category': 'Existing Venues',
      'title': 'See all existing venues',
      'img': 'assets/business_eggs.png'
    },
    {
      'id': 2,
      'category': 'Statistics',
      'title': 'See all check in, offers in graph',
      'img': 'assets/statistics.png'
    },
  ];

  Timer? _timer;
  String userId = '';

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    _timer = Timer(Duration(seconds: 5), () {
      setState(() {
        loader = false;
      });
    });
  }

  Future<void> dashboardApi() async {
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
        setState(() {
          averageFeathers = responseJson['averagefeather'] ?? '';
          totalFeathers = responseJson['totalfeathers'] ?? '';
          todayFeathers =
              int.tryParse(responseJson['today_feathers'].toString()) ?? 0;
          todayVenuePoints =
              int.tryParse(responseJson['today_venue_points'].toString()) ?? 0;

          // Update hotelList values based on API response
          hotelList[0]['points'] =
              (responseJson['checkin'] ?? '0') + ' Check Ins';
          hotelList[1]['points'] =
              (responseJson['offers'] ?? '0') + ' Active offers';
          hotelList[2]['points'] =
              (responseJson['countvenues'] ?? '0') + ' Venues';
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

  Future<void> getVenueList() async {
    var url = Uri.parse("https://yourserver.com/venuelist");
    var request = http.MultipartRequest('POST', url);
    request.fields['vendor_id'] = userId;

    try {
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseJson = json.decode(responseString);

      setState(() {
        loader = false;
      });

      if (responseJson != null && responseJson['status'] == 'success') {
        if ((responseJson['venues'] as List).isNotEmpty) {
          setState(() {
            venueList = responseJson['venues'];
            selectedVenue = responseJson['venues'][0]['venue_name'];
            selectedVenueId = responseJson['venues'][0]['venue_id'];
          });
        }
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

  // Dummy function to check permissions based on field
  bool hasPermission(String permission) {
    // Replace with your actual permission logic.
    return true;
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
      await getOfferApi();
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

  Future<void> getOfferApi() async {
    startLoader();
    var url = Uri.parse("https://yourserver.com/getOffer");
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
        Navigator.pushNamed(context, '/offers', arguments: {
          'Offers': responseJson['Offers'],
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
    // Request camera permission
    var status = await Permission.camera.request();
    if (status.isGranted) {
      Navigator.pushNamed(context, '/qrcode');
    } else {
      Fluttertoast.showToast(msg: 'Camera Permission Denied!');
    }
  }

  Widget venueListDropDown() {
    if (!hasPermission('verify_voucher') || venueList.isEmpty) {
      return SizedBox.shrink();
    }
    return DropdownButton<String>(
      value: selectedVenue,
      onChanged: (String? newValue) {
        setState(() {
          selectedVenue = newValue!;
          // Find the venue id from venueList
          var venueItem = venueList.firstWhere(
            (element) => element['venue_name'] == selectedVenue,
            orElse: () => null,
          );
          if (venueItem != null) {
            selectedVenueId = venueItem['venue_id'];
          }
        });
      },
      items: venueList.map<DropdownMenuItem<String>>((dynamic value) {
        return DropdownMenuItem<String>(
          value: value['venue_name'],
          child: Text(value['venue_name']),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColorOrange = Colors.deepOrange;
    final lightGrey = Colors.grey;
    final black = Colors.black;
    final white = Colors.white;
    final lightColorOrange = Colors.orange[100];

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top greeting row with Verify Offer button
                  Padding(
                    padding: EdgeInsets.only(
                      top: Platform.isIOS ? 55 : 15,
                      bottom: Platform.isIOS ? 30 : 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Greeting texts
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hello, ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '$firstName $lastName',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Verify Offer / QR Scan button
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
                          // Card for today's Feathers and Venue Points
                          Card(
                            elevation: Platform.isIOS ? 2.5 : 7,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 5),
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
                                          color: lightGrey,
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
                                          color: lightGrey,
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
                          // Grid view for hotelList
                          Padding(
                            padding: EdgeInsets.only(top: Platform.isIOS ? 20 : 15),
                            child: GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 10,
                                childAspectRatio:
                                    Platform.isIOS ? 140 / 140 : 120 / 120,
                              ),
                              itemCount: hotelList.length,
                              itemBuilder: (context, index) {
                                final item = hotelList[index];
                                return GestureDetector(
                                  onTap: () => clickCard(item),
                                  child: Card(
                                    elevation: Platform.isIOS ? 2.5 : 7,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
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
                                                    color: primaryColorOrange,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    item['category'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: black,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: Platform.isIOS ? 14 : 7),
                                              Text(
                                                item['title'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: lightGrey,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              SizedBox(height: Platform.isIOS ? 15 : 0),
                                              Text(
                                                item['points'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: -10,
                                            right: -5,
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
                          // Venue selector dropdown and QR code display
                          venueListDropDown(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loader overlay
          if (loader)
            Container(
              color: Colors.white.withOpacity(0.19),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      // Updated footer using a FloatingActionButton and BottomAppBar
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show modal bottom sheet with extra actions
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                ListTile(
  leading: Icon(Icons.apartment, color: Colors.blue),
  title: Text("Add Venues"),
  onTap: () async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => addVenue.AddEggScreen()),
    );
    if (result != null && result == true) {
      // Refresh the venue list so the new venue appears
      getVenueList();
    }
  },
),

                  ListTile(
                    leading: Icon(Icons.percent, color: Colors.blue),
                    title: Text("Add Offers"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddOfferScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: Colors.blue),
                    title: Text("Send Notification"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SendNotificationScreen()),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.orange,
        child: Image.asset(
          'assets/bird.png',
          fit: BoxFit.contain,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}

// Reusable updated bottom navigation bar widget using BottomAppBar
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left side navigation items.
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.grid_view_rounded, color: Colors.orange),
                  onPressed: () => _navigateTo(context, TabDashboard()),
                ),
                IconButton(
                  icon: Icon(Icons.apartment, color: Colors.grey),
                  onPressed: () => _navigateTo(context, venue.TabEggScreen()),
                ),
              ],
            ),
            // Right side navigation items.
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.login_outlined, color: Colors.grey),
                  onPressed: () => _navigateTo(context, CheckInsScreen()),
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Colors.grey),
                  onPressed: () => _navigateTo(context, profile.TabProfile()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy screens for navigation
// class CheckInScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(appBar: AppBar(title: Text("Check In")));
//   }
// }

class AddOfferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Add Offer")));
  }
}

class SendNotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Send Notification")));
  }
}
