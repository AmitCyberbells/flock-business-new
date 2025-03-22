import 'package:flock/venue.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Permissions {
  static List<String> userPermissions = [];

  static void setPermissions(List<String> permissions) {
    userPermissions = permissions;
  }

  static bool hasPermission(String permission) {
    return userPermissions.contains(permission);
  }

  static Future<void> getAssignedPermissions(String userId) async {
    // Simulate fetching permissions from an API or database
    userPermissions = ['change_password', 'history', 'manage_staff']; 
  }
}

class TabProfile extends StatefulWidget {
  const TabProfile({Key? key}) : super(key: key);

  @override
  _TabProfileState createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  String? userId;
  String? deviceToken;
  bool dialogAlert = false;
  bool loader = false;
  String firstName = '';
  String lastName = '';
  String email = '';
  String profilePic = '';
  String totalFeathers = '';
  String avgFeathers = '';

  @override
  void initState() {
    super.initState();
    detailFunc();
    generateToken();
  }

  Future<void> detailFunc() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userid');
    if (userId != null) {
      getProfile();
      totalFeatherApi();
      Permissions.getAssignedPermissions(userId!);
    }
  }

  Future<void> generateToken() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    String? fcmToken = await firebaseMessaging.getToken();
    if (fcmToken != null) {
      deviceToken = fcmToken;
    }
  }

  void changePassword() {
    if (!Permissions.hasPermission('change_password')) {
      Fluttertoast.showToast(msg: 'You don\'t have access to this feature!');
      return;
    }
    Navigator.pushNamed(context, '/ChangePassword');
  }

  void historyButton() {
    if (!Permissions.hasPermission('history')) {
      Fluttertoast.showToast(msg: 'You don\'t have access to this feature!');
      return;
    }
    Navigator.pushNamed(context, '/HistoryScreen');
  }

  void openHours() {
    if (!Permissions.hasPermission('hours_management')) {
      Fluttertoast.showToast(msg: 'You don\'t have access to this feature!');
      return;
    }
    Navigator.pushNamed(context, '/OpenHoursScreen');
  }

  void manageStaff() {
    if (!Permissions.hasPermission('manage_staff')) {
      Fluttertoast.showToast(msg: 'You don\'t have access to this feature!');
      return;
    }
    Navigator.pushNamed(context, '/StaffScreen');
  }

  void tutorialsPage() {
    if (!Permissions.hasPermission('tutorials')) {
      Fluttertoast.showToast(msg: 'You don\'t have access to this feature!');
      return;
    }
    Navigator.pushNamed(context, '/Tutorials');
  }
void logoutButton() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clear user session data
  Permissions.setPermissions([]); // Reset permissions

  setState(() {
    dialogAlert = false;
  });

  Navigator.pushReplacementNamed(context, '/Login'); // Redirect to login screen
  Fluttertoast.showToast(msg: 'Logged out successfully');
}

  Future<void> logoutApi() async {
    setState(() {
      loader = true;
    });
    // Example of how you might structure your logout request
    // var data = {
    //   'user_id': userId,
    //   'token': deviceToken,
    // };
    // // Call your API here...
    // // On success:
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    // Permissions.setPermissions([]);
    // Navigator.pushReplacementNamed(context, '/Login');

    // For now, just simulate a logout delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      loader = false;
    });
    Fluttertoast.showToast(msg: 'Logged out');
  }

  Future<void> getProfile() async {
    setState(() {
      loader = true;
    });
    // Example of how you might structure your getProfile request
    // var data = {'user_id': userId};
    // // On success:
    // setState(() {
    //   firstName = response['Userdetail']['first_name'];
    //   lastName = response['Userdetail']['last_name'];
    //   email = response['Userdetail']['email'];
    //   profilePic = response['Userdetail']['profileimg'];
    // });
    // For now, just simulate fetching profile data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      loader = false;
      firstName = 'Amit';
      lastName = 'Kumar';
      email = 'iitianamit2019@gmail.com';
      // profilePic = 'https://example.com/profile.jpg'; // example
    });
  }

  Future<void> totalFeatherApi() async {
    setState(() {
      loader = true;
    });
    // Example of how you might structure your totalFeatherApi request
    // var data = {'user_id': userId};
    // // On success:
    // setState(() {
    //   totalFeathers = response['totalfeathers'];
    //   avgFeathers = response['averagefeather'];
    // });
    // For now, just simulate a delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      loader = false;
      totalFeathers = '100';
      avgFeathers = '4.5';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make background white to match your design
      backgroundColor: Colors.white,
      // Remove the default AppBar in favor of a custom header
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Custom header with "My Profile"
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      "My Profile",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Avatar, name, email
                  const SizedBox(height: 10),
                  // If you have a real image, replace with NetworkImage(profilePic)
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    child: profilePic.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : ClipOval(
                            child: Image.network(
                              profilePic,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$firstName $lastName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // White container with the list of profile options
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          title: "Profile Settings",
                          onTap: () => Navigator.pushNamed(context, '/EditProfile'),
                        ),
                        _divider(),
                        _buildListTile(
                          title: "Staff Management",
                           onTap: () => Navigator.pushNamed(context, '/staffManage'),
                        ),
                        _divider(),
                        _buildListTile(
                          title: "Change Password",
                           onTap: () => Navigator.pushNamed(context, '/changePassword'),
                        ),
                        _divider(),
                        _buildListTile(
                          title: "History",
                          onTap: historyButton,
                        ),
                        _divider(),
                        _buildListTile(
                          title: "Open Hours",
                           onTap: () => Navigator.pushNamed(context, '/openHours'),
                        ),
                        _divider(),
                        _buildListTile(
                          title: "How to ?",
                         onTap: () => Navigator.pushNamed(context, '/tutorials'),
                        ),
                        _divider(),
                        _buildListTile(
                          title: "Feedback",
                          onTap: () => Navigator.pushNamed(context, '/feedback'),
                        ),
                        _divider(),
                        _buildListTile(
                          title: "Delete Account",
                          onTap: () => Navigator.pushNamed(context, '/DeleteAccount'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Orange "Log Out" bar at the bottom
                  // If you want a big bar that spans the screen:
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          dialogAlert = true;
                        });
                        logoutButton();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Show a linear loader at the very top if fetching data
            if (loader)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
    
  }
  
}




class TabDashboardBottom extends StatelessWidget {
  const TabDashboardBottom({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                isSelected: true,
                destination: DashboardScreen(),
              ),
              _buildNavItem(
                context,
                icon: Icons.apartment,
                label: 'Venues',
                isSelected: false,
                destination: TabEggScreen(),
              ),
              const Expanded(child: SizedBox()), // Space for center icon
              _buildNavItem(
                context,
                icon: Icons.login_outlined,
                label: 'Check in',
                isSelected: false,
                destination: CheckInScreen(),
              ),
              _buildNavItem(
                context,
                icon: Icons.person,
                label: 'My Profile',
                isSelected: false,
                destination: TabProfile(),
              ),
            ],
          ),
        ),
        
        // Centered circular bird icon (Non-clickable, can be wrapped with GestureDetector if needed)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/bird_icon.png',
                    width: 40,
                    height: 40,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required Widget destination,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateTo(context, destination),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.grey,
              size: 28,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.orange : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy screens for navigation
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Dashboard")));
  }
}

// class VenuesScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(appBar: AppBar(title: Text("Venues")));
//   }
// }

class CheckInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Check In")));
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("My Profile")));
  }
}
