import 'package:flock/DeleteAccountScreen.dart';
import 'package:flock/ForgotPasswordScreen.dart';
import 'package:flock/HomeScreen.dart';
import 'package:flock/app_colors.dart';
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
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'checkIns.dart';
import 'profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  
  runApp(
    
    MultiProvider(
      providers: [
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
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.black,
    selectionColor: AppColors.primary.withOpacity(0.2),
    selectionHandleColor: AppColors.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary),
    ),
  ),

    // ✅ Add this block for global TextField styling
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: const TextStyle(
      color: Colors.black54,
    ),
    floatingLabelStyle: TextStyle(
      color: Colors.black54,
      fontWeight: FontWeight.w600,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.black54,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
       color: Colors.black54,
        width: 2.0,
      ),
    ),
  ),
),


      home: const LoadingScreen(),
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
        '/login': (context) => const LoginScreen(),
        '/tab_checkin': (context) => const CheckInsScreen(),
        '/register': (context) => const RegisterScreen(),
        '/tab_egg': (context) => const TabEggScreen(),
        '/faq': (context) => FaqScreen(),
        '/offers': (context) => const OffersScreen(),
        '/HistoryScreen': (context) => const HistoryScreen(),
      },
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final token = prefs.getString('access_token');

    if (mounted) {
      if (isLoggedIn && token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}