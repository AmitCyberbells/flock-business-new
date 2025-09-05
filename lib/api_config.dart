class ApiConfig {
  // Base URL for all API endpoints
  static const String baseUrl = 'https://api.getflock.io/api';

  // Vendor API endpoints
  static const String vendorLogin = '$baseUrl/vendor/login';
  static const String vendorProfile = '$baseUrl/vendor/profile';
  static const String vendorDashboard = '$baseUrl/vendor/dashboard';
  static const String vendorVenues = '$baseUrl/vendor/venues';
  static const String vendorCategories = '$baseUrl/vendor/categories';
  static const String vendorFaqs = '$baseUrl/vendor/faqs';
  static const String vendorTerms = '$baseUrl/vendor/terms';
  static const String vendorVerifyVoucher = '$baseUrl/vendor/verify-voucher';
  static const String vendorDevicesUpdate = '$baseUrl/vendor/devices/update';
  static const String vendorOffers = '$baseUrl/vendor/offers';

  // Helper method to get offer remove URL with offer ID
  static String getVendorOffersRemoveUrl(String offerId) =>
      '$baseUrl/vendor/offers/$offerId';

  // Customer API endpoints
  static const String customerAppLogs = '$baseUrl/customer/app-logs/store';

  // Profile endpoints
  static const String profileById =
      '$baseUrl/vendor/profile'; // Will be appended with /{userId}

  // Helper method to get profile URL with user ID
  static String getProfileUrl(String userId) => '$profileById/$userId';

  // Helper method to get full URL from endpoint
  static String getFullUrl(String endpoint) => endpoint;

  // Helper method to get base URL only
  static String getBaseUrl() => baseUrl;
}


// some api's are defined in files itself of the screens