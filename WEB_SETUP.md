# PRAVASI AI - Web/Chrome Setup Guide

## ✅ Web Support Enabled

Your Flutter app is now configured to run as a web application in Chrome and other browsers. The following changes have been made:

### Changes Made:
1. **SOS Button**: Updated to work on web (vibration disabled on web, but button still functional)
2. **Web Manifest**: Updated with proper app name "PRAVASI AI" and PWA settings
3. **Index.html**: Enhanced with proper metadata, PWA support, and app description

## 🚀 Running the App in Chrome

### Option 1: Development Mode (Hot Reload)
```bash
# Run in Chrome with hot reload
flutter run -d chrome
```

### Option 2: Build for Web
```bash
# Build for web (production)
flutter build web

# The built files will be in: build/web/
# You can serve them with any web server or deploy to hosting
```

### Option 3: Run with Specific Chrome Profile
```bash
# Run with Chrome in debug mode
flutter run -d chrome --web-port=8080
```

## 📱 Progressive Web App (PWA) Features

The app is configured as a PWA, which means:
- ✅ Can be installed on desktop/mobile browsers
- ✅ Works offline (with limitations)
- ✅ App-like experience in browser
- ✅ Can be added to home screen on mobile devices

### Installing as PWA:
1. Open the app in Chrome
2. Click the install icon in the address bar (or menu → Install)
3. The app will open in its own window

## ⚠️ Platform-Specific Notes

### Features That Work on Web:
- ✅ UI/UX (all screens)
- ✅ Navigation
- ✅ AI Copilot
- ✅ Trip Planning
- ✅ Analytics
- ✅ Settings
- ✅ SOS Button (without vibration)
- ✅ Most core features

### Features with Limitations on Web:
- ⚠️ **Vibration**: Not available (SOS button works but no haptic feedback)
- ⚠️ **Location Services**: Requires browser permissions (HTTPS recommended)
- ⚠️ **Camera/Image Picker**: Works but requires user permission
- ⚠️ **SMS**: May not work (browser limitations)
- ⚠️ **Background Location**: Limited on web
- ⚠️ **Native Notifications**: Limited (web notifications available)

### Features That May Not Work:
- ❌ Some native device features (sensors, pedometer)
- ❌ Background tasks
- ❌ Some Firebase features may need web configuration

## 🔧 Troubleshooting

### If the app doesn't run:
```bash
# Enable web support (if not already enabled)
flutter config --enable-web

# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

### If you see Firebase errors:
- Firebase initialization has error handling and will continue without it
- For full Firebase features on web, you'll need to configure Firebase for web

### If location doesn't work:
- Make sure you're using HTTPS (or localhost for development)
- Grant location permissions in browser settings

## 📦 Building for Production

```bash
# Build optimized web app
flutter build web --release

# Build with specific base href (if deploying to subdirectory)
flutter build web --base-href="/pravasi-ai/"
```

## 🌐 Deploying to Web

The built files in `build/web/` can be deployed to:
- Firebase Hosting
- GitHub Pages
- Netlify
- Vercel
- Any static web hosting service

## 🎯 Quick Start

```bash
# 1. Make sure Flutter web is enabled
flutter config --enable-web

# 2. Get dependencies
flutter pub get

# 3. Run in Chrome
flutter run -d chrome
```

The app will automatically open in Chrome and you can use it just like the mobile version!

