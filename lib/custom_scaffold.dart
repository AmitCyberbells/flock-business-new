import 'package:flutter/material.dart';
import 'package:flock/add_offer.dart';
import 'package:flock/send_notifications.dart';
import 'package:flock/add_venue.dart' as addVenue;
import 'package:flock/venue.dart' as venue;
import 'package:flock/checkIns.dart';
import 'package:flock/profile_screen.dart' as profile hide TabEggScreen;
import 'package:flock/HomeScreen.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  const CustomScaffold({Key? key, required this.body, required this.currentIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.apartment,
                            label: "Add Venues",
                            iconColor: Colors.blue,
                            textColor: Colors.blue[900]!,
                            onTap: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => addVenue.AddEggScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.percent,
                            label: "Add Offers",
                            iconColor: Colors.blue,
                            textColor: Colors.blue[900]!,
                            borderColor: Colors.blue,
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
                    Padding(
                      padding: const EdgeInsets.only(top: 28.0),
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
            Icon(icon, color: iconColor, size: 24),
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

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomBar({Key? key, required this.currentIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TabDashboard()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => venue.TabEggScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckInsScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => profile.TabProfile()),
        );
        break;
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required Color color,
  }) {
    final bool isActive = (currentIndex == index);
    final Color activeColor = Colors.orange;
    final Color inactiveColor = color;
    
    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
Icon(icon, color: isActive ? activeColor : inactiveColor, size: 30),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color iconTextColor = Color.fromRGBO(204, 204, 204, 1);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: Colors.white,
      elevation: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              context,
              icon: Icons.grid_view_rounded,
              label: "Dashboard",
              index: 0,
              color: iconTextColor,
              
            ),
            _buildNavItem(
              context,
              icon: Icons.apartment,
              label: "Venues",
              index: 1,
              color: iconTextColor,
            ),
            const SizedBox(width: 50), // Space for FAB notch
            _buildNavItem(
              context,
              icon: Icons.login_outlined,
              label: "Check In",
              index: 2,
              color: iconTextColor,
            ),
            _buildNavItem(
              context,
              icon: Icons.person,
              label: "My Profile",
              index: 3,
              color: iconTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
