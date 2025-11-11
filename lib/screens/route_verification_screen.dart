// lib/screens/route_verification_screen.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../services/security_lock_service.dart';
import '../services/emergency_response_service.dart';

class RouteVerificationScreen extends StatefulWidget {
  final String routeType;
  final Position currentPosition;
  const RouteVerificationScreen({
    super.key,
    required this.routeType,
    required this.currentPosition,
  });

  @override
  State<RouteVerificationScreen> createState() => _RouteVerificationScreenState();
}

class _RouteVerificationScreenState extends State<RouteVerificationScreen> {
  final SecurityLockService _lockService = SecurityLockService();
  final EmergencyResponseService _emergencyService = EmergencyResponseService();
  int _countdown = 30;
  Timer? _countdownTimer;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _lockService.requireVerification();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        if (!_isVerified) {
          _triggerEmergency();
        }
      }
    });
  }

  Future<void> _verifyRoute() async {
    final authenticated = await _lockService.authenticate();
    
    if (authenticated) {
      setState(() {
        _isVerified = true;
      });
      _countdownTimer?.cancel();
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      // Authentication failed - show warning
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Verification Failed'),
          content: const Text('Please try again. If you cannot verify, emergency services will be called.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.pop(context);
                _verifyRoute();
              },
            ),
          ],
        ),
      );
    }
  }

  void _triggerEmergency() {
    _countdownTimer?.cancel();
    _emergencyService.triggerEmergencyResponse(
      location: widget.currentPosition,
      emergencyType: 'Unexpected Route - No Verification',
      startVideoStream: true,
    );
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('🚨 Emergency Alert Sent'),
          content: const Text('Emergency services have been notified. Help is on the way.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, false);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 80,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 24),
                const Text(
                  '⚠️ Unexpected Route Detected',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'You are on an unexpected route.\nPlease verify you are safe.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  onPressed: _verifyRoute,
                  child: const Text('I Am Safe - Verify'),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  color: CupertinoColors.systemRed,
                  onPressed: _triggerEmergency,
                  child: const Text('I Need Help'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

