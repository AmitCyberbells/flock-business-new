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
import 'package:qr_flutter/qr_flutter.dart'; // For QrImageView
import 'package:dropdown_search/dropdown_search.dart'; // For searchable dropdown

/// Reusable scaffold that integrates the FAB and bottom navigation bar.
class CustomScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  const CustomScaffold({Key? key, required this.body, required this.currentIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent, // No background color for the bottom sheet
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row for Add Venues and Add Offers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Add Venues Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.apartment,
                            label: "Add Venues",
                            iconColor: Colors.blue,
                            textColor: Colors.blue[900]!,
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => addVenue.AddEggScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Add Offers Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.percent,
                            label: "Add Offers",
                            iconColor: Colors.blue,
                            textColor: Colors.blue[900]!,
                            borderColor: Colors.blue, // Add a border to differentiate
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddOfferScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Send Notification Button (full width)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28.0), // Adjust as needed
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.notifications,
                        label: "Send Notification",
                        iconColor: Colors.blue,
                        textColor: Colors.blue[900]!,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SendNotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Image.asset(
          'assets/bird.png',
          fit: BoxFit.contain,
          width: 35,
          height: 35,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomBar(currentIndex: currentIndex),
    );
  }

  // Helper method to build each action button
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    Color backgroundColor = Colors.white,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Bottom Navigation Bar widget.
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TabDashboard()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => venue.TabEggScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckInsScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => profile.TabProfile()),
        );
        break;
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = (currentIndex == index);
    final Color activeColor = Colors.orange;
    final Color inactiveColor = Colors.grey;
    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              context,
              icon: Icons.grid_view_rounded,
              label: "Dashboard",
              index: 0,
            ),
            _buildNavItem(
              context,
              icon: Icons.apartment,
              label: "Venues",
              index: 1,
            ),
            const SizedBox(width: 50),
            _buildNavItem(
              context,
              icon: Icons.login_outlined,
              label: "Check In",
              index: 2,
            ),
            _buildNavItem(
              context,
              icon: Icons.person,
              label: "My Profile",
              index: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// TabDashboard widget (updated to use CustomScaffold).
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

  // Venue-related state.
  List<Map<String, dynamic>> venueList = []; // Properly typed as List<Map<String, dynamic>>
  Map<String, dynamic>? selectedVenue; // To store the currently selected venue

  // Example list for dashboard cards.
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
            // Set the default selected venue to the first one in the list
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
        padding: EdgeInsets.only(bottom: 8.0),
        child: Text(
          "Select Venue",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
      DropdownSearch<Map<String, dynamic>>(
        popupProps: const PopupProps.menu(
          showSearchBox: false, // Disable the search bar
        ),
        // asyncItems: (String filter) async {
        //   if (filter.isEmpty) {
        //     return venueList;
        //   }
        //   return venueList.where((venue) {
        //     final name = venue['name']?.toString().toLowerCase() ?? '';
        //     final id = venue['id']?.toString().toLowerCase() ?? '';
        //     return name.contains(filter.toLowerCase()) || id.contains(filter.toLowerCase());
        //   }).toList();
        // },
        compareFn: (Map<String, dynamic>? item1, Map<String, dynamic>? item2) {
          if (item1 == null || item2 == null) return false;
          return item1['id'] == item2['id'];
        },
        itemAsString: (Map<String, dynamic> venue) => venue['name'] ?? 'Unknown Venue',
        onChanged: (Map<String, dynamic>? newValue) {
          setState(() {
            selectedVenue = newValue;
          });
        },
        selectedItem: selectedVenue,
        dropdownBuilder: (context, selectedItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text(
              selectedItem != null
                  ? selectedItem['name'] ?? 'Unknown Venue'
                  : 'Select Venue',
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
      const SizedBox(height: 10),
      if (selectedVenue != null)
        Card(
          elevation: Platform.isIOS ? 2.5 : 7,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVenue!['name'] ?? 'Unknown Venue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: QrImageView(
                    data: selectedVenue!['id'].toString(),
                    version: QrVersions.auto,
                    size: 150.0,
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
                          Padding(
                            padding: EdgeInsets.only(top: Platform.isIOS ? 20 : 15),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 10,
                                childAspectRatio: Platform.isIOS ? 140 / 140 : 120 / 120,
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
                                                    color: Colors.deepOrange,
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
              color: Colors.white.withOpacity(0.19),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}