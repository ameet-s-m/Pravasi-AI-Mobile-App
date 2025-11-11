// lib/screens/accident_report_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/accident_detection_service.dart';

// Conditional import for File
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class AccidentReportScreen extends StatefulWidget {
  const AccidentReportScreen({super.key});

  @override
  State<AccidentReportScreen> createState() => _AccidentReportScreenState();
}

class _AccidentReportScreenState extends State<AccidentReportScreen> {
  final AccidentDetectionService _accidentService = AccidentDetectionService();
  dynamic _selectedImage;
  Position? _currentLocation;
  bool _isAnalyzing = false;
  bool _accidentDetected = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
      if (image != null) {
        setState(() {
          if (!kIsWeb) {
            _selectedImage = io.File(image.path);
          } else {
            _selectedImage = image; // Use XFile on web
          }
          _isAnalyzing = true;
        });

        if (_currentLocation != null && !kIsWeb) {
          final isAccident = await _accidentService.detectAccidentFromPhoto(_selectedImage);
          
          setState(() {
            _isAnalyzing = false;
            _accidentDetected = isAccident;
          });

          if (isAccident) {
            // Check if auto-call is enabled and request permission
            final prefs = await SharedPreferences.getInstance();
            final ambulanceAutoCallEnabled = prefs.getBool('ambulance_auto_call_enabled') ?? false;
            
            bool? callPermission = true; // Default to true if auto-call disabled
            if (ambulanceAutoCallEnabled) {
              callPermission = await showCupertinoDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('📞 Auto-Call Ambulance'),
                  content: const Text(
                    'The app will now call ambulance services with AI-generated accident details.\n\n'
                    'Do you want to proceed with the call?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('Call Now'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
            }
            
            if (callPermission == true) {
              await _accidentService.processAccidentPhoto(_selectedImage, _currentLocation!);
              _showAccidentDetectedDialog();
            }
          } else {
            // Even if AI doesn't detect, allow manual report
            _showManualReportOption();
          }
        } else if (kIsWeb) {
          setState(() {
            _isAnalyzing = false;
          });
          // Show message that this feature is not available on web
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Feature Not Available'),
              content: const Text('Accident detection from photos is not available on web. Please use the mobile app.'),
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

  void _showAccidentDetectedDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🚨 Accident Detected'),
        content: const Text(
          'An accident has been detected in the image.\n\n'
          '✅ Ambulance has been called automatically\n'
          '✅ Location and photo sent to emergency services\n'
          '✅ Police notified\n'
          '✅ Emergency contacts alerted\n\n'
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

  void _showManualReportOption() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('⚠️ Accident Not Detected'),
        content: const Text(
          'AI did not detect an accident in the image.\n\n'
          'If this is an emergency, you can still report it manually.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            isDefaultAction: true,
            child: const Text('Report Anyway'),
            onPressed: () {
              Navigator.pop(context);
              _reportManually();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reportManually() async {
    if (_currentLocation == null || _selectedImage == null) return;
    
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Report accident manually - still call ambulance
      await _accidentService.reportNearbyAccident(_selectedImage, _currentLocation!);
      
      setState(() {
        _isAnalyzing = false;
        _accidentDetected = true;
      });
      
      _showAccidentDetectedDialog();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to report accident: $e'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Emergency Report'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CupertinoColors.systemRed.withOpacity(0.2),
                    CupertinoColors.systemOrange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.systemRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 50,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Report Nearby Accident',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan an accident scene with camera. Our AI will:\n\n'
                    '✅ Analyze the image automatically\n'
                    '✅ Call ambulance (108) with AI-generated details\n'
                    '✅ Send location & photo to WhatsApp ambulance number\n'
                    '✅ Notify police (100)\n'
                    '✅ Alert your emergency contacts\n\n'
                    'Note: Set ambulance WhatsApp number in Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedImage != null)
              Container(
                height: 300,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: CupertinoColors.systemGrey,
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 50,
                            color: CupertinoColors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    color: CupertinoColors.systemRed,
                    onPressed: _isAnalyzing ? null : () => _pickImage(source: ImageSource.camera),
                    child: _isAnalyzing
                        ? const CupertinoActivityIndicator()
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.camera_fill, size: 20),
                              SizedBox(width: 8),
                              Text('Scan from Camera'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed: _isAnalyzing ? null : () => _pickImage(source: ImageSource.gallery),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.photo, size: 20),
                        SizedBox(width: 8),
                        Text('Choose from Gallery'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null && !_isAnalyzing && !_accidentDetected) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _reportManually,
                child: const Text('Report Emergency Manually'),
              ),
            ],
            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Analyzing image with AI...',
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              ),
            ],
            if (_accidentDetected) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Accident detected. Emergency services have been notified.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

