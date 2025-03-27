import 'package:flock/DeleteAccountScreen.dart';
import 'package:flock/ForgotPasswordScreen.dart';
import 'package:flock/HomeScreen.dart';
import 'package:flock/changePassword.dart';
import 'package:flock/editProfile.dart';
import 'package:flock/faq.dart';
import 'package:flock/feedback.dart';
import 'package:flock/history.dart';
import 'package:flock/offers.dart';
import 'package:flock/openHours.dart';
import 'package:flock/registration_screen.dart';
import 'package:flock/staffManagement.dart';
import 'package:flock/tutorial.dart';
import 'package:flock/venue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'login_screen.dart';
import 'checkIns.dart';
import 'profile_provider.dart'; // Import your ProfileProvider

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Add your providers here
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
        '/EditProfile': (context) => const EditProfileScreen(),
        '/staffManage': (context) => const StaffManagementScreen(),
        '/changePassword': (context) => const ChangePasswordScreen(),
        '/openHours': (context) => const OpenHoursScreen(),
        '/feedback': (context) => const ReportScreen(),
        '/DeleteAccount': (context) => const DeleteAccountScreen(),
        '/tutorials': (context) => const TutorialsScreen(),
        '/Login': (context) => const LoginScreen(),
        '/tab_checkin': (context) => const CheckInsScreen(),
        '/register': (context) => const RegisterScreen(),
        '/tab_egg':(context) => const TabEggScreen(),
        '/faq': (context) =>  FaqScreen(),
        '/offers': (context) => const OffersScreen(),
        '/HistoryScreen':(context) => const CheckinHistoryScreen(),
      },
    );
  }
}