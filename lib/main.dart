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
import 'login_screen.dart';
import 'checkIns.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Notification model to store notification data
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? screen;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.screen,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'screen': screen,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        screen: json['screen'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'],
      );
}

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.toMap()}');
  
  // Store notification locally
  await _storeNotification(message);
}

// Store notification in SharedPreferences
Future<void> _storeNotification(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final notification = NotificationModel(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: message.notification?.title ?? message.data['title'] ?? 'New Notification',
    body: message.notification?.body ?? message.data['body'] ?? 'No details available',
    screen: message.data['screen'],
    timestamp: DateTime.now(),
  );
  
  List<String> notifications = prefs.getStringList('notifications') ?? [];
  notifications.add(jsonEncode(notification.toJson()));
  await prefs.setStringList('notifications', notifications);
  print('Stored notification: ${notification.toJson()}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print("Firebase has been initialized successfully.");

    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

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
        primaryColor: const Color.fromRGBO(255, 130, 16, 1),
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
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black54),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black54, width: 2.0),
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
  int _unreadNotifications = 0;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _setupFCM();
    _loadNotifications();
    _checkLoginStatus();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationStrings = prefs.getStringList('notifications') ?? [];
    final notifications = notificationStrings
        .map((string) => NotificationModel.fromJson(jsonDecode(string)))
        .toList();
    setState(() {
      _notifications = notifications;
      _unreadNotifications = notifications.where((n) => !n.isRead).length;
    });
    print('Loaded ${_notifications.length} notifications, $_unreadNotifications unread');
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      // Request permission for iOS
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // Get and save FCM token
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _sendTokenToBackend(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await _sendTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Foreground message received: ${message.toMap()}');
        await _storeNotification(message);
        setState(() {
          _notifications.add(
            NotificationModel(
              id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: message.notification?.title ?? message.data['title'] ?? 'New Notification',
              body: message.notification?.body ?? message.data['body'] ?? 'No details available',
              screen: message.data['screen'],
              timestamp: DateTime.now(),
            ),
          );
          _unreadNotifications = _notifications.where((n) => !n.isRead).length;
        });

        // Show SnackBar with a valid ScaffoldMessenger
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification?.title ?? message.data['title'] ?? 'Notification'}: '
                '${message.notification?.body ?? message.data['body'] ?? 'Tap to view'}',
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 5),
              action: message.data['screen'] != null
                  ? SnackBarAction(
                      label: 'View',
                      textColor: Colors.white,
                      onPressed: () => _handleMessageNavigation(message),
                    )
                  : null,
            ),
          );
        }
      });

      // Handle messages when app is opened from a terminated state
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('Initial message received: ${initialMessage.toMap()}');
        await _storeNotification(initialMessage);
        await _loadNotifications();
        _handleMessageNavigation(initialMessage);
      }

      // Handle messages when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        print('Message opened from background: ${message.toMap()}');
        await _markNotificationAsRead(message.messageId);
        _handleMessageNavigation(message);
      });
    } catch (e) {
      print('Error setting up FCM: $e');
    }
  }

  Future<void> _markNotificationAsRead(String? messageId) async {
    if (messageId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final notificationStrings = prefs.getStringList('notifications') ?? [];
    final notifications = notificationStrings
        .map((string) => NotificationModel.fromJson(jsonDecode(string)))
        .toList();
    
    final updatedNotifications = notifications.map((n) {
      if (n.id == messageId) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          body: n.body,
          screen: n.screen,
          timestamp: n.timestamp,
          isRead: true,
        );
      }
      return n;
    }).toList();
    
    await prefs.setStringList(
      'notifications',
      updatedNotifications.map((n) => jsonEncode(n.toJson())).toList(),
    );
    
    setState(() {
      _notifications = updatedNotifications;
      _unreadNotifications = updatedNotifications.where((n) => !n.isRead).length;
    });
    print('Marked notification $messageId as read, $_unreadNotifications unread remaining');
  }

  void _handleMessageNavigation(RemoteMessage message) {
    // Only navigate if user is logged in
    final screen = message.data['screen'];
    if (screen == 'checkin' || screen == 'offers') {
      SharedPreferences.getInstance().then((prefs) {
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        if (isLoggedIn && mounted) {
          Navigator.pushNamed(context, screen == 'checkin' ? '/tab_checkin' : '/offers');
        }
      });
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      print('No access token available, storing FCM token for later');
      await prefs.setString('fcm_token', token);
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://165.232.152.77/api/vendor/devices/update'),
      );

      request.headers.addAll({'Authorization': 'Bearer $accessToken'});

      request.fields['type'] = 'android';
      request.fields['token'] = token;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Send token response: ${response.statusCode} $responseBody');

      if (response.statusCode == 200) {
        print('FCM token sent to backend successfully');
        await prefs.remove('fcm_token'); // Clear stored token
      } else {
        print('Failed to send FCM token: ${response.statusCode}');
        try {
          final responseData = jsonDecode(responseBody);
          print('Error: ${responseData['message'] ?? 'Unknown error'}');
        } catch (e) {
          print('Error decoding response: $e');
        }
      }
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    // Wait for notifications to load
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final token = prefs.getString('access_token');

    // Retry sending stored FCM token if available
    final fcmToken = prefs.getString('fcm_token');
    if (fcmToken != null && isLoggedIn && token != null) {
      await _sendTokenToBackend(fcmToken);
    }

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
    return Scaffold(
      body: Stack(
        children: [
          const Center(child: CircularProgressIndicator()),
          if (_unreadNotifications > 0)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unreadNotifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_notifications.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification.body),
                      trailing: notification.isRead
                          ? null
                          : const Icon(Icons.circle, color: Colors.red, size: 10),
                      onTap: () {
                        _markNotificationAsRead(notification.id);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}