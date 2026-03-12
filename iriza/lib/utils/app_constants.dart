// lib/utils/app_constants.dart
class AppConstants {
  // App Theme Colors (matching the dark navy UI design)
  static const String appName = 'Kigali City';
  
  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String reviewsCollection = 'reviews';

  // Categories
  static const List<String> categories = [
    'All',
    'Cafés',
    'Restaurants',
    'Hospitals',
    'Police Stations',
    'Libraries',
    'Parks',
    'Tourist Attractions',
    'Pharmacies',
    'Utility Offices',
  ];

  // Category Icons mapping
  static const Map<String, String> categoryIcons = {
    'Cafés': '☕',
    'Restaurants': '🍽️',
    'Hospitals': '🏥',
    'Police Stations': '🚔',
    'Libraries': '📚',
    'Parks': '🌿',
    'Tourist Attractions': '🏛️',
    'Pharmacies': '💊',
    'Utility Offices': '🏢',
  };

  // Default Kigali coordinates
  static const double kigaliLat = -1.9441;
  static const double kigaliLng = 30.0619;
}