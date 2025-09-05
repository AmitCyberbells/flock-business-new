 Flock Business App

A comprehensive Flutter-based business management application designed for venue owners, staff management, and customer engagement. The app provides features for venue management, staff operations, customer check-ins, offers management, and business analytics.

 Project Overview

Version: 20.0.9+106  
Flutter SDK: ^3.7.2  
Platforms: Android, iOS, Web, macOS, Linux, Windows

 Project Structure


flock-business-App/
├── android/                  Android platform-specific code
├── ios/                      iOS platform-specific code
├── lib/                      Main Flutter application code
├── assets/                   Images, icons, and static resources
├── web/                      Web platform configuration
├── macos/                    macOS platform configuration
├── linux/                    Linux platform configuration
├── windows/                  Windows platform configuration
├── test/                     Test files
├── pubspec.yaml             Flutter dependencies and configuration
└── README.md                This file


 Dependencies

 Core Dependencies
- flutter: Main Flutter framework
- cupertino_icons: iOS-style icons
- provider: State management solution
- http: HTTP client for API requests
- dio: Advanced HTTP client with interceptors

 UI & Navigation
- google_maps_flutter: Google Maps integration
- flutter_spinkit: Loading animations
- lottie: Lottie animations support
- cached_network_image: Image caching for network images

 Authentication & Security
- shared_preferences: Local data storage
- permission_handler: Device permissions management
- firebase_core: Firebase core functionality
- firebase_messaging: Push notifications
- firebase_analytics: Analytics tracking

 Media & Files
- image_picker: Image selection from gallery/camera
- video_player: Video playback
- chewie: Video player with controls
- file_picker: File selection

 Location & Maps
- geolocator: Location services
- geocoding: Address geocoding
- google_maps_flutter: Maps integration

 QR & Scanning
- qr_flutter: QR code generation
- mobile_scanner: QR code scanning

 Utilities
- connectivity_plus: Network connectivity monitoring
- workmanager: Background tasks
- intl: Internationalization
- timezone: Timezone handling
- flutter_branch_sdk: Deep linking

 Detailed File Structure

 Main Application Files

 lib/main.dart
The main entry point of the application containing:
- App initialization and configuration
- Theme definitions (light/dark themes)
- Firebase setup
- WorkManager configuration for background tasks
- Deep linking setup with Branch SDK
- Main app routing and navigation structure

 lib/app_colors.dart
Centralized color definitions for the application:
- Primary colors
- Secondary colors
- Background colors
- Text colors
- Status colors

 lib/constants.dart
Application-wide constants including:
- API endpoints
- Configuration values
- Static text strings
- App settings
- Validation rules

 lib/theme.dart
Theme configuration for the application:
- Material theme customization
- Color schemes
- Typography settings
- Component themes

  Core Screens

 lib/HomeScreen.dart
Main dashboard screen featuring:
- Business overview
- Quick actions
- Statistics display
- Navigation to other features
- Recent activity feed

 lib/home_container.dart
Container component for the home screen:
- Wraps the main home content
- Handles navigation state
- Manages screen transitions

 lib/login_screen.dart
User authentication screen with:
- Login form
- Credential validation
- Error handling
- Navigation to registration/forgot password

 lib/registration_screen.dart
User registration screen including:
- Registration form
- Field validation
- Terms acceptance
- Account creation flow

 lib/otp_verification_screen.dart
OTP verification for:
- Email verification
- Phone verification
- Two-factor authentication
- Account activation

  User Management

 lib/profile_screen.dart
User profile management:
- Profile information display
- Edit profile options
- Settings navigation
- Account management

 lib/editProfile.dart
Profile editing functionality:
- Personal information updates
- Avatar management
- Contact details
- Preferences settings

 lib/changePassword.dart
Password change functionality:
- Current password verification
- New password validation
- Security requirements
- Password update

 lib/DeleteAccountScreen.dart
Account deletion process:
- Confirmation dialogs
- Data removal
- Account deactivation
- Final confirmation

 Venue Management

 lib/venue.dart
Main venue management screen:
- Venue listing
- Venue details
- Management options
- Quick actions

 lib/add_venue.dart
Venue creation functionality:
- Venue information form
- Location selection
- Image uploads
- Business details
- Operating hours setup

 lib/edit_venue.dart
Venue editing capabilities:
- Information updates
- Location modifications
- Image management
- Settings changes

 lib/openHours.dart
Operating hours management:
- Weekly schedule setup
- Special hours
- Holiday schedules
- Time zone handling

 Staff Management

 lib/staffManagement.dart
Staff overview and management:
- Staff listing
- Role management
- Performance tracking
- Quick actions

 lib/addStaffMember.dart
Staff member addition:
- Personal information
- Role assignment
- Permissions setup
- Contact details

 lib/editSatffMember.dart
Staff member editing:
- Information updates
- Role modifications
- Permission changes
- Status updates

 lib/editStaffMember.dart
Alternative staff editing interface:
- Simplified editing
- Quick updates
- Basic modifications

  Offers & Promotions

 lib/offers.dart
Offers management screen:
- Current offers listing
- Offer creation
- Status management
- Performance tracking

 lib/add_offer.dart
