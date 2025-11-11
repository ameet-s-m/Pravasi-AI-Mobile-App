// lib/services/video_streaming_service.dart
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class VideoStreamingService {
  static final VideoStreamingService _instance = VideoStreamingService._internal();
  factory VideoStreamingService() => _instance;
  VideoStreamingService._internal();

  bool _isStreaming = false;
  Position? _currentLocation;
  Timer? _locationUpdateTimer;

  Function(Position location)? onLocationUpdate;
  Function(String streamUrl)? onStreamStarted;

  Future<void> startStreaming() async {
    if (_isStreaming) return;
    
    _isStreaming = true;
    
    // Get initial location
    _currentLocation = await Geolocator.getCurrentPosition();
    onLocationUpdate?.call(_currentLocation!);
    
    // Update location every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _currentLocation = await Geolocator.getCurrentPosition();
      onLocationUpdate?.call(_currentLocation!);
    });

    // In real app, start actual video stream using LiveKit
    final streamUrl = 'rtmp://stream.pravasiai.com/live/${DateTime.now().millisecondsSinceEpoch}';
    onStreamStarted?.call(streamUrl);
    
    print('Video streaming started: $streamUrl');
  }

  Future<void> shareStreamWithContacts(List<String> contactIds) async {
    if (!_isStreaming) await startStreaming();
    
    // Share stream URL with emergency contacts
    for (var contactId in contactIds) {
      await _sendStreamLink(contactId);
    }
  }

  Future<void> _sendStreamLink(String contactId) async {
    // Send stream link via SMS/notification
    final message = '🚨 LIVE STREAM ALERT 🚨\n\n'
        'Emergency live stream is active.\n'
        'Watch here: [Stream URL]\n'
        'Location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}';
    
    print('Stream link sent to $contactId: $message');
  }

  void stopStreaming() {
    _isStreaming = false;
    _locationUpdateTimer?.cancel();
  }

  bool get isStreaming => _isStreaming;
  Position? get currentLocation => _currentLocation;
}

