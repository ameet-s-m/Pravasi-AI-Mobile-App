// lib/main.dart
import 'package:flutter/cupertino.dart';
// Still needed for some colors/icons if not in Cupertino
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'models/models.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/permissions_disclaimer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/trip_data_service.dart';
import 'services/auto_trip_detection_service.dart';
import 'services/ai_copilot_service.dart';
import 'services/accident_detection_service.dart';
import 'services/ai_voice_call_service.dart';
import 'services/arrival_alert_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handlers to track errors during app usage
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('🚨 FLUTTER ERROR: ${details.exception}');
      print('Stack trace: ${details.stack}');
      print('Context: ${details.context}');
    }
  };
  
  // Handle errors from async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('🚨 PLATFORM ERROR: $error');
      print('Stack trace: $stack');
    }
    return true;
  };
  
  // Initialize Firebase with error handling (works on both Android and Web)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase initialization failed (likely missing config files)
    // App can still run without Firebase features on both platforms
    // Ignore Firebase initialization errors for now
    if (kDebugMode) {
      print('Firebase initialization skipped: $e');
    }
  }
  
  // Initialize database (only on mobile platforms, sqflite doesn't work on web)
  if (!kIsWeb) {
    try {
      await DatabaseService().initialize();
    } catch (e) {
      // Database initialization failed, app can still run
      if (kDebugMode) {
        print('Database initialization skipped: $e');
      }
    }
  }
  
  // Initialize default settings and AI services
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Set default family contact number if not set
    if (!prefs.containsKey('family_contact_number') || 
        prefs.getString('family_contact_number') == null || 
        prefs.getString('family_contact_number')!.isEmpty) {
      await prefs.setString('family_contact_number', '*****Add Family Contact Number*****');
    }
    
    // Always enable SOS auto-call by default (AI assistant talking in calls)
    await prefs.setBool('sos_auto_call_enabled', true);
    
    // Set default Gemini API key (user's API key)
    const defaultGeminiApiKey = '*****Your Gemini API KEY HERE*****';
    if (!prefs.containsKey('gemini_api_key') || 
        prefs.getString('gemini_api_key') == null || 
        prefs.getString('gemini_api_key')!.isEmpty) {
      await prefs.setString('gemini_api_key', defaultGeminiApiKey);
      if (kDebugMode) {
        print('Default Gemini API key set');
      }
    }
    
    // Initialize AI services with saved API key
    final geminiApiKey = prefs.getString('gemini_api_key');
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      final aiCopilotService = AICopilotService();
      await aiCopilotService.loadApiKeyFromStorage();
      
      final accidentService = AccidentDetectionService();
      await accidentService.loadApiKeyFromStorage();
      
      final aiVoiceCallService = AIVoiceCallService();
      await aiVoiceCallService.loadApiKeyFromStorage();
      
      if (kDebugMode) {
        print('AI services initialized with API key');
      }
    }
    
    // Start automatic trip detection for daily trips
    if (!kIsWeb) {
      try {
        final autoTripService = AutoTripDetectionService();
        final prefs = await SharedPreferences.getInstance();
        final autoTripEnabled = prefs.getBool('auto_trip_detection_enabled') ?? true; // Enabled by default
        
        if (autoTripEnabled) {
          await autoTripService.startAutoDetection();
          if (kDebugMode) {
            print('✅ Automatic daily trip detection started');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Auto trip detection initialization skipped: $e');
        }
      }
      
      // Start arrival alert monitoring if active
      try {
        final arrivalAlertService = ArrivalAlertService();
        final settings = await arrivalAlertService.getAlertSettings();
        if (settings['isActive'] == true) {
          await arrivalAlertService.startMonitoring();
          if (kDebugMode) {
            print('✅ Arrival alert monitoring started');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Arrival alert initialization skipped: $e');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Settings initialization skipped: $e');
    }
  }
  
  runApp(const PravasiAIApp());
}

class PravasiAIApp extends StatefulWidget {
  const PravasiAIApp({super.key});

  @override
  State<PravasiAIApp> createState() => _PravasiAIAppState();
    
    static _PravasiAIAppState? of(BuildContext context) {
      return context.findAncestorStateOfType<_PravasiAIAppState>();
    }
}

class _PravasiAIAppState extends State<PravasiAIApp> {
  Brightness _brightness = Brightness.light;

  void changeTheme(Brightness brightness) {
    setState(() {
      _brightness = brightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'PRAVASI AI',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap with error boundary
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
      theme: CupertinoThemeData(
        brightness: _brightness,
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: _brightness == Brightness.light 
            ? const Color(0xFFF5F7FA)
            : const Color(0xFF000000),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Display',
            color: _brightness == Brightness.light ? const Color(0xFF1D1D1F) : CupertinoColors.white,
            letterSpacing: -0.3,
          )
        ),
        barBackgroundColor: _brightness == Brightness.light 
            ? CupertinoColors.white.withOpacity(0.8)
            : CupertinoColors.black.withOpacity(0.8),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
 @override
 void initState() {
  super.initState();
  Timer(const Duration(seconds: 2), () async {
    if (!mounted) return;
    
    // Check if user has completed onboarding (disclaimer + login)
    final prefs = await SharedPreferences.getInstance();
    final hasSeenDisclaimer = prefs.getBool('has_seen_permissions_disclaimer') ?? false;
    final hasLoggedIn = prefs.getBool('has_logged_in') ?? false;
    
    if (!mounted) return;
    
    // For demo: Skip disclaimer and login if already completed
    if (hasSeenDisclaimer && hasLoggedIn) {
      // Go directly to main screen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }
    
    if (!hasSeenDisclaimer) {
      // Show permissions disclaimer first (only on first install)
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => PermissionsDisclaimerScreen(
            onAccept: () async {
              await prefs.setBool('has_seen_permissions_disclaimer', true);
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
    } else if (!hasLoggedIn) {
      // Show login screen (only if not logged in before)
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  });
 }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF007AFF),
              Color(0xFF0051D5),
              Color(0xFF003D99),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.paperplane_fill,
                  size: 80,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'PRAVASI AI',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Travel Safety Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              const CupertinoActivityIndicator(
                color: CupertinoColors.white,
                radius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN SCREEN (WITH TAB BAR) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  Future<void> _onNewTripCreated(PlannedTrip trip) async {
    final tripDataService = TripDataService();
    await tripDataService.initialize();
    await tripDataService.addPlannedTrip(trip);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.sparkles), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.play_rectangle), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.group), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle), label: 'Profile'),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            switch (index) {
              case 0:
                return HomeScreen(onNewTripCreated: _onNewTripCreated);
              case 1:
                return TripsScreen();
              case 2:
                return AssistantScreen();
              case 3:
                return ReelsScreen();
              case 4:
                return CommunityScreen();
              case 5:
                return ProfileScreen();
              default:
                return HomeScreen(onNewTripCreated: _onNewTripCreated);
            }
          },
        );
      },
    );
  }
}
