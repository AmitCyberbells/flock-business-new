import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// For local data storage (replacing AsyncStorage)
import 'package:shared_preferences/shared_preferences.dart';
// If you want an animated loader like in your RN code, you can use Lottie
import 'package:lottie/lottie.dart';

// Placeholder classes for your design tokens, images, server endpoints, etc.
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

class GlobalImages {
  static const String back = 'assets/back.png';
  static const String location = 'assets/location.png';
  static const String dateTime = 'assets/datetime.png';
  static const String edit = 'assets/edit.png';
  static const String delete = 'assets/delete.png';
  static const String dropDown = 'assets/drop_down.png';
  static const String dropUp = 'assets/drop_up.png';
}

class Server {
  static const String categoryList = 'https://example.com/categorylist';
  static const String getProfile = 'https://example.com/getprofile';
  static const String getVenueData = 'https://example.com/getvenuedata';
  static const String removeVenue = 'https://example.com/removevenue';
  static const String venueList = 'https://example.com/venuelist';
}

// Placeholder for your permission system
class UserPermissions {
  static void getAssignedPermissions(String? userId) {
    // Implement your permission logic
  }

  static bool hasPermission(String permission) {
    // Return true/false based on real logic
    return true;
  }
}

// Placeholder for your network request logic
class ApiRequest {
  static Future<void> postRequestWithoutToken(
    String url,
    Map<String, dynamic> data,
    Function(dynamic response, dynamic error) callback,
  ) async {
    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));
    // Return a mock response
    callback({'status': 'success'}, null);
  }
}

// A basic "card" wrapper using Container + BoxShadow
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

// Main screen replicating Tab_Egg
class TabEggScreen extends StatefulWidget {
  const TabEggScreen({Key? key}) : super(key: key);

  @override
  State<TabEggScreen> createState() => _TabEggScreenState();
}

class _TabEggScreenState extends State<TabEggScreen> {
  // React Native states -> Flutter fields
  bool loader = false;
  bool dialogAlert = false;

  // The ID of the venue to remove
  String removeVenueId = '';

  // For greeting
  String greeting = '';
  String firstName = '';
  String lastName = '';

  // For category list
  List<dynamic> categoryList = [];
  int cardPosition = 0; // which category is selected

  // For venue list
  List<dynamic> allData = [];

