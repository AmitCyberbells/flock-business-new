import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_scaffold.dart';

class TabProfile extends StatefulWidget {
  const TabProfile({Key? key}) : super(key: key);

  @override
  _TabProfileState createState() => _TabProfileState();
}

class _TabProfileState extends State<TabProfile> {
  String? userId;
  bool isLoading = false;
  String firstName = '';
  String lastName = '';
  String email = '';
  String profilePic = '';

  @override
  void initState() {
    super.initState();
    detailFunc();
  }

  Future<void> detailFunc() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      Fluttertoast.showToast(msg: 'Please log in to view profile');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.getflock.io/api/vendor/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = data['data'];

        setState(() {
          firstName = profile['first_name'] ?? 'John';
          lastName = profile['last_name'] ?? 'Doe';
          email = profile['email'] ?? 'johndoe@example.com';
          profilePic = profile['image'] ?? '';
          isLoading = false;
        });

        await prefs.setString('firstName', firstName);
        await prefs.setString('lastName', lastName);
        await prefs.setString('email', email);
        await prefs.setString('profilePic', profilePic);

        print("Profile loaded: $firstName $lastName, $email");
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to fetch profile. Please login again.',
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("Error fetching profile: $e");
      Fluttertoast.showToast(msg: 'Something went wrong.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void logoutButton() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacementNamed(context, '/login');
    Fluttertoast.showToast(msg: 'Logged out successfully');
  }

  Widget _buildProfileOption({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: 6,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Theme.of(context).iconTheme.color,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return CustomScaffold(
      currentIndex: 4,
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Text(
                        "My Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge!.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      child:
                          profilePic.isEmpty
                              ? Image.asset(
                                'assets/profile.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                              : ClipOval(
                                child: Image.network(
                                  profilePic,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) {
                                      // Image is fully loaded
                                      return child;
                                    }
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainer,
                                      child: Center(
                                        child: Image.asset(
                                          'assets/Bird_Full_Eye_Blinking.gif',
                                          width:
                                              60, // Smaller size for profile loader
                                          height: 60,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      "Error loading profile image",
                                    );
                                    return Image.asset(
                                      'assets/profile.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (firstName.isEmpty && lastName.isEmpty)
                          ? 'User Name'
                          : "$firstName $lastName".trim(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? 'Email not available' : email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        _buildProfileOption(
                          title: "Profile Settings",
                          onTap: () async {
                            final updatedProfile = await Navigator.pushNamed(
                              context,
                              '/EditProfile',
                              arguments: {
                                'firstName': firstName,
                                'lastName': lastName,
                                'email': email,
                                'profilePic': profilePic,
                              },
                            );
                            if (updatedProfile != null &&
                                updatedProfile is Map<String, dynamic>) {
                              detailFunc();
                            }
                          },
                        ),
                        _buildProfileOption(
                          title: "Staff Management",
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/staffManage'),
                        ),
                        _buildProfileOption(
                          title: "Change Password",
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/changePassword',
                              ),
                        ),
                        _buildProfileOption(
                          title: " Transaction History",
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/HistoryScreen',
                              ),
                        ),
                        _buildProfileOption(
                          title: "Open Hours",
                          onTap:
                              () => Navigator.pushNamed(context, '/openHours'),
                        ),
                        _buildProfileOption(
                          title: "How to ?",
                          onTap:
                              () => Navigator.pushNamed(context, '/tutorials'),
                        ),
                        _buildProfileOption(
                          title: "Feedback",
                          onTap:
                              () => Navigator.pushNamed(context, '/feedback'),
                        ),
                        _buildProfileOption(
                          title: "Delete Account",
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/DeleteAccount',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 38),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: logoutButton,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            255,
                            130,
                            16,
                            1,
                          ), // Keep constant
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Log Out",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
