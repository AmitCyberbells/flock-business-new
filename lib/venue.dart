import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flock/edit_venue.dart'; // This file should contain your EditVenueScreen implementation.
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flock/HomeScreen.dart';
import 'package:flock/custom_scaffold.dart';

// Design tokens
class Design {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color darkPink = Color(0xFFD81B60);
  static const Color lightGrey = Colors.grey;
  static const Color lightBlue = Color(0xFF2A4CE1);
  static const Color lightPink = Color(0xFFFFE9ED);
  static const Color primaryColorOrange = Color.fromRGBO(255, 130, 16, 1);
  static const double font11 = 11;
  static const double font12 = 12;
  static const double font13 = 13;
  static const double font15 = 15;
  static const double font17 = 17;
  static const double font20 = 20;

  static var lightPurple;

  static var blue;
}

// Global images
class GlobalImages {
  //  static const String back = 'assets/back.png';
  static const String location = 'assets/location.png';
}

// Server endpoints
class Server {
  static const String categoryList =
      'https://api.getflock.io/api/vendor/categories';
  static const String getProfile = 'https://api.getflock.io/api/vendor/profile';
  static const String getVenueData =
      'https://api.getflock.io/api/vendor/venues';
  static const String removeVenue = 'https://api.getflock.io/api/vendor/venues';
  static const String updateVenue = 'https://api.getflock.io/api/vendor/venues';
  static const String venueList = 'https://api.getflock.io/api/vendor/venues';
}

// Permissions placeholder
class UserPermissions {
  static void getAssignedPermissions(String? userId) {}
  static bool hasPermission(String permission) => true;
}

