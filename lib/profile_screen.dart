import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    userId = prefs.getString('userid');
    print("Retrieved userId: $userId");
    if (userId != null) {
      setState(() {
        isLoading = true;
      });
      setState(() {
        firstName = prefs.getString('firstName') ?? 'John';
        lastName = prefs.getString('lastName') ?? 'Doe';
        email = prefs.getString('email') ?? 'johndoe@example.com';
        profilePic = prefs.getString('profilePic') ?? '';
        isLoading = false;
      });
      print("Profile fetched - First Name: $firstName, Last Name: $lastName, Email: $email, Profile Pic: $profilePic");
    } else {
      Fluttertoast.showToast(msg: 'Please log in to view profile');
      Navigator.pushReplacementNamed(context, '/Login');
    }
  }

  void logoutButton() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/Login');
    Fluttertoast.showToast(msg: 'Logged out successfully');
  }

  Widget _buildProfileOption({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      currentIndex: 3,
      body: SafeArea(
        child: Container(
           color: Colors.white,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
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
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 60,
                       backgroundColor: Colors.grey.shade200,
                      child: profilePic.isEmpty
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
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading profile image: $error");
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? 'Email not available' : email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
                          onTap: () => Navigator.pushNamed(context, '/staffManage'),
                        ),
                        _buildProfileOption(
                          title: "Change Password",
                          onTap: () => Navigator.pushNamed(context, '/changePassword'),
                        ),
                        _buildProfileOption(
                          title: "History",
                          onTap: () => Navigator.pushNamed(context, '/HistoryScreen'),
                        ),
                        _buildProfileOption(
                          title: "Open Hours",
                          onTap: () => Navigator.pushNamed(context, '/openHours'),
                        ),
                        _buildProfileOption(
                          title: "How to ?",
                          onTap: () => Navigator.pushNamed(context, '/tutorials'),
                        ),
                        _buildProfileOption(
                          title: "Feedback",
                          onTap: () => Navigator.pushNamed(context, '/feedback'),
                        ),
                        _buildProfileOption(
                          title: "Delete Account",
                          onTap: () => Navigator.pushNamed(context, '/DeleteAccount'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: logoutButton,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 152, 0, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}