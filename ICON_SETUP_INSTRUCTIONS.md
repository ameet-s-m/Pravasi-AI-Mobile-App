# App Icon Setup Instructions

## Quick Setup (Recommended)

### Step 1: Convert SVG to PNG
1. Open `assets/app_icon_template.svg` in any image editor (Inkscape, GIMP, Photoshop, or online converter)
2. Export as PNG at **1024x1024 pixels**
3. Save as `assets/app_icon.png`

### Step 2: Create Foreground Icon
1. Open `assets/app_icon_foreground.svg` 
2. Export as PNG at **1024x1024 pixels** (transparent background)
3. Save as `assets/app_icon_foreground.png`

### Step 3: Generate Icons
Run these commands in your terminal:

```bash
# Install dependencies
flutter pub get

# Generate all icon sizes automatically
flutter pub run flutter_launcher_icons
```

That's it! The icons will be automatically generated and placed in the correct locations.

## Manual Alternative

If you prefer to generate icons manually:

### For Android:
1. Use an online icon generator like https://www.appicon.co/
2. Upload your 1024x1024 PNG
3. Download the Android icon set
4. Replace files in:
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

### For iOS:
1. Use https://www.appicon.co/ or similar
2. Download iOS icon set
3. Replace files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Icon Design Description

The icon features:
- **Shield shape**: Represents safety and protection
- **Location pin**: Represents travel and location tracking
- **Checkmark**: Represents safety confirmation
- **Blue/Pink gradient**: Trust (blue) and Safety alerts (pink)

## Testing

After generating icons:
1. Clean build: `flutter clean`
2. Rebuild: `flutter run`
3. Check the app icon appears correctly on your device

## Troubleshooting

- If icons don't update: Try `flutter clean` then rebuild
- For iOS: May need to delete app and reinstall
- For Android: Clear app data or reinstall

