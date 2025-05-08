import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flock/qr_code_scanner_screen.dart';
import 'package:flock/venue.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flock/custom_scaffold.dart';

class TabDashboard extends StatefulWidget {
  @override
  _TabDashboardState createState() => _TabDashboardState();
}

class _TabDashboardState extends State<TabDashboard>
    with WidgetsBindingObserver {
  String averageFeathers = '';
  String totalFeathers = '';
  int todayFeathers = 0;
  int todayVenuePoints = 0;
  String firstName = '';
  String lastName = '';
  bool loader = false;
  bool isVenueListLoaded = false;

  List<Map<String, dynamic>> venueList = [];
  Map<String, dynamic>? selectedVenue;
  bool showVenueDropdown = false; // For custom dropdown toggle

  List<Map<String, dynamic>> hotelList = [
    {
      'id': 1,
      'slug': 'Check-Ins',
      'category': 'Check-Ins',
      'title': 'Total Check-Ins Today',
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

    // {
    //   'id': 4,
    //   'slug': 'faq',
    //   'category': 'FAQ',
    //   'title': 'Open FAQ',
    //   'points': '',
    //   'img': 'assets/feather.png',
    // },
    {
      'id': 4,
      'slug': 'faq',
      'category': 'Activities',
      'title': 'See Transaction History',
      'points': '',
      'img': 'assets/feather.png',
    },
  ];

  Timer? _timer;
  String userId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Start lifecycle observation
    fetchName();
    getUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Called on lifecycle changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      var status = await Permission.camera.status;
      print("App resumed; camera permission status: $status");
      // Don’t navigate here
    }
  }

  Future<void> fetchName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        firstName = prefs.getString('firstName') ?? '';
        lastName = prefs.getString('lastName') ?? '';
      });
    }
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userid') ?? '';
    if (averageFeathers.isEmpty && venueList.isEmpty) {
      // Only fetch if data is not already loaded
      await dashboardApi();
      await getVenueList();
    }
  }

  void startLoader() {
    if (mounted) {
      setState(() {
        loader = true;
      });
    }
    _timer?.cancel();
    _timer = Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          loader = false;
        });
      }
    });
  }

  Future<void> dashboardApi() async {
    startLoader();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Fluttertoast.showToast(msg: 'No token found, please login again.');
      if (mounted) setState(() => loader = false);
      return;
    }
    final url = Uri.parse("https://api.getflock.io/api/vendor/dashboard");
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (mounted) {
        setState(() {
          loader = false;
        });
      }
      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson != null && responseJson['status'] == 'success') {
          final data = responseJson['data'];
          if (mounted) {
            setState(() {
              averageFeathers = data['averageFeathers']?.toString() ?? '';
              totalFeathers = data['totalFeathers']?.toString() ?? '';
              todayFeathers =
                  int.tryParse(data['today_feathers']?.toString() ?? '0') ?? 0;
              todayVenuePoints =
                  int.tryParse(data['today_venue_points']?.toString() ?? '0') ??
                  0;
              hotelList[0]['points'] =
                  '${int.tryParse(data['today_checkins']?.toString() ?? '0') ?? 0}';
              hotelList[1]['points'] =
                  '${int.tryParse(data['offers_count']?.toString() ?? '0') ?? 0}';
              hotelList[2]['points'] =
                  '${int.tryParse(data['venues_count']?.toString() ?? '0') ?? 0}';

              hotelList[3]['points'] =
                  '${int.tryParse(data['history_number']?.toString() ?? '0') ?? 0}';
            });
          }
        } else {
          Fluttertoast.showToast(msg: responseJson['message'] ?? 'Error');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loader = false;
        });
      }
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> getVenueList() async {
    startLoader();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      Fluttertoast.showToast(msg: 'No token found, please login again.');
      setState(() {
        loader = false;
        isVenueListLoaded = true; // Set flag even on failure
      });
      return;
    }
    final url = Uri.parse("https://api.getflock.io/api/vendor/venues");
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
        isVenueListLoaded = true; // API call completed
      });
      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        if (responseJson != null && responseJson['status'] == 'success') {
          setState(() {
            venueList = List<Map<String, dynamic>>.from(
              responseJson['data'] ?? [],
            );
            if (venueList.isNotEmpty) {
              selectedVenue = venueList[0];
            }
          });
        } else {
          Fluttertoast.showToast(
            msg: responseJson['message'] ?? 'Error fetching venues',
          );
        }
      } else {
        Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        loader = false;
        isVenueListLoaded = true; // Set flag even on error
      });
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  bool hasPermission(String permission) {
    return true;
  }

  String getPermissionName(String field) {
    switch (field) {
      case "offers":
        return "create_offer";
      case "Check-Ins":
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
    } else if (slug == "Check-Ins") {
      Navigator.pushNamed(context, '/tab_checkin');
    } else if (slug == "feathers") {
      await totalFeatherApi();
    } else if (slug == "venues") {
      Navigator.pushNamed(context, '/tab_egg');
    } else if (slug == "faq") {
      Navigator.pushNamed(context, '/history');
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
        Navigator.pushNamed(
          context,
          '/feathers',
          arguments: {
            'totalfeathers': responseJson['totalfeathers'],
            'totalvenuepoints': responseJson['total_venue_points'],
          },
        );
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

    if (selectedVenue == null) {
      Fluttertoast.showToast(msg: 'Please select a venue first!');
      return;
    }

    var status = await Permission.camera.status;
    print("Initial camera permission status: $status");

    if (status.isDenied) {
      status = await Permission.camera.request();
      print("Camera permission status after request: $status");
    }

    if (status.isGranted) {
      _navigateToQRScanScreen(selectedVenue!['id'].toString());
    } else if (status.isPermanentlyDenied) {
      Fluttertoast.showToast(
        msg:
            'Camera permission is permanently denied. Please enable it in settings.',
      );
      await openAppSettings();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        var newStatus = await Permission.camera.status;
        if (newStatus.isGranted) {
          _navigateToQRScanScreen(selectedVenue!['id'].toString());
        }
      });
    } else {
      Fluttertoast.showToast(msg: 'Camera Permission Denied!');
    }
  }

  Future<void> _navigateToQRScanScreen(String venueId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    if (token == null) {
      Fluttertoast.showToast(msg: 'No token found. Please log in.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanScreen(venueId: venueId, token: token),
      ),
    ).then((qrCode) {
      if (qrCode != null) {
        _handleScannedQRCode(qrCode, venueId);
      }
    });
  }

  // void _handleScannedQRCode(String qrCode, String venueId) {
  //   Fluttertoast.showToast(
  //     msg: 'Scanned QR Code: $qrCode for Venue ID: $venueId',
  //   );
  // }

  // void _navigateToQRScanScreen(String venueId) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => QRScanScreen(venueId: venueId)),
  //   );
  // }

  Future<void> _handleScannedQRCode(String qrCode, String venueId) async {
    startLoader();
    final token = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString('access_token'),
    );
    final url = Uri.parse("https://api.getflock.io/api/vendor/verify-voucher");
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'qr_code': qrCode, 'venue_id': venueId}),
      );
      setState(() => loader = false);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Voucher verified successfully!');
      } else {
        Fluttertoast.showToast(
          // msg: 'Error verifying voucher: ${response.statusCode}',
          msg: 'Error verifying voucher',
        );
      }
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  /// Custom dropdown design for selecting venue.
  Widget customVenueDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        // White box shadow for differentiation.
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                showVenueDropdown = !showVenueDropdown;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Design.lightPurple,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedVenue == null
                        ? "Select Venue"
                        : selectedVenue!['name'] ?? "Select Venue",
                    style: const TextStyle(fontSize: 15),
                  ),
                  Icon(
                    showVenueDropdown
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (showVenueDropdown)
            Container(
              constraints: BoxConstraints(maxHeight: 35.0 * 5),
              decoration: BoxDecoration(
                color: Design.lightPurple,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true, // always show scrollbar
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: venueList.length,
                        itemBuilder: (context, index) {
                          final venue = venueList[index];
                          final isSelected =
                              selectedVenue != null &&
                              selectedVenue!['id'].toString() ==
                                  venue['id'].toString();
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedVenue = venue;
                                showVenueDropdown = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              color:
                                  isSelected
                                      ? Design.primaryColorOrange.withOpacity(
                                        0.1,
                                      )
                                      : Colors.transparent,
                              child: Text(
                                venue['name'] ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.all(6.0),
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: ElevatedButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           showVenueDropdown = false;
                  //         });
                  //       },
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Design.primaryColorOrange,
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(5),
                  //         ),
                  //         padding: const EdgeInsets.symmetric(vertical: 8),
                  //       ),
                  //       child: const Text(
                  //         "Done",
                  //         style: TextStyle(color: Colors.white),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Updated venue list with QR Codes method (includes the custom dropdown)
  ///
  /// Updated venue list with QR Codes method (includes the custom dropdown)

  Widget venueListWithQRCodes() {
    if (!hasPermission('verify_voucher')) {
      return const SizedBox.shrink();
    }
    if (!isVenueListLoaded) {
      return const SizedBox.shrink(); // Don't show anything until API call completes
    }
    if (venueList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Text(
            'You don’t have any venues yet, please add a venue by clicking on the "Bird Image" at the bottom.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customVenueDropdown(),
        if (selectedVenue != null)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  data: selectedVenue!['id'].toString(),
                  version: QrVersions.auto,
                  size: 150.0,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return CustomScaffold(
      currentIndex: 0,
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.023),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Hello" Section
                  Padding(
                    padding: EdgeInsets.only(
                      top: Platform.isIOS ? 20 : 5,
                      bottom: Platform.isIOS ? 10 : 5,
                      left: Platform.isIOS ? 15 : 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Padding(
                            padding: EdgeInsets.only(
                              top: Platform.isIOS ? 5 : 5,
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.all(deviceWidth * 0.023),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing:
                                        MediaQuery.of(context).size.height *
                                        0.016,
                                    crossAxisSpacing: deviceWidth * 0.04,
                                    childAspectRatio:
                                        deviceWidth /
                                        (MediaQuery.of(context).size.height *
                                            0.4),
                                  ),
                              itemCount: hotelList.length,
                              itemBuilder: (context, index) {
                                final item = hotelList[index];
                                return GestureDetector(
                                  onTap: () => clickCard(item),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                          0.0025,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.4),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                            0.020,
                                        horizontal: deviceWidth * 0.03,
                                      ),
                                      child: Stack(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    item['img'],
                                                    width: deviceWidth * 0.06,
                                                    height: deviceWidth * 0.06,
                                                    color: const Color.fromRGBO(
                                                      255,
                                                      130,
                                                      16,
                                                      1,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      item['category'],
                                                      style: TextStyle(
                                                        fontSize:
                                                            deviceWidth * 0.040,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      softWrap: true,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.visible,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.01,
                                              ),
                                              Center(
                                                child: Text(
                                                  item['title'],
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.03,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height *
                                                    0.01,
                                              ),
                                              Center(
                                                child: Text(
                                                  item['points'],
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.08,
                                                    color: const Color.fromRGBO(
                                                      255,
                                                      130,
                                                      16,
                                                      1,
                                                    ),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top:
                                                -MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.018,
                                            right: -deviceWidth * 0.035,
                                            child: IconButton(
                                              icon: Image.asset(
                                                'assets/side_arrow.png',
                                                width: deviceWidth * 0.035,
                                                height: deviceWidth * 0.035,
                                              ),
                                              onPressed: () => clickCard(item),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          venueListWithQRCodes(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loader)
            Stack(
              children: [
                // Semi-transparent dark overlay
                Container(
                  color: Colors.black.withOpacity(0.14), // Dark overlay
                ),

                // Your original container with white tint and loader
                Container(
                  color: Colors.white10,
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
        ],
      ),
    );
  }
}