// Reusable card wrapper widget
Widget cardWrapper({
  required Widget child,
  double borderRadius = 10,
  double elevation = 5,
  Color color = Colors.white,
}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: elevation,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class TabEggScreen extends StatefulWidget {
  const TabEggScreen({Key? key}) : super(key: key);

  @override
  State<TabEggScreen> createState() => _TabEggScreenState();
}

class _TabEggScreenState extends State<TabEggScreen> {
  bool loader = false;
  bool dialogAlert = false;
  String removeVenueId = '';
  String greeting = '';
  String firstName = '';
  String lastName = '';
  List<dynamic> categoryList = [];
  int cardPosition = 0;
  List<dynamic> allData = [];
  Timer? _timer;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    computeGreeting();
    fetchInitialData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  void computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userid') ?? '';
  }

  void startLoader() {
    setState(() => loader = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20), () {
      setState(() => loader = false);
    });
  }

  Future<Map<String, dynamic>> makeApiRequest({
    required String url,
    required Map<String, String> headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchInitialData() async {
    try {
      final userId = await getUserId();
      await Future.wait([getProfile(userId), getCategoryList(userId)]);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error initializing data: $e');
    }
  }

  Future<void> getProfile(String userId) async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await makeApiRequest(
        url: Server.getProfile,
        headers: headers,
      );

      setState(() {
        loader = false;
        firstName = response['data']['first_name'] ?? '';
        lastName = response['data']['last_name'] ?? '';
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('firstName', firstName);
          prefs.setString('lastName', lastName);
        });
      });
    } catch (e) {
      setState(() => loader = false);
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        firstName = prefs.getString('firstName') ?? 'User';
        lastName = prefs.getString('lastName') ?? '';
      });
    }
  }

  Future<void> getCategoryList(String userId) async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await makeApiRequest(
        url: Server.categoryList,
        headers: headers,
      );

      setState(() {
        categoryList = response['data'] ?? [];
        loader = false;
        if (categoryList.isNotEmpty) {
          cardPosition = 0;
          getVenueData(userId, categoryList[cardPosition]['id'].toString());
        }
      });
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: 'Failed to load categories: $e');
    }
  }

  Future<void> getVenueData(String userId, String categoryId) async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      if (token.isEmpty) throw Exception('No authentication token');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await makeApiRequest(
        url: Server.getVenueData,
        headers: headers,
        queryParams: {'category_id': categoryId},
      );

      print('Venue response for category $categoryId: $response'); // Debug

      setState(() {
        allData = response['data'] ?? [];
        loader = false;
        if (allData.isEmpty) {
          // Fluttertoast.showToast(msg: 'No venues found for this category');
        }
      });
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(msg: 'Failed to load venues: $e');
      print('Venue fetch error: $e');
    }
  }

  void clickCategoryItem(dynamic item, int index) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        cardPosition = index;
        allData = [];
      });
      getUserId().then((uid) => getVenueData(uid, item['id'].toString()));
    });
  }

  Future<void> removeVenueBtn() async {
    setState(() => loader = true);
    try {
      final token = await getToken();
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.delete(
        Uri.parse('${Server.removeVenue}/$removeVenueId'),
        headers: headers,
      );

      final responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        setState(() {
          allData.removeWhere(
            (element) => element['id'].toString() == removeVenueId,
          );
          dialogAlert = false;
          loader = false;
        });
        Fluttertoast.showToast(
          msg: responseData['message'] ?? 'Venue removed successfully',
          toastLength: Toast.LENGTH_LONG,
        );
        final userId = await getUserId();
        if (categoryList.isNotEmpty) {
          getVenueData(userId, categoryList[cardPosition]['id'].toString());
        }
      } else {
        var errorMessage =
            responseData['message'] ??
            'Failed to remove venue (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() => loader = false);
      Fluttertoast.showToast(
        msg: 'Failed to remove venue: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  // In venue.dart, replace the editVenue method with this:

  void editVenue(Map<String, dynamic> item) {
    if (!UserPermissions.hasPermission('edit_venue')) {
      Fluttertoast.showToast(msg: "You don't have access to this feature!");
      return;
    }
    final categoryId =
        item['category_id']?.toString() ??
        categoryList[cardPosition]['id'].toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditVenueScreen(
              venueData: Map<String, dynamic>.from(item),
              categoryId: categoryId,
            ),
      ),
    ).then((updatedVenue) {
      if (updatedVenue != null && updatedVenue is Map<String, dynamic>) {
        setState(() {
          final index = allData.indexWhere(
            (v) => v['id'].toString() == updatedVenue['id'].toString(),
          );
          if (index != -1) {
            // Update existing venue
            allData[index] = Map<String, dynamic>.from(updatedVenue);
          } else {
            // Add new venue if not found (edge case)
            allData.add(Map<String, dynamic>.from(updatedVenue));
          }
        });
        // Optional: Refresh venue data to ensure consistency with backend
        getUserId().then((uid) => getVenueData(uid, categoryId));
      }
    });
  }

  void qrCodeBtn(Map<String, dynamic> item) {
    final String qrData = item['qrData'] ?? item['id'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("QR Code"),
          content: SizedBox(
            width: 200,
            height: 200,
            child: Align(
              alignment: Alignment.center,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void locationBtn(String lat, String lon, String label) {
    final latNum = double.tryParse(lat) ?? 0.0;
    final lonNum = double.tryParse(lon) ?? 0.0;
    final scheme = Platform.isIOS ? 'maps://?daddr=' : 'geo:';
    final uri = '$scheme$latNum,$lonNum';
    Fluttertoast.showToast(msg: 'Open map for $label at ($lat, $lon)');
  }

  Widget buildCategoryItem(dynamic item, int index) {
    final isSelected = (cardPosition == index);
    final colors = ["#FBDFC3", "#CAD2F7", "#C3CFD6", "#FEF2BF"];
    final bgColor = Color(int.parse('0xff${colors[index % 4].substring(1)}'));

    // Use MediaQuery for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize =
        screenWidth * 0.07; // 8% of screen width for icon (adjustable)
    // final iconSize = .00;
    return GestureDetector(
      onTap: () => clickCategoryItem(item, index),
      child: Container(
        width: screenWidth * 0.18, // Responsive width (adjustable)
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.002, // Responsive margin
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border:
                    isSelected
                        ? Border.all(color: Colors.grey.shade300, width: 1)
                        : null,
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              padding: EdgeInsets.all(screenWidth * 0.020),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  cardWrapper(
                    borderRadius: 40,
                    elevation: isSelected ? 0 : 5,
                    color: bgColor,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ClipOval(
                        child: SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: Image.network(
                            item['icon'] ?? 'https://picsum.photos/50',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    Icon(Icons.error, size: iconSize * 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // This keeps spacing consistent whether selected or not
                  SizedBox(height: screenWidth * 0.010),

                  SizedBox(
                    width: screenWidth * 0.2,
                    child: Text(
                      item['name'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: screenWidth * 0.03),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVenueItem(Map<String, dynamic> item) {
    return cardWrapper(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item['images'] != null && item['images'].isNotEmpty
                      ? item['images'].last['image']
                      : 'https://picsum.photos/90',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Venue name and approval/QR code row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: Design.font17,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item['approval'] == '0')
                          Text(
                            '(In Review)',
                            style: TextStyle(
                              fontSize: Design.font13,
                              color: Design.darkPink,
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => qrCodeBtn(item),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: Design.font12,
                                  color: Design.lightBlue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Address row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Image.asset(
                            GlobalImages.location,
                            width: 12,
                            height: 10,
                            color: Design.lightGrey,
                          ),
                        ),
                        const SizedBox(width: 1),
                        Expanded(
                          child: InkWell(
                            onTap:
                                () => locationBtn(
                                  item['lat']?.toString() ?? '0.0',
                                  item['lon']?.toString() ?? '0.0',
                                  item['location'] ?? 'Unknown',
                                ),
                            child: Text(
                              item['location'] ?? 'No location',
                              style: const TextStyle(
                                fontSize: Design.font12,
                                color: Design.lightGrey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Added row for Posted At info
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(
                          'assets/date_time.png', // Replace with your image path
                          width: 16,
                          height: 16,
                          color:
                              Design
                                  .lightGrey, // Optional: if your image is an icon and you want to tint it
                        ),
                        const SizedBox(width: 4), // Space between icon and text
                        Text(
                          item['posted_at'] ?? '',
                          style: const TextStyle(
                            fontSize: Design.font12,
                            color: Design.lightGrey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    // Action buttons row (Edit and Remove)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit Info button with shadow
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                // color: Colors.grey.withOpacity(0.4),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: cardWrapper(
                            borderRadius: 5,
                            elevation: 2,
                            color: Colors.red,
                            child: InkWell(
                              onTap: () {
                                if (!UserPermissions.hasPermission(
                                  'remove_venue',
                                )) {
                                  Fluttertoast.showToast(
                                    msg:
                                        "You don't have access to this feature!",
                                  );
                                  return;
                                }
                                setState(() {
                                  removeVenueId = item['id'].toString();
                                  dialogAlert = true;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: Design.font13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                // color: Colors.grey.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: cardWrapper(
                            borderRadius: 5,
                            elevation: 2,
                            color: const Color.fromRGBO(255, 130, 16, 1),
                            child: InkWell(
                              onTap: () => editVenue(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/edit.png',
                                      width: 16,
                                      height: 16,
                                      color: const Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Edit Info',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: Design.font13,
                                        color: const Color.fromRGBO(
                                          255,
                                          255,
                                          255,
                                          1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Remove button with shadow
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      currentIndex: 1, // Venues screen corresponds to index 1
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                cardWrapper(
                  borderRadius: 10,
                  elevation: 5,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TabDashboard(),
                                  ),
                                );
                              },
                              child: Container(
                                color: Colors.white, // White background
                                child: Image.asset(
                                  'assets/back_updated.png',
                                  height: 40,
                                  width: 34,
                                  fit: BoxFit.contain,
                                  // color: const Color.fromRGBO(255, 130, 16, 1.0), // Orange tint
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "All Venues",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$greeting, ',
                                          style: const TextStyle(
                                            fontSize:
                                                Design.font15, // reduced size
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$firstName $lastName',
                                          style: const TextStyle(
                                            fontSize:
                                                Design
                                                    .font15, // same reduced size
                                            fontWeight:
                                                FontWeight
                                                    .bold, // bold for names
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 130,
                        child:
                            categoryList.isEmpty
                                ? const Center(
                                  //  child: Text('No Categories Found'),
                                )
                                : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  itemCount: categoryList.length,
                                  itemBuilder: (context, index) {
                                    final item = categoryList[index];
                                    return buildCategoryItem(item, index);
                                  },
                                ),
                      ),
                      // const SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      loader && allData.isEmpty
                          ? Stack(
                            children: [
                              // Semi-transparent dark overlay
                              Container(
                                color: Colors.black.withOpacity(
                                  0.1,
                                ), // Dark overlay
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
                          )
                          : allData.isEmpty
                          ? Center(
                            child: Text(
                              'No Venues Found in ${categoryList.isNotEmpty ? categoryList[cardPosition]['name'] : 'Selected Category'}',
                              style: const TextStyle(
                                fontSize: Design.font20,
                                color: Design.lightGrey,
                              ),
                            ),
                          )
                          : Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 20,
                                  bottom: 10,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Venues in ',
                                        style: TextStyle(
                                          fontSize: 18, // Adjust as needed
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            categoryList[cardPosition]['name'],
                                        style: const TextStyle(
                                          fontSize: 20, // Slightly larger
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Design
                                                  .primaryColorOrange, // or any color you like
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  itemCount: allData.length,
                                  itemBuilder: (context, index) {
                                    final item = allData[index];
                                    return Column(
                                      children: [
                                        buildVenueItem(item),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
            if (dialogAlert)
              if (dialogAlert)
                Stack(
                  children: [
                    // 🔘 Background overlay
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(
                          0.4,
                        ), // Darkens background
                      ),
                    ),

                    // 🔲 Dialog box
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Design.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirm Deletion',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Are you sure you want to remove venue?',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: Design.font15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () =>
                                            setState(() => dialogAlert = false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: removeVenueBtn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Design.primaryColorOrange,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

            // if (loader)
            //   Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
