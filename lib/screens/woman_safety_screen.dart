// lib/screens/woman_safety_screen.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../services/woman_safety_service.dart';
import '../widgets/safety_zone_lock_dialog.dart';
import 'map_location_picker_screen.dart';

// UserSafeZone is defined in woman_safety_service.dart

class WomanSafetyScreen extends StatefulWidget {
  const WomanSafetyScreen({super.key});

  @override
  State<WomanSafetyScreen> createState() => _WomanSafetyScreenState();
}

class _WomanSafetyScreenState extends State<WomanSafetyScreen> {
  final WomanSafetyService _safetyService = WomanSafetyService();
  bool _isActive = false;
  String _safetyStatus = 'Inactive';
  Timer? _updateTimer;
  int _locationShareCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      _setupServiceCallbacks();
      _isActive = _safetyService.isActive;
      // Load safety zones on screen init
      await _safetyService.loadSafetyZones();
      if (mounted) {
        setState(() {
          if (_isActive) {
            _startUpdates();
          }
        });
      }
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        setState(() {
          _safetyStatus = 'Error: $e';
        });
      }
    }
  }

  void _setupServiceCallbacks() {
    _safetyService.onSafetyAlert = (String message) {
      if (mounted) {
        _showSafetyAlert(message);
      }
    };
    
    _safetyService.onEmergencyTriggered = () {
      if (mounted) {
        _showEmergencyConfirmation();
      }
    };
    
    _safetyService.onUnsafeZoneDetected = () {
      if (mounted && !kIsWeb) {
        HapticFeedback.heavyImpact();
      }
    };
    
    _safetyService.onLocationUpdate = (position) {
      setState(() {
        _locationShareCount++;
      });
    };

    _safetyService.onLeftSafetyZone = (position) {
      if (mounted) {
        _showSafetyZoneLockDialog(position);
      }
    };
  }

  void _startUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isActive) {
        setState(() {
          _safetyStatus = _safetyService.getSafetyStatus();
        });
      } else {
        timer.cancel();
        _updateTimer = null;
      }
    });
  }

  void _stopUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _toggleSafetyMode() async {
    if (_isActive) {
      _safetyService.stopWomanSafetyMode();
      _stopUpdates();
      setState(() {
        _isActive = false;
        _safetyStatus = 'Inactive';
        _locationShareCount = 0;
      });
    } else {
      try {
        await _safetyService.startWomanSafetyMode();
        _startUpdates();
        setState(() {
          _isActive = true;
          _locationShareCount = 0;
        });
        
        if (!kIsWeb) {
          HapticFeedback.mediumImpact();
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to start safety mode: $e'),
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
    }
  }

  void _showSafetyZoneLockDialog(Position position) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SafetyZoneLockDialog(
        userName: 'You',
        currentPosition: position,
        onUnlocked: () {
          // User confirmed they are safe - STOP the alarm
          _safetyService.stopSafetyZoneAlarm();
          print('User confirmed safety - alarm stopped');
        },
        onTimeout: () {
          // Timeout - send SOS
          _safetyService.sendSOSAlert(position);
          if (mounted) {
            showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('🚨 SOS ALERT SENT'),
                content: Text(
                  'SOS alert has been sent to your emergency contacts.\n\n'
                  'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
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
        },
      ),
    );
  }

  Future<void> _addSafetyZone() async {
    // Show options for adding safety zone
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Safety Zone'),
        message: const Text('Select how you want to set the safety zone'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addSafetyZoneFromMap();
            },
            child: const Text('Select from Map'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addSafetyZoneFromCurrentLocation();
            },
            child: const Text('Use Current Location'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSafetyZoneFromMap() async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select Safety Zone Location',
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      _showSafetyZoneForm(selectedPosition);
    }
  }

  Future<void> _addSafetyZoneFromCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _showSafetyZoneForm(position);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not get current location: $e'),
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
  }

  void _showSafetyZoneForm(Position position) {
    final nameController = TextEditingController();
    double radius = 500.0; // Default 500 meters

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Add Safety Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Zone Name (e.g., Home, Office)',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Safety Zone Radius',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${radius.toInt()} meters',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoSlider(
                  value: radius,
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() {
                      radius = value;
                    });
                  },
                ),
                const Text(
                  'If you leave this zone, you must confirm safety or SOS will be sent',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Add Zone'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final zone = UserSafeZone(
                    name: nameController.text,
                    latitude: position.latitude,
                    longitude: position.longitude,
                    radius: radius,
                  );
                  
                  _safetyService.addSafetyZone(zone);
                  Navigator.pop(context);
                  setState(() {});
                  
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Success'),
                      content: const Text('Safety zone added! You will be alerted if you leave this zone.'),
                      actions: [
                        CupertinoDialogAction(
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
        ),
      ),
    );
  }

  void _showSafetyAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('⚠️ Safety Alert'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showEmergencyConfirmation() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🚨 Emergency Alert Sent'),
        content: const Text(
          'Your emergency alert has been sent to your emergency contacts with your live location.\n\n'
          'Help is on the way!',
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

  @override
  void dispose() {
    _stopUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Woman Safety Mode'),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                          const Color(0xFFE91E63),
                          const Color(0xFFC2185B),
                        ]
                      : [
                          CupertinoColors.systemGrey,
                          CupertinoColors.systemGrey2,
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isActive ? const Color(0xFFE91E63) : CupertinoColors.systemGrey)
                        .withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isActive ? CupertinoIcons.shield_fill : CupertinoIcons.shield,
                    size: 60,
                    color: CupertinoColors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isActive ? 'Safety Mode Active' : 'Safety Mode Inactive',
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
                      color: CupertinoColors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  if (_isActive && _safetyService.isNightMode)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.moon_fill, size: 16, color: CupertinoColors.white),
                          SizedBox(width: 8),
                          Text(
                            'Night Mode',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Quick Actions
            if (_isActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            'Share Location',
                            CupertinoIcons.location_fill,
                            CupertinoColors.systemBlue,
                            () => _safetyService.shareLiveLocation(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            'Call Emergency',
                            CupertinoIcons.phone_fill,
                            CupertinoColors.systemRed,
                            () => _safetyService.callEmergencyContact(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton.filled(
                      color: CupertinoColors.systemRed,
                      onPressed: () => _triggerEmergency(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 20),
                          SizedBox(width: 8),
                          Text('EMERGENCY ALERT'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Stats
            if (_isActive)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Location Shares',
                      '$_locationShareCount',
                      CupertinoIcons.location,
                    ),
                    _buildStatItem(
                      'Status',
                      _safetyStatus,
                      CupertinoIcons.check_mark_circled_solid,
                    ),
                  ],
                ),
              ),

            // Toggle Button
            Container(
              margin: const EdgeInsets.all(16),
              child: CupertinoButton.filled(
                color: _isActive ? CupertinoColors.systemRed : const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _toggleSafetyMode,
                child: Text(
                  _isActive ? 'Stop Safety Mode' : 'Start Safety Mode',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Safety Zones Section
            if (_isActive)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          color: Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Safety Zones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_safetyService.safetyZones.isEmpty)
                      const Text(
                        'No safety zones set. Add zones to get alerts when you leave them.',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      )
                    else
                      ...(_safetyService.safetyZones.map((zone) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: CupertinoColors.systemGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Radius: ${zone.radius.toInt()}m',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList()),
                    const SizedBox(height: 12),
                    CupertinoButton.filled(
                      color: const Color(0xFFE91E63),
                      onPressed: _addSafetyZone,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.add_circled, size: 18),
                          SizedBox(width: 8),
                          Text('Add Safety Zone'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Features Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.info,
                        color: Color(0xFFE91E63),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Safety Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('📍 Automatic location sharing every 30 seconds'),
                  _buildFeatureItem('🌙 Enhanced night mode monitoring (8 PM - 6 AM)'),
                  _buildFeatureItem('⚠️ Unsafe zone detection and alerts'),
                  _buildFeatureItem('🔒 Safety zone monitoring with lock confirmation'),
                  _buildFeatureItem('🚨 Auto SOS if safety not confirmed'),
                  _buildFeatureItem('📞 Quick call to emergency contacts'),
                  _buildFeatureItem('🔔 Real-time safety notifications'),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback UI if build fails
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Woman Safety Mode'),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Screen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE91E63), size: 24),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: Color(0xFFE91E63),
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

  Future<void> _triggerEmergency() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🚨 Emergency Alert'),
        content: const Text(
          'This will send an emergency alert to your emergency contacts with your live location.\n\n'
          'Are you sure?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            isDefaultAction: true,
            child: const Text('Send Alert'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _safetyService.triggerEmergency();
    }
  }
}

