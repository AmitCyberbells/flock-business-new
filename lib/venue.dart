import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flock/edit_venue.dart'; // This file should contain your EditVenueScreen implementation.
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Design tokens
class Design {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color darkPink = Color(0xFFD81B60);
  static const Color lightGrey = Colors.grey;
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color lightPink = Color(0xFFFFE9ED);
  static const Color primaryColorOrange = Colors.orange;
  static const double font11 = 11;
  static const double font12 = 12;
  static const double font13 = 13;
  static const double font15 = 15;
  static const double font17 = 17;
  static const double font20 = 20;
}

// Global images
class GlobalImages {
  static const String back = 'assets/back.png';
  static const String location = 'assets/location.png';
}

// Server endpoints
class Server {
  static const String categoryList = 'http://165.232.152.77/mobi/api/vendor/categories';
  static const String getProfile = 'http://165.232.152.77/mobi/api/vendor/profile';
  static const String getVenueData = 'http://165.232.152.77/mobi/api/vendor/venues';
  static const String removeVenue = 'http://165.232.152.77/mobi/api/vendor/venues';
  static const String updateVenue = 'http://165.232.152.77/mobi/api/vendor/venues';
  static const String venueList = 'http://165.232.152.77/mobi/api/vendor/venues';
}

// Permissions placeholder
class UserPermissions {
  static void getAssignedPermissions(String? userId) {}
  static bool hasPermission(String permission) => true;
}

// Reusable card wrapper widget
Widget cardWrapper({
  required Widget child,
  double borderRadius = 15,
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
    _timer = Timer(const Duration(seconds: 5), () {
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
      final response =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
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

      final response = await makeApiRequest(url: Server.getProfile, headers: headers);

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

      final response = await makeApiRequest(url: Server.categoryList, headers: headers);

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
          Fluttertoast.showToast(msg: 'No venues found for this category');
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

      // Use DELETE method
      final response = await http.delete(
        Uri.parse('${Server.removeVenue}/$removeVenueId'),
        headers: headers,
      );

      final responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        setState(() {
          allData.removeWhere(
              (element) => element['id'].toString() == removeVenueId);
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
        var errorMessage = responseData['message'] ??
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

  void editVenue(Map<String, dynamic> item) {
    if (!UserPermissions.hasPermission('edit_venue')) {
      Fluttertoast.showToast(msg: "You don't have access to this feature!");
      return;
    }
    final categoryId = item['category_id']?.toString() ?? categoryList[cardPosition]['id'].toString();

    // Navigate to the EditVenueScreen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVenueScreen(
          venueData: Map<String, dynamic>.from(item),
          categoryId: categoryId,
        ),
      ),
    ).then((updatedVenue) {
      if (updatedVenue != null && updatedVenue is Map<String, dynamic>) {
        final index = allData.indexWhere((v) => v['id']?.toString() == item['id']?.toString());
        if (index != -1) {
          setState(() {
            allData[index] = Map<String, dynamic>.from(allData[index])
              ..addAll(updatedVenue);
          });
        } else {
          getUserId().then((uid) => getVenueData(uid, categoryId));
        }
      }
    });
  }

  // Updated qrCodeBtn using QrImageView for QR code display.
  void qrCodeBtn(Map<String, dynamic> item) {
    final String qrData = item['qrData'] ?? item['id'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("QR Code"),
          content: SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
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

    return GestureDetector(
      onTap: () => clickCategoryItem(item, index),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            cardWrapper(
              borderRadius: 50,
              elevation: isSelected ? 0 : 5,
              color: bgColor,
              child: SizedBox(
                width: 50,
                height: 50,
                child: Image.network(
                  item['icon'] ?? 'https://picsum.photos/50',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 75,
              child: Text(
                item['name'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: Design.font11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.all(8.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item['images'] != null && item['images'].isNotEmpty
                      ? item['images'][0]['image']
                      : 'https://picsum.photos/90',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(
                          GlobalImages.location,
                          width: 12,
                          height: 12,
                          color: Design.lightGrey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: InkWell(
                            onTap: () => locationBtn(
                              item['lat']?.toString() ?? '0.0',
                              item['lon']?.toString() ?? '0.0',
                              item['location'] ?? 'Unknown',
                            ),
                            child: Text(
                              item['location'] ?? 'No location',
                              style: TextStyle(
                                fontSize: Design.font12,
                                color: Design.lightGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: cardWrapper(
                            borderRadius: 30,
                            elevation: 2,
                            child: InkWell(
                              onTap: () => editVenue(item),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Text(
                                  'Edit Info',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: Design.font13,
                                    color: Design.lightBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: cardWrapper(
                            borderRadius: 30,
                            elevation: 2,
                            color: Design.lightPink,
                            child: InkWell(
                              onTap: () {
                                if (!UserPermissions.hasPermission('remove_venue')) {
                                  Fluttertoast.showToast(msg: "You don't have access to this feature!");
                                  return;
                                }
                                setState(() {
                                  removeVenueId = item['id'].toString();
                                  dialogAlert = true;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 6),
                                    Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontSize: Design.font13,
                                        color: Design.darkPink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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
    return Scaffold(
      backgroundColor: Design.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                cardWrapper(
                  borderRadius: 20,
                  elevation: 5,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Image.asset(GlobalImages.back, width: 30, height: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "All Venues",
                                style: TextStyle(fontSize: Design.font20, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 50),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$greeting,', style: const TextStyle(fontSize: Design.font20)),
                                  Text(
                                    '$firstName $lastName',
                                    style: const TextStyle(fontSize: Design.font20, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 130,
                        child: loader && categoryList.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : categoryList.isEmpty
                                ? const Center(child: Text('No Categories Found'))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    itemCount: categoryList.length,
                                    itemBuilder: (context, index) {
                                      final item = categoryList[index];
                                      return buildCategoryItem(item, index);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: loader && allData.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : allData.isEmpty
                          ? Center(
                              child: Text(
                                'No Venues Found in ${categoryList.isNotEmpty ? categoryList[cardPosition]['name'] : 'Selected Category'}',
                                style: const TextStyle(fontSize: Design.font20, color: Design.lightGrey),
                              ),
                            )
                          : Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                                  child: Text(
                                    'Venues in ${categoryList[cardPosition]['name']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    itemCount: allData.length,
                                    itemBuilder: (context, index) {
                                      final item = allData[index];
                                      return buildVenueItem(item);
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
            if (dialogAlert)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Design.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Are you sure you want to Remove Venue?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: Design.font15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: removeVenueBtn,
                            style: ElevatedButton.styleFrom(backgroundColor: Design.primaryColorOrange),
                            child: const Text('Yes'),
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() => dialogAlert = false),
                            style: OutlinedButton.styleFrom(foregroundColor: Design.primaryColorOrange),
                            child: const Text('No'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (loader)
              Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
