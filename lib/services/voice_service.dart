// lib/services/voice_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isInitialized = false;

  Function(String)? onVoiceCommand;
  Function()? onSOSVoice;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    bool available = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    if (available) {
      await _tts.setLanguage('en');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    if (_isListening) return;

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords.toLowerCase());
          _isListening = false;
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _processVoiceCommand(String command) {
    if (command.contains('sos') || command.contains('emergency') || command.contains('help')) {
      onSOSVoice?.call();
    } else if (command.contains('safe') || command.contains('i am safe')) {
      onVoiceCommand?.call('safe');
    } else if (command.contains('start trip') || command.contains('begin trip')) {
      onVoiceCommand?.call('start_trip');
    } else if (command.contains('share location')) {
      onVoiceCommand?.call('share_location');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _tts.speak(text);
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void stopSpeaking() {
    _tts.stop();
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
}