  // Timer for loader
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    computeGreeting();
    fetchUserId();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void computeGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
  }

  Future<void> fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid') ?? '';
    // Load profile, category list, etc.
    getProfile(userId);
    UserPermissions.getAssignedPermissions(userId);
    getCategoryList(userId);
  }

  void startLoader() {
    setState(() => loader = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      setState(() => loader = false);
    });
  }

  void getProfile(String userId) {
    startLoader();
    final data = {'user_id': userId};

    ApiRequest.postRequestWithoutToken(Server.getProfile, data,
        (response, error) {
      setState(() => loader = false);
      if (response != null && response['status'] == 'success') {
        // Mock: set firstName, lastName
        setState(() {
          firstName = 'John';
          lastName = 'Doe';
        });
      } else {
        Fluttertoast.showToast(msg: 'Error fetching profile');
      }
    });
  }

  void getCategoryList(String userId) {
    startLoader();
    ApiRequest.postRequestWithoutToken(Server.categoryList, {}, (res, err) {
      setState(() => loader = false);
      if (res != null && res['status'] == 'success') {
        // Mock categories
        setState(() {
          categoryList = [
            {
              'id': '1',
              'name': 'Bars',
              'image':
                  'https://cdn-icons-png.flaticon.com/512/2931/2931506.png'
            },
            {
              'id': '2',
              'name': 'Restaurants',
              'image':
                  'https://cdn-icons-png.flaticon.com/512/3075/3075937.png'
            },
            {
              'id': '3',
              'name': 'Cafes',
              'image':
                  'https://cdn-icons-png.flaticon.com/512/3075/3075925.png'
            },
          ];
        });
        if (categoryList.isNotEmpty) {
          final categoryId = categoryList[cardPosition]['id'];
          getVenueData(userId, categoryId);
        }
      } else {
        Fluttertoast.showToast(msg: 'Error loading categories');
      }
    });
  }

  void getVenueData(String userId, String categoryId) {
    startLoader();
    final data = {
      'user_id': userId,
      'cat_id': categoryId,
      'user_type': 'vendor',
    };
    ApiRequest.postRequestWithoutToken(Server.getVenueData, data, (res, err) {
      setState(() => loader = false);
      if (res != null && res['status'] == 'success') {
        // Mock list of venues
        setState(() {
          allData = [
            {
              'venue_id': '101',
              'venue_name': 'Sample Venue A',
              'image':
                  'https://images.unsplash.com/photo-1566843976517-d51fe2c90f40',
              'location': '123 Street, City',
              'lat': '12.34',
              'lon': '56.78',
              'approval': '1',
              'date': '2025-03-21',
            },
            {
              'venue_id': '102',
              'venue_name': 'Sample Venue B',
              'image':
                  'https://images.unsplash.com/photo-1551782450-17144c3fa673',
              'location': '456 Road, City',
              'lat': '23.45',
              'lon': '67.89',
              'approval': '0', // In Review
              'date': '2025-03-20',
            },
          ];
        });
      } else {
        Fluttertoast.showToast(msg: 'Error loading venues');
      }
    });
  }

  // When tapping a category
  void clickCategoryItem(dynamic item, int index) {
    setState(() {
      cardPosition = index;
    });
    final categoryId = item['id'];
    // Get venue data again
    SharedPreferences.getInstance().then((prefs) {
      final userId = prefs.getString('userid') ?? '';
      getVenueData(userId, categoryId);
    });
  }

  // Remove venue
  void removeVenueBtn() {
    startLoader();
    final data = {'venue_id': removeVenueId};
    ApiRequest.postRequestWithoutToken(Server.removeVenue, data, (res, err) {
      setState(() {
        loader = false;
        dialogAlert = false;
      });
      if (res != null && res['status'] == 'success') {
        Fluttertoast.showToast(msg: 'Venue removed successfully');
        // Refresh or remove from the allData list
        setState(() {
          allData.removeWhere(
              (element) => element['venue_id'] == removeVenueId);
        });
      } else {
        Fluttertoast.showToast(msg: 'Error removing venue');
      }
    });
  }

  // Edit venue
  void editVenue(Map<String, dynamic> item) {
    if (!UserPermissions.hasPermission('edit_venue')) {
      Fluttertoast.showToast(msg: "You don't have access to this feature!");
      return;
    }
    // Navigate to "AddEgg" screen with item
    Navigator.pushNamed(context, '/AddEgg', arguments: item);
  }

  // Show QR code
  void qrCodeBtn(Map<String, dynamic> item) {
    // Example route
    Navigator.pushNamed(context, '/QRCodeScreen', arguments: {
      'venueId': item['venue_id'],
    });
  }

  // Open location in maps
  void locationBtn(String lat, String lon, String label) {
    final latNum = double.tryParse(lat) ?? 0.0;
    final lonNum = double.tryParse(lon) ?? 0.0;
    final scheme = Platform.isIOS ? 'maps://?daddr=' : 'geo:';
    final uri = '$scheme$latNum,$lonNum';
    // or use url_launcher
    // For now, just show a toast
    Fluttertoast.showToast(msg: 'Open map for $label at ($lat, $lon)');
  }

  // UI for category item (horizontal list)
  Widget buildCategoryItem(dynamic item, int index) {
    final isSelected = (cardPosition == index);
    final colors = ["#FBDFC3", "#CAD2F7", "#C3CFD6", "#FEF2BF"];
    final bgColor = Color(int.parse('0xff${colors[index % 4].substring(1)}'));

    return GestureDetector(
      onTap: () => clickCategoryItem(item, index),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: isSelected
            ? cardWrapper(
                borderRadius: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    cardWrapper(
                      borderRadius: 50,
                      color: bgColor,
                      elevation: 0,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(
                          item['image'],
                          width: 25,
                          height: 25,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: Design.font11),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  cardWrapper(
                    borderRadius: 50,
                    color: bgColor,
                    elevation: 5,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.network(
                        item['image'],
                        width: 25,
                        height: 25,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['name'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: Design.font11),
                  ),
                ],
              ),
      ),
    );
  }

  // UI for a single venue (vertical list)
  Widget buildVenueItem(Map<String, dynamic> item) {
    return cardWrapper(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Venue image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item['image'],
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: venue name + QR code or (In Review)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['venue_name'],
                          style: const TextStyle(
                            fontSize: Design.font17,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                          child: Text(
                            'QR Code',
                            style: TextStyle(
                              fontSize: Design.font12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location row
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
                          onTap: () =>
                              locationBtn(item['lat'], item['lon'], item['location']),
                          child: Text(
                            item['location'],
                            style: TextStyle(
                              fontSize: Design.font12,
                              color: Design.lightGrey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Date row
                  Row(
                    children: [
                      Image.asset(
                        GlobalImages.dateTime,
                        width: 12,
                        height: 12,
                        color: Design.lightGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item['date'] ?? '',
                        style: TextStyle(
                          fontSize: Design.font12,
                          color: Design.lightGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Buttons row: Edit Info / Remove
                  Row(
                    children: [
                      Expanded(
                        child: cardWrapper(
                          borderRadius: 30,
                          elevation: 2,
                          child: InkWell(
                            onTap: () => editVenue(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    GlobalImages.edit,
                                    width: 18,
                                    height: 18,
                                    color: Design.lightBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Edit Info',
                                    style: TextStyle(
                                      fontSize: Design.font13,
                                      color: Design.lightBlue,
                                    ),
                                  ),
                                ],
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
                                Fluttertoast.showToast(
                                  msg: "You don't have access to this feature!",
                                );
                                return;
                              }
                              setState(() {
                                removeVenueId = item['venue_id'];
                                dialogAlert = true;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    GlobalImages.delete,
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 6),
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
    );
  }

  // The main build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Design.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Card with greeting + category list
                cardWrapper(
                  borderRadius: 20,
                  elevation: 5,
                  child: Column(
                    children: [
                      // If you want a back button only sometimes:
                      // This checks some condition like your "value == egg"
                      // For simplicity, let's always show the back arrow:
                      Row(
                        children: [
                          IconButton(
                            icon: Image.asset(
                              GlobalImages.back,
                              width: 30,
                              height: 30,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "All Venues",
                                style: TextStyle(
                                  fontSize: Design.font20,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                  Text(
                                    '$greeting,',
                                    style: const TextStyle(
                                      fontSize: Design.font20,
                                    ),
                                  ),
                                  Text(
                                    '$firstName $lastName',
                                    style: const TextStyle(
                                      fontSize: Design.font20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Horizontal category list
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
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
                // Venues list
                Expanded(
                  child: allData.isEmpty
                      ? const Center(
                          child: Text(
                            'No Data Found...',
                            style: TextStyle(
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
                                  left: 16, top: 8, bottom: 4),
                              child: const Text(
                                'All Venues',
                                style: TextStyle(
                                  // fontSize: Design.font18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 10),
                                itemCount: allData.length,
                                itemBuilder: (context, index) {
                                  final item = allData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: buildVenueItem(item),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            // Loader overlay
            if (loader)
              Container(
                color: Colors.black12,
                child: Center(
                  // Example using Lottie asset
                  child: SizedBox(
                    width: 100,
                    height: 100,
                     child: Lottie.asset('assets/loader.json'), 
                  ),
                ),
              ),

            // Remove-venue confirmation dialog
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
                        style: TextStyle(
                          fontSize: Design.font15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: removeVenueBtn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Design.primaryColorOrange,
                            ),
                            child: const Text('Yes'),
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() => dialogAlert = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Design.primaryColorOrange,
                            ),
                            child: const Text('No'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



