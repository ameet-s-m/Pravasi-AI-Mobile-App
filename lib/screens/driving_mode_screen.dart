// lib/screens/driving_mode_screen.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/driving_mode_service.dart';
import '../services/safety_service.dart';
import '../services/ai_voice_call_service.dart';

class DrivingModeScreen extends StatefulWidget {
  const DrivingModeScreen({super.key});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen> {
  final DrivingModeService _drivingService = DrivingModeService();
  final SafetyService _safetyService = SafetyService();
  bool _isActive = false;
  String _safetyStatus = 'Not Active';
  double _currentSpeed = 0.0;
  Timer? _updateTimer;
  bool _showSafetyDialog = false;
  Timer? _safetyResponseTimer; // Timer to track if user responds to safety check
  bool _userResponded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _setupServiceCallbacks();
    _isActive = _drivingService.isActive;
    if (_isActive) {
      _startUpdates();
    }
  }

  void _setupServiceCallbacks() {
    _drivingService.onAreYouAlrightCheck = () {
      if (!_showSafetyDialog && mounted) {
        _userResponded = false;
        _showAreYouAlrightDialog();
        // Start timer - if no response in 30 seconds, trigger auto-SOS
        _startSafetyResponseTimer();
      }
    };
    
    _drivingService.onSafetyAlert = (String reason) {
      if (mounted) {
        _showSafetyAlert(reason);
      }
    };

    _drivingService.onAutoSOSTrigger = () {
      if (mounted && !_userResponded) {
        _triggerAutoSOS();
      }
    };
  }

  void _startSafetyResponseTimer() {
    _safetyResponseTimer?.cancel();
    _safetyResponseTimer = Timer(const Duration(seconds: 30), () {
      // User didn't respond within 30 seconds
      if (mounted && !_userResponded && _showSafetyDialog) {
        // Auto-trigger SOS
        _triggerAutoSOS();
      }
    });
  }

  void _cancelSafetyResponseTimer() {
    _safetyResponseTimer?.cancel();
    _safetyResponseTimer = null;
  }

