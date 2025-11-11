# 🛡️ PRAVASI AI - Women's Safety App

<div align="center">

![PRAVASI AI](https://img.shields.io/badge/PRAVASI-AI-blue?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.9.0-02569B?style=for-the-badge&logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**An AI-powered comprehensive safety solution for women travelers**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Screenshots](#-screenshots) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Installation](#-installation)
- [Usage](#-usage)
- [Architecture](#-architecture)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 About

**PRAVASI AI** is a comprehensive women's safety application designed to provide multiple layers of protection during travel. Built with Flutter and powered by AI/ML technologies, it offers real-time safety monitoring, community support, and emergency response features.

### Key Highlights
- 🚨 **Real-time Safety Monitoring** - Continuous GPS tracking with route deviation detection
- 🤖 **AI-Powered Features** - Voice commands and OCR for hands-free operation
- 👥 **Community Safety Network** - Connect with nearby users for mutual support
- 📊 **Safety Analytics** - Data-driven insights and safety scoring
- 🎯 **Multiple Safety Layers** - Comprehensive protection system

---

## ✨ Features

### 🔐 Core Safety Features

#### 1. **OCR Trip Details Upload**
- 📸 Upload trip tickets/receipts via camera or gallery
- 🔍 Automatic text extraction using Google ML Kit
- 📝 Auto-fills origin, destination, time, and vehicle details
- ✅ Smart pattern recognition for various ticket formats

#### 2. **Route Deviation Detection**
- 🗺️ Real-time GPS tracking during trips
- ⚠️ Automatic detection when driver deviates >200m from planned route
- 🔔 Instant safety check prompt
- 📍 Continuous location monitoring

#### 3. **30-Second Safety Check System**
- ⏱️ Automatic safety confirmation request on route deviation
- 🚨 30-second countdown timer
- 📱 "I Am Safe" button for quick confirmation
- 🆘 Auto-emergency alert if no response

#### 4. **Live Location Sharing**
- 📍 Real-time GPS coordinates
- 📧 SMS with Google Maps link to emergency contact
- 🗺️ One-tap navigation to user's location
- ⏰ Timestamp included in alerts

#### 5. **Emergency Contact Management**
- 👤 Add/manage emergency contacts
- 📞 Pick from phone contacts or manual entry
- ⭐ Mark primary emergency contact
- 💾 Secure local storage

---

### 🤖 AI-Powered Features

#### 6. **Voice Commands**
- 🎤 Hands-free voice activation
- 🗣️ Say "I am safe" to confirm safety
- 🚨 Say "SOS" or "Emergency" to trigger alert
- 🔊 Text-to-speech feedback
- 🎯 Perfect for emergency situations

#### 7. **Voice-Controlled Safety**
- 🎙️ Speech-to-text integration
- 📢 Voice-activated trip start
- 🎵 Audio confirmations
- 🔇 Hands-free operation during travel

---

### 🎭 Emergency Exit Features

#### 8. **Fake Call Feature**
- 📞 Simulate incoming calls
- 👨‍👩‍👧 Multiple caller options (Mom, Dad, Friend, etc.)
- 📱 Full-screen realistic call interface
- ⚡ Quick access for uncomfortable situations
- 🎯 One-tap fake call activation

---

### 👥 Community Safety Network

#### 9. **Incident Reporting System**
- 📝 Report various incident types:
  - Harassment
  - Theft
  - Assault
  - Suspicious Activity
  - Other
- 📍 Automatic location tagging
- 🔔 Real-time community notifications
- 👤 Optional anonymous reporting
- 📊 Incident tracking and analytics

#### 10. **Safe Zones Mapping**
- 🏢 Verified safe locations:
  - Police Stations
  - Hospitals
  - Safe Houses
  - Community Centers
- 📍 Find nearby safe zones (within 5km)
- ⭐ Community-rated safe zones
- 🗺️ Get directions to safe zones
- 📊 Safe zone ratings and reviews

#### 11. **Community Alerts**
- 🔔 Real-time incident notifications
- 📍 Location-based alerts
- 👥 Nearby community member awareness
- 🚨 Emergency community response

#### 12. **Location Sharing**
- 📍 Share live location with trusted contacts
- 👥 Community member location sharing
- 🔒 Privacy controls
- ⏰ Time-limited sharing options

---

### 📊 Analytics & Insights

#### 13. **Safety Analytics Dashboard**
- 📈 Comprehensive safety score (0-100)
- 📊 Trip statistics:
  - Total trips
  - Safe trips percentage
  - Average trip duration
  - Incidents reported
  - Emergency alerts triggered
- 📉 Visual charts and graphs:
  - Pie charts for trip safety
  - Trend analysis
  - Safety patterns
- 🎯 Personalized safety insights

#### 14. **Trip History & Statistics**
- 📝 Complete trip log
- 📊 Trip-by-trip safety analysis
- 🗺️ Route history
- ⏱️ Duration and distance tracking
- 📈 Safety trend visualization

---

### 🚗 Driver & Vehicle Features

#### 15. **Driver Verification System**
- 👤 Driver information management:
  - Name
  - Vehicle number
  - Phone number
  - Photo (optional)
- ⭐ Rating system (1-5 stars)
- ✅ Verification badges
- 📊 Trip history with driver
- 🛡️ Verified driver status

#### 16. **Vehicle Information**
- 🚗 Vehicle number tracking
- 📝 Trip vehicle details
- 🔍 Vehicle verification
- 📊 Vehicle safety history

---

### 🎨 User Interface & Experience

#### 17. **Modern UI Design**
- 🎨 Beautiful gradient backgrounds
- ✨ Smooth animations
- 📱 Cupertino design language
- 🌓 Dark mode support
- 🎯 Intuitive navigation

#### 18. **Quick Actions**
- ⚡ Fast access to key features:
  - New Trip
  - Safe Zones
  - Analytics
  - Fake Call
  - Incident Report
- 📱 One-tap feature access
- 🎯 Contextual quick actions

#### 19. **SOS Button**
- 🚨 Always-accessible emergency button
- 📍 Floating action button
- 🔴 Long-press to activate
- ⚡ Instant emergency alert
- 🎯 Available on all screens

#### 20. **Real-time Status Indicators**
- 🟢 Safety status display
- ⏱️ Active trip indicators
- 📍 Location status
- 🔔 Notification badges

---

### 🔧 Technical Features

#### 21. **Offline Mode Support**
- 📴 Works without internet connection
- 💾 Local data storage
- 🔄 Automatic sync when online
- 🆘 Emergency features work offline

#### 22. **Background Location Tracking**
- 📍 Continuous GPS monitoring
- 🔋 Battery-efficient tracking
- 📊 Background location updates
- 🛡️ Privacy-compliant tracking

#### 23. **Multi-platform Support**
- 📱 Android
- 🍎 iOS (planned)
- 💻 Cross-platform Flutter app
- 🌐 Web support (planned)

#### 24. **Secure Data Storage**
- 🔒 Encrypted local storage
- 🔐 Secure emergency contact storage
- 🛡️ Privacy-first approach
- 📊 Data export capabilities

---

### 👶 Child Safety Features

#### 25. **Child Safety Monitoring**
- 👨‍👩‍👧 Track children's location in real-time
- 📍 Safe zone monitoring
- 🚨 Missing child alerts
- ⏰ School/home location verification
- 📱 Parent notifications
- 🔔 Out-of-zone alerts

#### 26. **Missing Child Alert System**
- 🚨 Automatic missing child detection
- 📧 Emergency contact notifications
- 📍 Last known location sharing
- ⏰ Time-based safety checks
- 🏫 School hours monitoring

---

### 🧠 AI & Machine Learning Features

#### 27. **Daily Route Learning**
- 🗺️ Learns your daily routes automatically
- 📊 Pattern recognition
- ⚠️ Unexpected route detection
- 🔒 Security lock verification on unexpected routes
- 📈 Route frequency tracking

#### 28. **Security Lock Verification**
- 🔐 Biometric authentication (fingerprint/face)
- ⏱️ 30-second verification window
- 🚨 Auto-emergency if not verified
- 🛡️ Prevents unauthorized route changes
- 📱 PIN/Pattern fallback

#### 29. **Emotion Detection (Wearable Integration)**
- ❤️ Heart rate monitoring
- 📊 Accelerometer analysis
- 🎯 Panic detection
- 😰 Distress recognition
- 🚨 Automatic emergency response
- 📹 Video streaming activation

#### 30. **Accident Detection from Photos**
- 📸 Upload accident scene photos
- 🤖 AI-powered image analysis (Gemini AI)
- 🚑 Automatic ambulance calling
- 📍 Location-based emergency response
- 📞 Natural language ambulance calls

#### 31. **Motorcycle Accident Detection**
- 🏍️ Speed monitoring
- 🔊 Sound detection (high impact sounds)
- 📉 Sudden speed drop detection
- 🚑 Automatic ambulance dispatch
- 📍 Real-time location sharing
- 🚨 SOS sound activation

#### 32. **Gemini AI Integration**
- 🗣️ Natural language ambulance calls
- 📞 Human-like conversation
- 🎯 Context-aware responses
- 📝 Automatic call script generation
- 🌐 Multi-language support

#### 33. **Video Streaming & Live Sharing**
- 📹 Real-time video streaming
- 📍 Live location updates
- 👥 Share with emergency contacts
- 🚨 Automatic activation during emergencies
- 🔴 Continuous streaming during distress

#### 34. **Automatic Emergency Response System**
- 🚨 Multi-channel emergency alerts:
  - Police (100)
  - Ambulance (108)
  - Family & Friends
  - Emergency contacts
- 📧 SMS notifications
- 📞 Automatic phone calls
- 📍 Location sharing
- 📹 Video stream activation

---

### 🎯 Advanced Features

#### 35. **Route Planning & Optimization**
- 🗺️ Automatic route generation
- 📍 Multiple waypoint support
- ⏱️ Estimated time calculation
- 🚗 Vehicle-specific routes
- 🎯 Optimal route suggestions

#### 36. **Trip Planning**
- 📅 Schedule trips in advance
- 🔔 Trip reminders
- 📝 Trip notes and details
- 👥 Companion information
- 🎯 Purpose and purpose tracking

#### 37. **Real-time Notifications**
- 🔔 Push notifications
- 📱 In-app notifications
- 🚨 Emergency alerts
- 📍 Location-based alerts
- 👥 Community notifications

#### 38. **Data Export**
- 📊 Export trip data
- 📈 Analytics export
- 📝 Incident reports export
- 💾 CSV/JSON formats
- ☁️ Cloud backup (optional)

---

### 🗺️ Navigation & Maps (Replaces Google Maps)

#### 39. **Built-in Navigation System**
- 🧭 Turn-by-turn navigation
- 📍 Real-time route guidance
- 🗺️ Interactive map display
- 🔊 Voice instructions
- ⏱️ ETA calculation
- 🚗 Multiple transport modes

#### 40. **Route Planning & Optimization**
- 🎯 Automatic route generation
- 📍 Multiple waypoint support
- ⏱️ Estimated time calculation
- 🚗 Vehicle-specific routes
- 🎯 Optimal route suggestions
- 🔄 Route alternatives

#### 41. **Address Search & Geocoding**
- 🔍 Search by address
- 📍 Reverse geocoding
- 🗺️ Map integration
- 📌 Save favorite locations
- 🏠 Home/Work shortcuts

---

### 🚌 Transport Booking (Replaces Uber/Ola)

#### 42. **Multi-Mode Transport Booking**
- 🚌 Bus booking
- 🚂 Train booking
- 🚕 Taxi booking
- 🛺 Auto booking
- ✈️ Flight booking (long distances)
- 📱 One-tap booking

#### 43. **Transport Comparison & Sorting**
- 💰 Sort by price (cheapest first)
- ⏱️ Sort by duration (fastest)
- ⭐ Sort by rating (best rated)
- 📊 Side-by-side comparison
- 🏆 Cheapest option highlight
- 📈 Price trends

#### 44. **Smart Booking System**
- 🎫 QR code generation
- 📧 Booking confirmations
- 🔔 Trip reminders
- 📱 Booking history
- 💳 Payment integration ready

---

### 🤖 AI Copilot Assistant

#### 45. **AI Travel Assistant (Gemini AI)**
- 💬 Natural language conversations
- 🧠 Context-aware responses
- 📍 Location-based advice
- 🗺️ Route suggestions
- 🛡️ Safety tips
- 📊 Trip analysis
- 💡 Travel recommendations

#### 46. **Conversation History**
- 📝 Chat history saved
- 🔍 Search past conversations
- 💾 Export conversations
- 🔄 Continue previous chats

---

### 🎁 Rewards & Gamification

#### 47. **Points & Rewards System**
- ⭐ Earn points for safe trips
- 🏆 Achievement badges
- 📈 Level progression
- 🎁 Reward redemption
- 💰 Discounts and vouchers
- 🎯 Challenges and goals

#### 48. **Achievement System**
- 🎯 First Trip badge
- 🛡️ Safety Champion
- 👥 Community Hero
- 🗺️ Explorer badge
- 📊 Progress tracking

---

### 💾 Database & Data Management

#### 49. **Comprehensive Database (SQLite)**
- 📊 Trip data storage
- 📍 Location history
- 📝 Incident records
- 💰 Expense tracking
- 📈 Analytics data
- 🔍 Advanced queries

#### 50. **Data Export & Backup**
- 📄 JSON export
- 📊 CSV export
- ☁️ Cloud backup ready
- 📧 Email export
- 💾 Local backup
- 🔄 Auto-sync

---

### 📝 Journey Management

#### 51. **Journey Summary**
- 📊 Complete trip report
- 📍 Route visualization
- ⏱️ Duration analysis
- 💰 Expense breakdown
- 🛡️ Safety score
- 📈 Performance metrics

#### 52. **Trip Reports**
- 📄 Detailed reports
- 📊 Visual charts
- 📍 Map integration
- 💾 PDF export ready
- 📧 Share reports

---

### 🏨 Hotels & Accommodation

#### 53. **Hotel Nearby Alerts**
- 🔔 Automatic hotel detection
- 📍 Distance-based alerts
- 💰 Price notifications
- ⭐ Rating information
- 🎯 Smart recommendations

#### 54. **Hotel Booking**
- 🏨 Browse nearby hotels
- 💰 Price comparison
- ⭐ Rating filter
- 📱 Quick booking
- 🎫 Booking confirmation
- 📧 Receipt generation

---

### 🌤️ Weather & Travel Advisories

#### 55. **Weather Alerts**
- 🌡️ Real-time weather
- 🌧️ Rain alerts
- ☀️ Heat warnings
- 💨 Wind information
- 📍 Location-based weather

#### 56. **Travel Advisories**
- ⚠️ Safety advisories
- 📍 Location-specific warnings
- 🕐 Time-based alerts
- 📊 Severity levels
- 🔔 Push notifications

---

### 💰 Expense Tracking & Budget

#### 57. **Expense Management**
- 💳 Add expenses by category
- 📊 Category-wise breakdown
- 📈 Spending trends
- 💰 Budget setting
- ⚠️ Over-budget alerts
- 📝 Expense notes

#### 58. **Budget Management**
- 💵 Set trip budgets
- 📊 Track spending
- ⚠️ Budget warnings
- 📈 Spending analysis
- 💾 Budget history

---

## 🚀 Installation

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Git

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/pravasi-ai.git
   cd pravasi-ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Android permissions**
   - Location permissions are already configured in `AndroidManifest.xml`
   - Ensure location services are enabled on device

4. **Run the app**
   ```bash
   flutter run
   ```

### Android Setup
- Minimum SDK: 21
- Target SDK: 33+
- Permissions configured automatically

---

## 📱 Usage

### Setting Up Emergency Contact

1. Open the app
2. Go to **Profile** → **Emergency Contact**
3. Add contact name and phone number
4. Save the contact

### Planning a Trip with OCR

1. Tap **New Trip** on home screen
2. Tap **Upload Trip Image**
3. Select ticket/receipt from gallery or camera
4. Review extracted details
5. Tap **Generate Route**
6. Tap **Start Tracking with Safety**

### During a Trip

1. App automatically tracks your location
2. If route deviates, safety check appears
3. Tap **"I Am Safe"** within 30 seconds
4. If no response, emergency alert is sent automatically

### Using Voice Commands

1. During trip tracking, tap **Voice Commands**
2. Say "I am safe" to confirm safety
3. Say "SOS" or "Emergency" for help
4. Voice feedback confirms actions

### Fake Call Feature

1. Tap **Fake Call** from home screen
2. Select a caller (Mom, Dad, etc.)
3. Full-screen call interface appears
4. Use to exit uncomfortable situations

### Reporting Incidents

1. Go to **Profile** → **Report Incident**
2. Select incident type
3. Describe what happened
4. Location is automatically tagged
5. Submit report (notifies community)

### Viewing Safe Zones

1. Tap **Safe Zones** from home screen
2. View nearby verified safe locations
3. Tap **Get Directions** for navigation
4. Add new safe zones (community feature)

### Safety Analytics

1. Go to **Profile** → **Safety Analytics**
2. View comprehensive safety score
3. Check trip statistics
4. Review safety trends
5. Export data if needed

---

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── models.dart          # Data models
├── screens/
│   ├── home_screen.dart
│   ├── plan_trip_screen.dart
│   ├── tracking_screen.dart
│   ├── analytics_screen.dart
│   ├── safe_zones_screen.dart
│   ├── incident_report_screen.dart
│   ├── fake_call_screen.dart
│   ├── emergency_contact_screen.dart
│   └── ...
├── services/
│   ├── safety_service.dart
│   ├── ocr_service.dart
│   ├── voice_service.dart
│   ├── community_safety_service.dart
│   └── analytics_service.dart
├── widgets/
│   └── sos_button.dart
└── data/
    └── dummy_data.dart
```

### Key Services

- **SafetyService**: Route monitoring and emergency alerts
- **OCRService**: Text recognition from images
- **VoiceService**: Speech-to-text and text-to-speech
- **CommunitySafetyService**: Community features and safe zones
- **AnalyticsService**: Safety statistics and insights

---

## 📸 Screenshots

### Home Screen
- Dashboard with quick actions
- Safety statistics
- Recent trips
- SOS button

### Trip Planning
- OCR upload interface
- Route generation
- Safety monitoring setup

### Live Tracking
- Real-time location
- Route deviation alerts
- Safety check dialogs
- Voice commands

### Analytics Dashboard
- Safety score
- Trip statistics
- Visual charts
- Safety insights

### Safe Zones
- Nearby safe locations
- Ratings and reviews
- Directions integration

---

## 🛠️ Tech Stack

### Core Technologies
- **Flutter** - Cross-platform framework
- **Dart** - Programming language

### Key Packages
- **geolocator** - Location services
- **google_maps_flutter** - Maps integration
- **google_mlkit_text_recognition** - OCR
- **speech_to_text** - Voice input
- **flutter_tts** - Text-to-speech
- **fl_chart** - Data visualization
- **shared_preferences** - Local storage
- **firebase_core** - Backend services (optional)
- **permission_handler** - Permissions management

### AI/ML Integration
- Google ML Kit for OCR
- Speech recognition
- Text-to-speech synthesis

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines
- Follow Flutter/Dart style guidelines
- Write clear commit messages
- Add tests for new features
- Update documentation

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Google ML Kit for OCR capabilities
- Flutter team for the amazing framework
- Open source community for various packages
- All contributors and testers

---

## 📞 Contact & Support

- **Project Link**: [https://github.com/yourusername/pravasi-ai](https://github.com/yourusername/pravasi-ai)
- **Issues**: [GitHub Issues](https://github.com/yourusername/pravasi-ai/issues)
- **Email**: support@pravasiai.com

---

## 🎯 Roadmap

### Upcoming Features
- [ ] Multi-language support
- [ ] Wearable device integration
- [ ] AR navigation to safe zones
- [ ] Machine learning for predictive safety
- [ ] Blockchain for secure incident reporting
- [ ] Government authority integration
- [ ] AI chatbot assistant
- [ ] Gamification and achievements

### Future Enhancements
- [ ] Web application
- [ ] Desktop support
- [ ] Advanced analytics
- [ ] Social features
- [ ] Trip sharing
- [ ] Group safety features

---

<div align="center">

**Built with ❤️ for Women's Safety**

⭐ Star this repo if you find it helpful!

</div>