Offer creation functionality:
- Offer details
- Terms and conditions
- Image uploads
- Scheduling options
- Target audience

 lib/offer_details.dart
Detailed offer view:
- Complete offer information
- Customer interactions
- Analytics data
- Management options

  Business Analytics

 lib/checkIns.dart
Customer check-in tracking:
- Check-in history
- Customer analytics
- Location data
- Time patterns

 lib/history.dart
Business activity history:
- Transaction logs
- Customer interactions
- Revenue tracking
- Performance metrics

 lib/statistics.dart
Business statistics and analytics:
- Revenue charts
- Customer metrics
- Performance indicators
- Trend analysis

  Utility Screens

 lib/faq.dart
Frequently asked questions:
- Common queries
- Help topics
- Support information
- User guidance

 lib/feedback.dart
Customer feedback management:
- Feedback collection
- Response management
- Rating tracking
- Improvement suggestions

 lib/tutorial.dart
User tutorial system:
- Feature guides
- Step-by-step instructions
- Interactive help
- Onboarding support

 lib/notifications_screen.dart
Notification management:
- Push notifications
- In-app alerts
- Settings configuration
- History tracking

  Custom Components

 lib/custom_scaffold.dart
Customized scaffold component:
- Consistent layout structure
- Navigation elements
- Theme integration
- Responsive design

 lib/custom_bottom_bar.dart.dart
Custom bottom navigation:
- Tab navigation
- Icon management
- Active state handling
- Smooth transitions

 lib/custom_loader.dart
Custom loading indicators:
- Loading animations
- Progress indicators
- State management
- User feedback

 lib/connectivity_banner.dart
Network connectivity indicator:
- Connection status
- Offline warnings
- Reconnection prompts
- User notifications

 lib/multiSelectDropdown.dart
Multi-selection dropdown component:
- Multiple choice selection
- Search functionality
- Custom styling
- Data validation

  Location & Maps

 lib/location.dart
Location management:
- Address handling
- GPS coordinates
- Map integration
- Location validation

 lib/qr_code.dart
QR code functionality:
- Code generation
- Display options
- Customization
- Sharing capabilities

 lib/qr_code_scanner_screen.dart
QR code scanning:
- Camera integration
- Code recognition
- Data processing
- Result handling

 🔗 Services

 lib/services/fcm_service.dart
Firebase Cloud Messaging service:
- Push notification handling
- Token management
- Message processing
- Background handling

 lib/services/deep_link_service.dart
Deep linking functionality:
- URL handling
- App navigation
- External link processing
- Branch SDK integration

 lib/services/checkin_service.dart
Check-in processing:
- Customer verification
- Location validation
- Data recording
- Analytics tracking

 lib/services/logger_service.dart
Logging and debugging:
- Error logging
- Debug information
- Performance metrics
- Troubleshooting data

  Platform-Specific Code

 android/
Android-specific configurations:
- Gradle build files
- Manifest configurations
- Resource files
- Native code integration

 ios/
iOS-specific configurations:
- Xcode project files
- Info.plist settings
- App icons and assets
- Native Swift code

 web/
Web platform support:
- HTML templates
- Web-specific assets
- Browser compatibility
- Progressive web app features

 macos/, linux/, windows/
Desktop platform support:
- Platform-specific configurations
- Native integrations
- Desktop UI adaptations
- Cross-platform compatibility

  Assets

 assets/
Application resources:
- Images: App icons, backgrounds, UI elements
- Icons: Navigation icons, action buttons, status indicators
- Animations: GIFs, Lottie files, loading animations
- Branding: Logos, business assets, promotional materials

  Getting Started

 Prerequisites
- Flutter SDK ^3.7.2
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code (recommended for development)

 Installation
1. Clone the repository
2. Install dependencies: flutter pub get
3. Configure platform-specific settings
4. Run the application: flutter run

 Configuration
- Update pubspec.yaml for dependency management
- Configure Firebase services
- Set up Google Maps API keys
- Configure Branch SDK for deep linking

 🔧 Development

 Code Structure
- Provider pattern for state management
- Service layer for business logic
- Custom widgets for reusable components
- Platform-specific implementations where needed

 Testing
- Unit tests in test/ directory
- Widget tests for UI components
- Integration tests for user flows

 Building
- Android: flutter build apk or flutter build appbundle
- iOS: flutter build ios
- Web: flutter build web
- Desktop: flutter build macos/linux/windows

  Features

 Core Functionality
- User authentication and management
- Venue creation and management
- Staff management and permissions
- Customer check-in system
- Offers and promotions management
- Business analytics and reporting
- QR code generation and scanning
- Push notifications
- Deep linking support

 Business Tools
- Operating hours management
- Customer feedback system
- Performance tracking
- Revenue analytics
- Location-based services
- Multi-platform support

  Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

  License

This project is proprietary software. All rights reserved.

  Support

For support and questions:
- Check the FAQ section in the app
- Review the documentation
- Contact the development team

 Version History

- 20.0.9+106: Current stable release
- Previous versions: See git history for detailed changelog

---

Flock Business App - Empowering businesses with comprehensive management solutions. 