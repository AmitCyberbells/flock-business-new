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
  static final AssetImage _bird=const AssetImage('assets/bird.png');
  final Widget body;
  final int currentIndex;

  const CustomScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
  }) : super(key: key);
  
  BuildContext get context => context;

  @override
  Widget build(BuildContext context) {
    precacheImage(_bird, context); //add not to reload
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Background layer
       Container(decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor)),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(top: true, bottom: true, child: body),
          floatingActionButtonLocation: _CustomFABLocation(),
          floatingActionButton: GestureDetector(
            onTap: () {
       showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.14, // Adjust position just above bottom bar
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            child: GestureDetector(
              onTap: () {}, // Prevent tap-through to dismiss
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
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
              ),
            ),
          ),
        ],
      ),
    );
  },
);

            },
            child: Center(
              child: Image(
               image: _bird,
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
              ),
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
    Color? backgroundColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.02,
          horizontal: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.surface,
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
    if (index == currentIndex) return; // Prevent unnecessary navigation
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          // Use pushReplacement to avoid stack buildup
          context,
          MaterialPageRoute(builder: (context) => TabDashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => venue.TabEggScreen()),
        );
        break;
      case 2: //bird
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CheckInsScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
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
final Brightness brightness = Theme.of(context).brightness;
final Color activeColor = brightness == Brightness.dark
    ? const Color.fromRGBO(255, 255, 255, 1) // White in dark mode
    : Colors.black; // Black in light mode
    final Color inactiveColor = color;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () => _onItemTapped(context, index),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.005,
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
            SizedBox(height: screenWidth * 0.004),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: screenWidth * 0.032,
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
  Theme.of(context).colorScheme.brightness == Brightness.dark
      ? 'assets/bottom_nav_dark.png'
      : 'assets/bottom_nav.png',
  fit: BoxFit.cover,
  height: screenHeight * 0.16,
),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.04,
              left: screenWidth * 0.05,
              right: screenWidth * 0.03,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
         _buildNavItem(
  context,
  icon: Icons.grid_view_rounded,
  label: "Dashboard",
  index: 0,
  color: Theme.of(context).brightness == Brightness.dark
      ? const Color.fromRGBO(255, 130, 16, 1) // Orange in dark mode
      : Colors.black, // Black in light mode
),

                _buildNavItem(
                  context,
                  icon: Icons.apartment,
                  label: "Venues",
                  index: 1,
                   color: Theme.of(context).brightness == Brightness.dark
      ? const Color.fromRGBO(255, 130, 16, 1) // Orange in dark mode
      : Colors.black, // Black in light mode
                ),

                SizedBox(width: screenWidth * 0.2),
                _buildNavItem(
                  context,
                  icon: Icons.login_outlined,
                  label: "Check In",
                  index: 3,
                   color: Theme.of(context).brightness == Brightness.dark
      ? const Color.fromRGBO(255, 130, 16, 1) // Orange in dark mode
      : Colors.black, // Black in light mode
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person,
                  label: "My Profile",
                  index: 4,

                   color: Theme.of(context).brightness == Brightness.dark
      ? const Color.fromRGBO(255, 130, 16, 1) // Orange in dark mode
      : Colors.black, // Black in light mode
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}