// lib/services/security_lock_service.dart
import 'package:local_auth/local_auth.dart';
import 'dart:async';

class SecurityLockService {
  static final SecurityLockService _instance = SecurityLockService._internal();
  factory SecurityLockService() => _instance;
  SecurityLockService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLocked = false;
  Timer? _lockTimer;
  
  Function()? onLockRequired;
  Function()? onLockFailed;
  Function()? onLockSuccess;

  Future<bool> authenticate() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        // Fallback to PIN/pattern
        return await _authenticateWithPIN();
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to confirm you are safe',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        onLockSuccess?.call();
        return true;
      } else {
        onLockFailed?.call();
        return false;
      }
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  Future<bool> _authenticateWithPIN() async {
    // In real app, show PIN entry dialog
    // For demo, simulate authentication
    return true;
  }

  Future<void> requireVerification() async {
    _isLocked = true;
    onLockRequired?.call();
    
    // Start countdown - if not unlocked in 30 seconds, trigger emergency
    _lockTimer = Timer(const Duration(seconds: 30), () {
      if (_isLocked) {
        onLockFailed?.call();
      }
    });
  }

  Future<void> verifyAndUnlock() async {
    final authenticated = await authenticate();
    
    if (authenticated) {
      _isLocked = false;
      _lockTimer?.cancel();
      onLockSuccess?.call();
    } else {
      // Authentication failed - trigger emergency
      onLockFailed?.call();
    }
  }

  void cancelVerification() {
    _lockTimer?.cancel();
    _isLocked = false;
  }

  bool get isLocked => _isLocked;
  bool get canAuthenticate => true; // Check device capabilities
}

