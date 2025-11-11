// lib/widgets/sos_button.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'dart:async';
import '../services/safety_service.dart';
import '../services/ai_voice_call_service.dart';
import '../services/real_location_sharing_service.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  final SafetyService _safetyService = SafetyService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPressed = false;
  bool _isProcessing = false; // Guard to prevent multiple simultaneous SOS triggers
  Timer? _vibrationTimer;
  Timer? _soundTimer;
  Timer? _soundTimer2; // Additional timer for more aggressive sound
  Timer? _flashlightTimer; // Timer for blinking flashlight
  bool _isPlaying = false;
  bool _isFlashlightOn = false;
  bool _flashlightAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkFlashlightAvailability();
  }

  Future<void> _checkFlashlightAvailability() async {
    if (kIsWeb) return;
    
    try {
      _flashlightAvailable = await TorchLight.isTorchAvailable();
    } catch (e) {
      print('Error checking flashlight availability: $e');
      _flashlightAvailable = false;
    }
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _soundTimer?.cancel();
    _soundTimer2?.cancel();
    _flashlightTimer?.cancel();
    _turnOffFlashlight();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playEmergencySound() async {
    if (kIsWeb) return; // Skip on web
    
    _soundTimer?.cancel();
    _soundTimer2?.cancel();
    _isPlaying = true;
    
    // Get selected ringtone from settings
    final prefs = await SharedPreferences.getInstance();
    final selectedRingtone = prefs.getString('sos_ringtone') ?? 'System Alert';
    final customRingtonePath = prefs.getString('sos_custom_ringtone_path');
    
    try {
      // Set volume to maximum for loud playback
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Play based on selected ringtone type
      if (selectedRingtone == 'Custom' && customRingtonePath != null) {
        await _playCustomRingtone(customRingtonePath);
      } else {
        switch (selectedRingtone) {
          case 'System Alert':
            _playSystemAlertPattern();
            break;
          case 'Emergency Alarm':
            _playEmergencyAlarmPattern();
            break;
          case 'Loud Siren':
            _playLoudSirenPattern();
            break;
          case 'Alert Tone':
            _playAlertTonePattern();
            break;
          case 'Urgent Beep':
            _playUrgentBeepPattern();
            break;
          default:
            _playSystemAlertPattern();
        }
      }
    } catch (e) {
      print('Error playing emergency sound: $e');
      // Fallback to system sound
      _playSystemAlertPattern();
    }
  }

  Future<void> _playCustomRingtone(String filePath) async {
    if (kIsWeb) return;
    
    try {
      // Stop any existing playback
      await _audioPlayer.stop();
      
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Play custom ringtone file
      if (!kIsWeb) {
        await _audioPlayer.play(DeviceFileSource(filePath));
      }
      
      // Also play system alert as backup for maximum loudness
      SystemSound.play(SystemSoundType.alert);
      SystemSound.play(SystemSoundType.alert);
      
      // Create timer to repeat system alert while custom ringtone plays
      _soundTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!_isPlaying || kIsWeb) {
          timer.cancel();
          return;
        }
        try {
          SystemSound.play(SystemSoundType.alert);
        } catch (e) {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error playing custom ringtone: $e');
      // Fallback to system alert pattern
      _playSystemAlertPattern();
    }
  }

  void _playSystemAlertPattern() {
    // Play system alert sound immediately - this uses RING volume, not media volume
    SystemSound.play(SystemSoundType.alert);
    
    // Play multiple times immediately for maximum impact
    for (int i = 0; i < 10; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (_isPlaying && !kIsWeb) {
          try {
            SystemSound.play(SystemSoundType.alert);
          } catch (e) {
            print('Error playing sound: $e');
          }
        }
      });
    }
    
    // Create aggressive repeating pattern - play every 200ms for continuous loud alarm
    _soundTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        print('Error playing emergency sound: $e');
        timer.cancel();
      }
    });
    
    // Additional timer for more aggressive pattern - every 100ms
    _soundTimer2 = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void _playEmergencyAlarmPattern() {
    // Very aggressive pattern for emergency alarm
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.alert);
    
    _soundTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
    
    _soundTimer2 = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void _playLoudSirenPattern() {
    // Continuous siren-like pattern
    SystemSound.play(SystemSoundType.alert);
    
    _soundTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
    
    _soundTimer2 = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void _playAlertTonePattern() {
    // Standard alert tone pattern
    SystemSound.play(SystemSoundType.alert);
    
    _soundTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void _playUrgentBeepPattern() {
    // Fast beeping pattern
    SystemSound.play(SystemSoundType.alert);
    
    _soundTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
    
    _soundTimer2 = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        timer.cancel();
      }
    });
  }

  void _startVibrationPattern() {
    if (kIsWeb) return; // Skip on web
    
    _vibrationTimer?.cancel();
    
    // Immediate strong vibration
    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();
    HapticFeedback.heavyImpact();
    
    // Continuous heavy vibration pattern - vibrate every 200ms for maximum intensity
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        return;
      }
      // Use heavy impact multiple times for maximum vibration intensity
      HapticFeedback.heavyImpact();
      // Add a slight delay and vibrate again for stronger effect
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_isPlaying && !kIsWeb) {
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  Future<void> _startFlashlightBlinking() async {
    if (kIsWeb || !_flashlightAvailable) return;
    
    _flashlightTimer?.cancel();
    
    // Start blinking pattern - blink every 200ms
    _flashlightTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!_isPlaying || kIsWeb) {
        timer.cancel();
        await _turnOffFlashlight();
        return;
      }
      
      try {
        if (_isFlashlightOn) {
          await TorchLight.disableTorch();
          _isFlashlightOn = false;
        } else {
          await TorchLight.enableTorch();
          _isFlashlightOn = true;
        }
      } catch (e) {
        print('Error toggling flashlight: $e');
        timer.cancel();
      }
    });
  }

  Future<void> _turnOffFlashlight() async {
    if (kIsWeb || !_flashlightAvailable) return;
    
    try {
      if (_isFlashlightOn) {
        await TorchLight.disableTorch();
        _isFlashlightOn = false;
      }
    } catch (e) {
      print('Error turning off flashlight: $e');
    }
  }

  void _stopEmergencyAlert() {
    _vibrationTimer?.cancel();
    _soundTimer?.cancel();
    _soundTimer2?.cancel();
    _flashlightTimer?.cancel();
    _turnOffFlashlight();
    _audioPlayer.stop();
    _isPlaying = false;
  }

  Future<void> _handleSOSPress() async {
    // Prevent multiple simultaneous SOS triggers
    if (_isProcessing) {
      return;
    }
    
    _isProcessing = true;
    
    // Vibrate when pressed (only on mobile platforms)
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() {
      _isPressed = true;
    });

    // Start emergency alert immediately - no confirmation needed
    if (!kIsWeb) {
      _playEmergencySound();
      _startVibrationPattern();
      _startFlashlightBlinking();
    }
    
    // Get settings and set default family contact if not set
    final prefs = await SharedPreferences.getInstance();
    const defaultFamilyNumber = '+91 90352 80631';
    var familyContactNumber = prefs.getString('family_contact_number') ?? '';
    
    // Set default family contact number if not already set
    if (familyContactNumber.isEmpty) {
      await prefs.setString('family_contact_number', defaultFamilyNumber);
      familyContactNumber = defaultFamilyNumber;
    }
    
    // Always enable SOS auto-call by default (AI assistant talking in calls)
    await prefs.setBool('sos_auto_call_enabled', true);
    
    // REAL SOS: Send WhatsApp first, then call automatically
    try {
      // Get current position
      Position position = _safetyService.getCurrentPosition() ?? 
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
      
      if (familyContactNumber.isNotEmpty) {
        // STEP 1: Send REAL live location via WhatsApp FIRST (for unconscious users)
        try {
          final cleanNumber = familyContactNumber.replaceAll(RegExp(r'[^0-9]'), '');
          String address = 'Unknown location';
          try {
            final placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks[0];
              address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
            }
          } catch (e) {
            // Use coordinates if address fails
          }
          
          final mapUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
          final whatsappMessage = '🚨 SOS EMERGENCY ALERT 🚨\n\n'
              'I need immediate help! Please check my location.\n\n'
              '📍 Location: $address\n'
              'Coordinates: ${position.latitude}, ${position.longitude}\n'
              '📍 View on Map: $mapUrl\n\n'
              'Time: ${DateTime.now()}\n\n'
              'This is an automated emergency alert from PRAVASI AI safety app.';
          
          final whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(whatsappMessage)}');
          if (await canLaunchUrl(whatsappUri)) {
            await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
            print('✅ Real location shared via WhatsApp to: $familyContactNumber');
            // Wait a moment for WhatsApp to open
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          print('Error sharing location via WhatsApp: $e');
        }
        
        // STEP 2: Send REAL live location via SMS (backup)
        try {
          final locationService = RealLocationSharingService();
          await locationService.shareLocationOnce(
            phoneNumbers: [familyContactNumber],
            customMessage: '🚨 SOS EMERGENCY ALERT 🚨\n\n'
                'I need immediate help! Please check my location.\n\n'
                'This is an automated emergency alert from PRAVASI AI safety app.',
          );
          print('✅ Real location shared via SMS to: $familyContactNumber');
        } catch (e) {
          print('Error sharing location via SMS: $e');
        }
        
        // STEP 3: Automatically call family member (without user interaction)
        // Try direct call first (works on some Android devices)
        try {
          final cleanNumber = familyContactNumber.replaceAll(RegExp(r'[^0-9+]'), '');
          
          // Attempt direct call (may require CALL_PHONE permission)
          try {
            final callUri = Uri.parse('tel:$cleanNumber');
            // Try to call directly without opening dialer
            if (await canLaunchUrl(callUri)) {
              // On some devices, this will call directly
              await launchUrl(
                callUri,
                mode: LaunchMode.externalApplication,
              );
              print('✅ Phone call initiated to: $cleanNumber');
              // Wait a moment for call to connect
              await Future.delayed(const Duration(milliseconds: 1000));
            }
          } catch (e) {
            print('Direct call failed, trying alternative method: $e');
            // Fallback: Open dialer with number pre-filled
            final callUri = Uri.parse('tel:$cleanNumber');
            if (await canLaunchUrl(callUri)) {
              await launchUrl(
                callUri,
                mode: LaunchMode.externalApplication,
              );
              print('✅ Phone dialer opened with number: $cleanNumber');
            }
          }
        } catch (e) {
          print('Error initiating phone call: $e');
        }
        
        // STEP 4: AI voice call - ALWAYS ENABLED (AI assistant automatically talks in calls)
        // Wait a moment after regular call before AI call
        await Future.delayed(const Duration(milliseconds: 2000));
        try {
          final aiCallService = AIVoiceCallService();
          await aiCallService.loadApiKeyFromStorage();
          
          await aiCallService.callFamilyMemberWithAI(
            phoneNumber: familyContactNumber,
            emergencyType: 'SOS Emergency Alert',
            location: position,
            additionalDetails: 'User triggered SOS button. Immediate assistance may be required.',
          );
          print('✅ AI voice call initiated to: $familyContactNumber');
        } catch (e) {
          print('Error making AI call: $e');
        }
      }
      
      // Also send standard emergency alert
      await _safetyService.sendEmergencyAlert(
        onPermissionRequested: null,
        overridePosition: position,
      );
    } catch (e) {
      print('Error in SOS emergency response: $e');
      // Still try to send basic alert
      await _safetyService.sendEmergencyAlert(
        onPermissionRequested: null,
      );
    }
    
    _isProcessing = false;
    
    // Show alert active dialog
    if (mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('🚨 SOS ALERT ACTIVE'),
              content: const Text(
                'Emergency call and WhatsApp message sent to your family contact!\n\n'
                'Your live location has been shared.\n\n'
                'Alarm and vibration will continue until you press STOP.',
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  isDefaultAction: true,
                  child: const Text('STOP ALERT'),
                  onPressed: () {
                    _stopEmergencyAlert();
                    Navigator.pop(context);
                    if (mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Alert Stopped'),
                          content: const Text('Emergency alert has been stopped.'),
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
                  },
                ),
              ],
            );
          },
        ),
      );
    }

    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleSOSPress,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: _isPressed ? CupertinoColors.systemRed.withOpacity(0.8) : CupertinoColors.systemRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemRed.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.exclamationmark_triangle_fill,
          color: CupertinoColors.white,
          size: 35,
        ),
      ),
    );
  }
}

