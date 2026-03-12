# Iriza - Kigali City Services & Places Directory

A Flutter application for discovering and exploring services and places in Kigali, Rwanda. The app provides an interactive directory with map integration, user reviews, and real-time updates.

## Features

- **User Authentication** - Secure Firebase authentication
- **Interactive Map** - Browse locations with Flutter Map integration
- **Service Directory** - Comprehensive listing of city services and places
- **Reviews & Ratings** - User-generated reviews and ratings
- **Real-time Updates** - Cloud Firestore for live data synchronization
- **Location Services** - GPS-based location tracking and navigation
- **Cross-platform** - Supports Android, iOS, Web, Windows, Linux, and macOS

## Tech Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Backend**: Firebase (Auth, Firestore)
- **State Management**: Provider
- **Maps**: Flutter Map with OpenStreetMap
- **Location**: Geolocator

## Prerequisites

- Flutter SDK (>=3.0.0 <4.0.0)
- Dart SDK
- Firebase account and project setup
- Android Studio / Xcode (for mobile development)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd iriza
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS/Web apps to your Firebase project
   - Download and place configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/` and `macos/Runner/`
   - Run FlutterFire CLI to configure:
     ```bash
     flutterfire configure
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models (User, Listing, Review)
├── providers/       # State management providers
├── screens/         # UI screens (Auth, Directory, Listings, Map, Settings)
├── services/        # Business logic and API services
├── utils/           # Constants, themes, and utilities
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## Configuration

Update Firebase configuration in `firebase_options.dart` after running `flutterfire configure`.

## Building for Production

**Android**
```bash
flutter build apk --release
```

**iOS**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue in the repository.