  void _startUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isActive) {
        setState(() {
          _currentSpeed = _drivingService.currentSpeed;
          _safetyStatus = _drivingService.getSafetyStatus();
        });
      }
    });
  }

  void _stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _toggleDrivingMode() async {
    if (_isActive) {
      _drivingService.stopDrivingMode();
      _stopUpdates();
      setState(() {
        _isActive = false;
        _currentSpeed = 0.0;
        _safetyStatus = 'Not Active';
      });
    } else {
      // Show loading state
      setState(() {
        _isSubmitting = true;
      });
      
      // Request location permission
      try {
        await _drivingService.startDrivingMode();
        
        // Wait a moment for initial speed reading
        await Future.delayed(const Duration(milliseconds: 500));
        
        _startUpdates();
        setState(() {
          _isActive = true;
          _isSubmitting = false;
          _safetyStatus = 'Initializing...';
        });
        
        if (!kIsWeb) {
          HapticFeedback.mediumImpact();
        }
        
        // Update status after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _isActive) {
            setState(() {
              _safetyStatus = _drivingService.getSafetyStatus();
            });
          }
        });
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error Starting Driving Mode'),
              content: Text(
                'Failed to start driving mode:\n\n${e.toString()}\n\n'
                'Please ensure:\n'
                '• Location services are enabled\n'
                '• Location permissions are granted\n'
                '• GPS signal is available',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showAreYouAlrightDialog() {
    if (_showSafetyDialog) return;
    
    _showSafetyDialog = true;
    _userResponded = false;
    
    // Vibrate continuously
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_showSafetyDialog && !kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_showSafetyDialog && !kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      });
    }
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Show countdown timer
          return StreamBuilder<int>(
            stream: Stream.periodic(const Duration(seconds: 1), (i) => 30 - i)
                .take(31),
            builder: (context, snapshot) {
              final remainingSeconds = snapshot.data ?? 30;
              
              return CupertinoAlertDialog(
                title: const Text('⚠️ Safety Check'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'We detected an unexpected stop or speed change.\n\n'
                      'Are you alright?',
                    ),
                    const SizedBox(height: 16),
                    if (remainingSeconds > 0)
                      Text(
                        'Auto-SOS in: ${remainingSeconds}s',
                        style: TextStyle(
                          color: remainingSeconds <= 10 
                              ? CupertinoColors.systemRed 
                              : CupertinoColors.secondaryLabel,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('I Need Help'),
                    onPressed: () {
                      _userResponded = true;
                      _cancelSafetyResponseTimer();
                      _showSafetyDialog = false;
                      Navigator.pop(context);
                      _triggerEmergency();
                    },
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('I\'m Alright'),
                    onPressed: () {
                      _userResponded = true;
                      _cancelSafetyResponseTimer();
                      _showSafetyDialog = false;
                      Navigator.pop(context);
                      if (!kIsWeb) {
                        HapticFeedback.lightImpact();
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    ).then((_) {
      _showSafetyDialog = false;
      _cancelSafetyResponseTimer();
    });
  }

  void _showSafetyAlert(String reason) {
    if (mounted && !_showSafetyDialog) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('⚠️ Safety Alert'),
          content: Text(reason),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _triggerEmergency() {
    // User manually requested help
    _triggerSOSWithAI();
  }

  Future<void> _triggerAutoSOS() async {
    // Auto-SOS triggered because user didn't respond
    if (!mounted) return;
    
    _cancelSafetyResponseTimer();
    _showSafetyDialog = false;
    
    // Close any open dialogs
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    
    // Show alert that auto-SOS is being triggered
    if (mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('🚨 AUTO-SOS TRIGGERED'),
          content: const Text(
            'No response detected. Emergency alert is being sent to your family contact with your live location.\n\n'
            'AI will call your family member to inform them about the situation.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                _triggerSOSWithAI();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _triggerSOSWithAI() async {
    // Get current position from driving service
    final position = _drivingService.currentPosition;
    if (position == null) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to get current location. Please try again.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Get settings
    final prefs = await SharedPreferences.getInstance();
    final familyContactNumber = prefs.getString('family_contact_number');
    // AI assistant call is always enabled by default
    final sosAutoCallEnabled = prefs.getBool('sos_auto_call_enabled') ?? true;

    // Determine emergency type based on what was detected
    String emergencyType = 'Driving Mode Emergency';
    String additionalDetails = 'Sudden stop or drastic speed change detected in driving mode. '
        'User did not respond to safety check. Possible accident or emergency situation.';

    // Send emergency alert via SafetyService (includes SMS)
    await _safetyService.sendEmergencyAlert(overridePosition: position);

    // If auto-call is enabled and family contact exists, call with AI
    if (sosAutoCallEnabled && familyContactNumber != null && familyContactNumber.isNotEmpty) {
      final aiCallService = AIVoiceCallService();
      await aiCallService.loadApiKeyFromStorage();
      
      await aiCallService.callFamilyMemberWithAI(
        phoneNumber: familyContactNumber,
        emergencyType: emergencyType,
        location: position,
        additionalDetails: additionalDetails,
      );
    } else if (familyContactNumber != null && familyContactNumber.isNotEmpty) {
      // Even if auto-call is disabled, still send SMS/WhatsApp with AI message
      final aiCallService = AIVoiceCallService();
      await aiCallService.loadApiKeyFromStorage();
      
      // Generate AI message and send via SMS/WhatsApp
      final message = await aiCallService.generateEmergencyMessage(
        emergencyType: emergencyType,
        location: position,
        additionalDetails: additionalDetails,
      );

      // Send SMS
      try {
        final smsUri = Uri.parse('sms:$familyContactNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } catch (e) {
        print('Error sending SMS: $e');
      }

      // Send WhatsApp
      try {
        final cleanNumber = familyContactNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final whatsappMessage = '🚨 EMERGENCY - $emergencyType 🚨\n\n$message';
        final whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(whatsappMessage)}');
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        }
      } catch (e) {
        print('Error sending WhatsApp: $e');
      }
    }

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('🚨 Emergency Alert Sent'),
          content: const Text(
            'Your emergency alert has been sent to your family contact with your live location.\n\n'
            'If auto-call is enabled, an AI call has been initiated to inform your family about the situation.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopUpdates();
    _cancelSafetyResponseTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Driving Mode'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
            // Status Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isActive
                      ? [
                          const Color(0xFF34C759),
                          const Color(0xFF28A745),
                        ]
                      : [
                          CupertinoColors.systemGrey,
                          CupertinoColors.systemGrey2,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isActive ? CupertinoColors.systemGreen : CupertinoColors.systemGrey)
                        .withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isActive ? CupertinoIcons.car_fill : CupertinoIcons.car,
                    size: 60,
                    color: CupertinoColors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isActive ? 'Driving Mode Active' : 'Driving Mode Inactive',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _safetyStatus,
                    style: TextStyle(
                      color: CupertinoColors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Speed Display
            if (_isActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Current Speed',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentSpeed.toStringAsFixed(0)} km/h',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Avg Speed',
                          '${_drivingService.getAverageSpeed().toStringAsFixed(0)} km/h',
                          CupertinoIcons.speedometer,
                        ),
                        _buildStatItem(
                          'Status',
                          _safetyStatus,
                          CupertinoIcons.check_mark_circled_solid,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Toggle Button
            Container(
              margin: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _isSubmitting ? null : _toggleDrivingMode,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator()
                    : Text(
                        _isActive ? 'Stop Driving Mode' : 'Start Driving Mode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // Safety Tips
            if (_isActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemBlue.withOpacity(0.1),
                      CupertinoColors.systemGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.lightbulb_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Safety Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('Keep your phone accessible while driving'),
                    _buildInfoItem('Respond to safety checks promptly'),
                    _buildInfoItem('The app detects sudden stops automatically'),
                    _buildInfoItem('Emergency contacts will be notified if needed'),
                  ],
                ),
              ),

            // Info Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.info,
                        color: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('Monitors speed using GPS and accelerometer sensors'),
                  _buildInfoItem('Calculates actual speed from device sensors for accuracy'),
                  _buildInfoItem('Detects sudden stops (speed drops from >30 km/h to <5 km/h)'),
                  _buildInfoItem('Detects unexpected speed changes (>50% drop)'),
                  _buildInfoItem('Alerts you with vibration if something seems wrong'),
                  _buildInfoItem('Shows "Are you alright?" dialog for safety confirmation'),
                  _buildInfoItem('Provides emergency help option if needed'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: CupertinoColors.systemBlue, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

