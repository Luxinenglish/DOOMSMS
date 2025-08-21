# DoomSMS Flutter Build Instructions

## Project Overview
DoomSMS is a secure peer-to-peer messaging application built with Flutter. It features end-to-end encryption, P2P networking, and modern UI design.

## Build Requirements

### Prerequisites
- **Flutter SDK**: 3.27.1 (stable) or later
- **Dart SDK**: 3.9.0 or later (included with Flutter)
- **Android Studio** (for Android builds)
- **Xcode** (for iOS builds, macOS only)
- **Git** for version control

### Dependencies
The project uses the following key dependencies:
- `flutter`: SDK framework
- `cupertino_icons`: iOS-style icons
- `google_fonts`: Custom fonts
- `crypto`: Cryptographic functions
- `shared_preferences`: Local storage
- `pointycastle`: Encryption library
- `network_info_plus`: Network information

## Build Steps

### 1. Install Flutter
```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:[PATH_TO_FLUTTER]/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Clone and Setup Project
```bash
git clone https://github.com/Luxinenglish/DOOMSMS.git
cd DOOMSMS

# Get dependencies
flutter pub get
```

### 3. Build Commands

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### iOS (macOS only)
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

#### Desktop (Linux/Windows/macOS)
```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

### 4. Run in Development
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d [device_id]

# Run in web browser
flutter run -d web-server
```

## Architecture

### Core Components
- **P2P Service** (`lib/services/p2p_service.dart`): Handles peer discovery and communication
- **Encryption Service** (`lib/services/encryption_service.dart`): RSA/AES encryption
- **Storage Service** (`lib/services/storage_service.dart`): Local data persistence
- **Theme System** (`lib/theme.dart`): Dark/light theme support

### Key Features
1. **End-to-end Encryption**: RSA-2048 key exchange + AES-256-GCM message encryption
2. **P2P Discovery**: Local network peer discovery using UDP broadcast
3. **Secure Storage**: Encrypted local storage for keys and messages
4. **Modern UI**: Material Design with custom themes

## Troubleshooting

### Common Issues

#### 1. Flutter SDK Version Mismatch
```bash
flutter --version
flutter upgrade
```

#### 2. Dependency Conflicts
```bash
flutter pub deps
flutter pub upgrade
```

#### 3. Platform-specific Issues
- **Android**: Ensure Android SDK is properly configured
- **iOS**: Requires macOS with Xcode
- **Web**: May have CORS issues with P2P networking

#### 4. Network Access
The app requires network permissions for P2P communication:
- Android: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`
- iOS: Network usage descriptions in `Info.plist`

### Build Environment Issues
If you encounter network access issues during Flutter setup:
1. Check internet connectivity
2. Verify proxy settings if behind corporate firewall
3. Try `flutter doctor` to diagnose issues
4. Consider using Flutter from official installer instead of git clone

## Development Setup

### VS Code Extensions
- Flutter
- Dart
- Flutter Intl (for internationalization)

### Android Studio Plugins
- Flutter plugin
- Dart plugin

## Security Notes

### Cryptographic Implementation
- Uses industry-standard RSA-2048 and AES-256-GCM
- Keys are generated securely and stored encrypted locally
- No server-side key storage - fully peer-to-peer

### Network Security
- All communications are encrypted end-to-end
- Local network discovery only (no internet relay)
- Message metadata is minimized

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

[Add license information here]

## Support

For build issues or questions, please:
1. Check this build guide
2. Verify Flutter doctor output
3. Check existing GitHub issues
4. Create new issue with detailed error logs