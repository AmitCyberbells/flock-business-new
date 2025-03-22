import 'package:flock/DeleteAccountScreen.dart';
import 'package:flock/ForgotPasswordScreen.dart';
import 'package:flock/HomeScreen.dart';
import 'package:flock/changePassword.dart';
import 'package:flock/editProfile.dart';
import 'package:flock/feedback.dart';
import 'package:flock/openHours.dart';
import 'package:flock/registration_screen.dart';
import 'package:flock/staffManagement.dart';
import 'package:flock/tutorial.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flock Login',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const LoginScreen(),
      routes: {
      '/forgot-password': (context) => ForgotPasswordScreen(),
      '/home': (context) => TabDashboard(),
      '/EditProfile': (context) => EditProfileScreen(),
      '/staffManage': (context) => StaffManagementScreen(),
      '/changePassword': (context) => ChangePasswordScreen(),
      '/openHours'  : (context) => OpenHoursScreen(),
      '/feedback'  : (context) => ReportScreen(),
      '/DeleteAccount'  : (context) => DeleteAccountScreen(),
      '/tutorials'  : (context) => TutorialsScreen(),
      '/Login'  : (context) => LoginScreen(),
      '/tab_checkin': (context) => CheckInScreen(),
      '/register': (context) => RegisterScreen(),

    },
    );
  }
}
