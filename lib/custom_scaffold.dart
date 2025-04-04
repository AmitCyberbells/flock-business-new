import 'package:flutter/material.dart';
import 'package:flock/add_offer.dart';
import 'package:flock/send_notifications.dart';
import 'package:flock/add_venue.dart' as addVenue;
import 'package:flock/venue.dart' as venue;
import 'package:flock/checkIns.dart';
import 'package:flock/profile_screen.dart' as profile hide TabEggScreen;
import 'package:flock/HomeScreen.dart';

class _CustomFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    final double fabY =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height / 2 +
        (scaffoldGeometry.scaffoldSize.height * 0.06);
    return Offset(fabX, fabY);
  }
}

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;

  const CustomScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
  }) : super(key: key);
@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  return Stack(
    children: [
      // Background layer (this fills full screen, behind status bar etc.)
      Container(
        decoration: BoxDecoration(
          color: Colors.white, // change to background image or gradient if needed
        ),
      ),

      // Foreground UI (Scaffold on top)
      Scaffold(
        backgroundColor: Colors.transparent, // Keep it transparent so background shows
        body: SafeArea(
          top: true,
          bottom: true,
          child: body, // Body respects SafeArea, FAB and nav don't need to
        ),
        floatingActionButtonLocation: _CustomFABLocation(),
        floatingActionButton: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (BuildContext context) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.1,
                    horizontal: screenWidth * 0.04,
                  ),
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
                              label: "Add Venue",
                              iconColor: const Color(0xFF2A4CE1),
                              textColor: const Color(0xFF2A4CE1),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => addVenue.AddEggScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.percent,
                              label: "Add Offer",
                              iconColor: const Color(0xFF2A4CE1),
                              textColor: const Color(0xFF2A4CE1),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Image.asset(
            'assets/bird.png',
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
          ),
        ),
        bottomNavigationBar: CustomBottomBar(currentIndex: currentIndex),
      ),
    ],
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
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.03,
          horizontal: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5),
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
            Icon(icon, color: iconColor, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: textColor,
                  fontWeight: FontWeight.w700,
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

  const CustomBottomBar({Key? key, required this.currentIndex})
    : super(key: key);

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
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.015,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: screenWidth * 0.08,
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: screenWidth * 0.025,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const Color iconTextColor = Color.fromRGBO(204, 204, 204, 1);

    return SizedBox(
      height: screenHeight * 0.14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/bottom_nav.png',
              fit: BoxFit.cover,
              height: screenHeight * 0.16,
              colorBlendMode: BlendMode.lighten,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.037,
              left: screenWidth * 0.05,
              right: screenWidth * 0.03,
              // / bottom: screenWidth * 0.05, // Remove unnecessary bottom padding
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                SizedBox(width: screenWidth * 0.12),
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
        ],
      ),
    );
  }
}
