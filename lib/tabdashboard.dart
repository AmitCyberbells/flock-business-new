import 'package:flutter/material.dart';
import 'dart:io';

// Import your screens as needed.
import 'package:flock/add_offer.dart';
import 'package:flock/add_venue.dart' as addVenue;
import 'package:flock/profile_screen.dart' as profile;
import 'package:flock/send_notifications.dart';
import 'package:flock/venue.dart' as venue;

// Dummy screen for check-in navigation.
class CheckInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Check In")));
  }
}

// TabDashboard widget with the bottom footer integrated.
class TabDashboard extends StatelessWidget {
  const TabDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Replace or update the body as needed.
      body: Center(child: Text("Tab Dashboard Content")),
      // Floating action button used for additional actions.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show modal bottom sheet with extra options.
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  ListTile(
                    leading: Icon(Icons.apartment, color: Colors.blue),
                    title: Text("Add Venues"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => addVenue.AddEggScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.percent, color: Colors.blue),
                    title: Text("Add Offers"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddOfferScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: Colors.blue),
                    title: Text("Send Notification"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SendNotificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.white,
        child: Image.asset(
          'assets/botom_bird.png',
          fit: BoxFit.contain
         
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}

// Reusable bottom navigation bar widget.
class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left side navigation items.
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.grid_view_rounded, color: Colors.orange),
                  onPressed: () => _navigateTo(context, TabDashboard()),
                ),
                IconButton(
                  icon: Icon(Icons.apartment, color: Colors.grey),
                  onPressed: () => _navigateTo(context, venue.TabEggScreen()),
                ),
              ],
            ),
            // Right side navigation items.
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.login_outlined, color: Colors.grey),
                  onPressed: () => _navigateTo(context, CheckInScreen()),
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Colors.grey),
                  onPressed: () => _navigateTo(context, profile.TabProfile()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy screens for navigation from the modal bottom sheet.
class AddOfferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Add Offer")));
  }
}

class SendNotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Send Notification")));
  }
}
