import 'package:flock/HomeScreen.dart';
import 'package:flock/add_offer.dart';
import 'package:flock/send_notifications.dart';

import 'package:flutter/material.dart';

import 'package:flock/add_venue.dart' as addVenue;
import 'package:flock/checkIns.dart';
import 'package:flock/profile_screen.dart' as profile;
import 'package:flock/venue.dart' as venue;

// Reusable bottom navigation bar widget.
class CustomScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  const CustomScaffold({Key? key, required this.body, required this.currentIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
          body: Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/bottom_nav.png', // Your background image
            fit: BoxFit.cover, // Ensures the image covers the entire screen
          ),
        ),
        // Main content
        body,
      ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent, // No background color for the bottom sheet
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row for Add Venues and Add Offers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Add Venues Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.apartment,
                            label: "Add Venues",
                            iconColor: Colors.blue,
                            textColor: Colors.blue[900]!,
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => addVenue.AddEggScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Add Offers Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.percent,
                            label: "Add Offers",
                            iconColor: Colors.blue,
                            textColor: Colors.blue[900]!,
                            borderColor: Colors.blue, // Add a border to differentiate
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddOfferScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Send Notification Button (full width)
                  Padding(
  padding: const EdgeInsets.only(bottom: 28.0), // Adjust as needed
  child: _buildActionButton(
    context: context,
    icon: Icons.notifications,
    label: "Send Notification",
    iconColor: Colors.blue,
    textColor: Colors.blue[900]!,
    backgroundColor: Colors.white.withOpacity(0.9),
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
),

                  ],
                ),
              );
            },
          );
        },
        child: Image.asset(
          'assets/bird.png',
          fit: BoxFit.contain,
          width: 35,
          height: 35,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomBar(currentIndex: currentIndex),
    );
  }

  // Helper method to build each action button
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    Color backgroundColor = Colors.white,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
