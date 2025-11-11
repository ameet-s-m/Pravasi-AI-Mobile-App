# PRAVASI AI - Build Guide for Android & Chrome

## ✅ Cross-Platform Support

Your app is now configured to run on both **Android** and **Chrome (Web)** platforms!

## 🚀 Quick Start

### For Android:
```bash
# Run on connected Android device/emulator
flutter run

# Or build APK
flutter build apk --release
```

### For Chrome/Web:
```bash
# Run in Chrome browser
flutter run -d chrome

# Or build for web
flutter build web --release
```

## 📱 Platform-Specific Features

### ✅ Works on Both Platforms:
- UI/UX (all screens)
- Navigation
- AI Copilot
- Trip Planning
- Analytics Dashboard
- Settings
- SOS Button (vibration only on Android)
- Most core features

### 📱 Android Only:
- ✅ Vibration/Haptic Feedback
- ✅ SQLite Database (sqflite)
- ✅ Background Location
- ✅ Native Notifications
- ✅ Device Sensors
- ✅ Biometric Authentication

### 🌐 Web/Chrome Only:
- ✅ PWA Installation
- ✅ Browser-based storage
- ✅ Web Notifications
- ✅ Easy sharing via URL

## 🔧 Building for Production

### Android APK:
```bash
# Debug APK
flutter build apk --debug

# Release APK (optimized)
flutter build apk --release

# Split APKs by ABI (smaller file size)
flutter build apk --split-per-abi --release
```

### Web Build:
```bash
# Development build
flutter build web

# Production build (optimized)
flutter build web --release

# With custom base href (for subdirectory deployment)
flutter build web --release --base-href="/pravasi-ai/"
```

## 📦 Deployment

### Android:
1. **Google Play Store:**
   ```bash
   flutter build appbundle --release
   ```
   Upload the `.aab` file from `build/app/outputs/bundle/release/`

2. **Direct APK Distribution:**
   - APK file is in `build/app/outputs/flutter-apk/app-release.apk`

### Web:
1. **Firebase Hosting:**
   ```bash
   flutter build web --release
   firebase deploy
   ```

2. **GitHub Pages:**
   - Build web files
   - Push `build/web/` to `gh-pages` branch

3. **Any Static Host:**
   - Upload contents of `build/web/` to your hosting service

## ⚙️ Configuration

### Firebase Setup:

**For Android:**
- Place `google-services.json` in `android/app/`

**For Web:**
- Add Firebase web config to `web/index.html` (optional)
- Or use Firebase Hosting for automatic setup

### Platform Detection:

The app automatically detects the platform:
- Database: Only initializes on mobile (sqflite)
- Vibration: Only works on mobile
- Other features adapt automatically

## 🐛 Troubleshooting

### Android Issues:

**Build Errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**SDK Issues:**
- Ensure Android SDK 35+ is installed
- Check `android/local.properties` has correct SDK path

### Web Issues:

**CORS Errors:**
- Use HTTPS or localhost for development
- Configure CORS headers on your server

**Firebase Errors:**
- App will continue without Firebase if not configured
- Check browser console for specific errors

**Location Not Working:**
- Requires HTTPS (or localhost)
- Grant location permissions in browser

## 📝 Development Tips

### Testing Both Platforms:

1. **Run Android:**
   ```bash
   flutter run
   ```

2. **Run Chrome (in another terminal):**
   ```bash
   flutter run -d chrome
   ```

3. **Hot Reload works on both!**

### Platform-Specific Code:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

## ✅ Checklist Before Release

### Android:
- [ ] Test on multiple Android versions
- [ ] Test on different screen sizes
- [ ] Verify all permissions work
- [ ] Test background features
- [ ] Generate signed APK/AAB

### Web:
- [ ] Test in Chrome, Firefox, Safari, Edge
- [ ] Test PWA installation
- [ ] Verify responsive design
- [ ] Test on mobile browsers
- [ ] Check HTTPS requirements
- [ ] Test offline functionality

## 🎯 Current Status

✅ **Android**: Fully supported
✅ **Chrome/Web**: Fully supported
✅ **Cross-platform**: Code shared between platforms
✅ **Platform detection**: Automatic
✅ **Error handling**: Graceful fallbacks

Your app is ready for both platforms! 🚀

