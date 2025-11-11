// lib/widgets/safety_zone_lock_dialog.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class SafetyZoneLockDialog extends StatefulWidget {
  final String userName;
  final Position currentPosition;
  final Function() onUnlocked;
  final Function() onTimeout;

  const SafetyZoneLockDialog({
    super.key,
    required this.userName,
    required this.currentPosition,
    required this.onUnlocked,
    required this.onTimeout,
  });

  @override
  State<SafetyZoneLockDialog> createState() => _SafetyZoneLockDialogState();
}

class _SafetyZoneLockDialogState extends State<SafetyZoneLockDialog> {
  bool _isUnlocked = false;
  int _countdown = 30; // 30 seconds to unlock
  Timer? _countdownTimer;
  Timer? _vibrationTimer;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startVibration();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });

        if (_countdown <= 0 && !_isUnlocked) {
          _hasTimedOut = true;
          timer.cancel();
          _vibrationTimer?.cancel();
          widget.onTimeout();
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _startVibration() {
    if (!kIsWeb) {
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        if (!_isUnlocked && !_hasTimedOut && mounted) {
          HapticFeedback.heavyImpact();
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _unlock() {
    if (!_isUnlocked) {
      setState(() {
        _isUnlocked = true;
      });
      _countdownTimer?.cancel();
      _vibrationTimer?.cancel();
      widget.onUnlocked();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing by back button
      child: CupertinoAlertDialog(
        title: const Text('⚠️ SAFETY ZONE ALERT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              '${widget.userName}, you are about to leave your safety zone!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please confirm you want to proceed, or stay within your safety zone.',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.lock_fill,
                    size: 50,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please confirm you are safe',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (!_isUnlocked)
                    Text(
                      'Time remaining: $_countdown seconds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _countdown <= 10
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemBlue,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'If you do not unlock within 30 seconds, an SOS alert will be sent to your emergency contacts.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            isDefaultAction: true,
            onPressed: _isUnlocked ? null : _unlock,
            child: const Text('UNLOCK & CONFIRM SAFE'),
          ),
        ],
      ),
    );
  }
}

