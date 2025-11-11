// lib/screens/settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'data_export_screen.dart';
import '../services/simple_mode_service.dart';
import '../services/ai_copilot_service.dart';
import '../services/accident_detection_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SimpleModeService _simpleModeService = SimpleModeService();
  bool _isSimpleMode = false;
  bool _isLoading = true;
  String? _familyContactName;
  String? _familyContactNumber;
  final _familyNameController = TextEditingController();
  final _familyPhoneController = TextEditingController();
  String? _geminiApiKey;
  final _geminiApiKeyController = TextEditingController();
  String? _ambulanceWhatsAppNumber;
  final _ambulanceWhatsAppController = TextEditingController();
  bool _sosAutoCallEnabled = false;
  bool _ambulanceAutoCallEnabled = false;
  String _sosRingtone = 'System Alert'; // Default ringtone
  String? _customRingtonePath; // Path to custom ringtone file
  final List<String> _availableRingtones = [
    'System Alert',
    'Emergency Alarm',
    'Loud Siren',
    'Alert Tone',
    'Urgent Beep',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _familyPhoneController.dispose();
    _geminiApiKeyController.dispose();
    _ambulanceWhatsAppController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final isSimple = await _simpleModeService.isSimpleModeEnabled();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSimpleMode = isSimple;
      _familyContactName = prefs.getString('family_contact_name');
      _familyContactNumber = prefs.getString('family_contact_number');
      _geminiApiKey = prefs.getString('gemini_api_key');
      _ambulanceWhatsAppNumber = prefs.getString('ambulance_whatsapp_number');
      // AI assistant call is always enabled by default
      _sosAutoCallEnabled = prefs.getBool('sos_auto_call_enabled') ?? true;
      _ambulanceAutoCallEnabled = prefs.getBool('ambulance_auto_call_enabled') ?? false;
      _sosRingtone = prefs.getString('sos_ringtone') ?? 'System Alert';
      _customRingtonePath = prefs.getString('sos_custom_ringtone_path');
      if (_familyContactName != null) {
        _familyNameController.text = _familyContactName!;
      }
      if (_familyContactNumber != null) {
        _familyPhoneController.text = _familyContactNumber!;
      }
      if (_geminiApiKey != null) {
        _geminiApiKeyController.text = _geminiApiKey!;
      }
      if (_ambulanceWhatsAppNumber != null) {
        _ambulanceWhatsAppController.text = _ambulanceWhatsAppNumber!;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveFamilyContact() async {
    if (_familyNameController.text.isEmpty || _familyPhoneController.text.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Missing Information'),
            content: const Text('Please enter both name and phone number'),
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_contact_name', _familyNameController.text);
    await prefs.setString('family_contact_number', _familyPhoneController.text);

    setState(() {
      _familyContactName = _familyNameController.text;
      _familyContactNumber = _familyPhoneController.text;
    });

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Saved'),
          content: const Text('Family contact saved successfully. This number will receive SOS alerts automatically.'),
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

  void _showFamilyContactDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Family Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Set a family contact number that will automatically receive SOS alerts with live location via SMS and WhatsApp.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _familyNameController,
                placeholder: 'Family Member Name',
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _familyPhoneController,
                placeholder: 'Phone Number (with country code)',
                keyboardType: TextInputType.phone,
                padding: const EdgeInsets.all(12),
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
            child: const Text('Save'),
            onPressed: () {
              Navigator.pop(context);
              _saveFamilyContact();
            },
          ),
        ],
      ),
    );
  }

  void _showGeminiApiKeyDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Gemini API Key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Enter your Google Gemini API key. This enables:\n\n'
                '• AI Assistant & Copilot\n'
                '• Accident Detection from Photos\n'
                '• Smart Image Analysis\n\n'
                'Get your API key from: https://makersuite.google.com/app/apikey',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _geminiApiKeyController,
                placeholder: 'Paste your Gemini API key here',
                padding: const EdgeInsets.all(12),
                obscureText: true,
                autocorrect: false,
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
            child: const Text('Save'),
            onPressed: () {
              Navigator.pop(context);
              _saveGeminiApiKey();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveGeminiApiKey() async {
    final apiKey = _geminiApiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Invalid API Key'),
            content: const Text('Please enter a valid Gemini API key'),
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);

    setState(() {
      _geminiApiKey = apiKey;
    });

    // Initialize services with the new API key
    await _initializeAIServices(apiKey);

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('API Key Saved'),
          content: const Text('Gemini API key has been saved and AI services have been initialized.'),
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

  Future<void> _initializeAIServices(String apiKey) async {
    // Initialize AI Copilot Service
    final aiCopilotService = AICopilotService();
    await aiCopilotService.initialize(apiKey);
    
    // Initialize Accident Detection Service
    final accidentService = AccidentDetectionService();
    await accidentService.initializeGemini(apiKey);
  }

  void _showRingtoneSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select SOS Ringtone'),
        message: const Text('Choose a loud ringtone for SOS alerts'),
        actions: _availableRingtones.map((ringtone) {
          return CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ringtone),
                      if (ringtone == 'Custom' && _customRingtonePath != null)
                        Text(
                          _getFileName(_customRingtonePath!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (_sosRingtone == ringtone)
                  const Icon(CupertinoIcons.check_mark, color: CupertinoColors.systemBlue),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              if (ringtone == 'Custom') {
                _pickCustomRingtone();
              } else {
                _selectRingtone(ringtone);
              }
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  String _getFileName(String path) {
    if (kIsWeb) {
      return path.split('/').last;
    }
    // Use path separator for non-web platforms
    try {
      return path.split(io.Platform.pathSeparator).last;
    } catch (e) {
      // Fallback if Platform is not available
      return path.split('/').last.split('\\').last;
    }
  }

  Future<void> _pickCustomRingtone() async {
    if (kIsWeb) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Not Available'),
            content: const Text('Custom ringtone selection is not available on web. Please use the mobile app.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        // Validate file extension
        final validExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
        final fileExtension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
        
        if (!validExtensions.contains(fileExtension)) {
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Invalid File'),
                content: Text('Please select an audio file (${validExtensions.join(', ')})'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // Save custom ringtone path
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sos_custom_ringtone_path', filePath);
        await prefs.setString('sos_ringtone', 'Custom');
        
        setState(() {
          _customRingtonePath = filePath;
          _sosRingtone = 'Custom';
        });

        // Play preview
        _playCustomRingtonePreview(filePath);
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Custom Ringtone Selected'),
              content: Text('SOS will now use: $fileName'),
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
    } catch (e) {
      print('Error picking custom ringtone: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to select custom ringtone: $e'),
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

  Future<void> _playCustomRingtonePreview(String filePath) async {
    // Preview will be played in SOS button
    // Just show a message here
    print('Custom ringtone selected: $filePath');
  }

  Future<void> _selectRingtone(String ringtone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sos_ringtone', ringtone);
    
    setState(() {
      _sosRingtone = ringtone;
    });
    
    // Play preview of selected ringtone
    _playRingtonePreview(ringtone);
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Ringtone Selected'),
          content: Text('SOS will now use: $ringtone'),
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

  void _playRingtonePreview(String ringtone) {
    // Preview the ringtone by playing system alert sound
    // This gives user a sense of the pattern
    try {
      SystemSound.play(SystemSoundType.alert);
      SystemSound.play(SystemSoundType.alert);
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('Error playing ringtone preview: $e');
    }
  }

  void _showAmbulanceWhatsAppDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ambulance WhatsApp Number'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Enter the WhatsApp number for ambulance services. This number will receive automatic accident reports with AI-analyzed details and location.\n\n'
                'Format: Include country code (e.g., 911234567890 for India)',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _ambulanceWhatsAppController,
                placeholder: 'Enter WhatsApp number (with country code)',
                keyboardType: TextInputType.phone,
                padding: const EdgeInsets.all(12),
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
            child: const Text('Save'),
            onPressed: () {
              Navigator.pop(context);
              _saveAmbulanceWhatsApp();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveAmbulanceWhatsApp() async {
    final number = _ambulanceWhatsAppController.text.trim();
    
    if (number.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Invalid Number'),
            content: const Text('Please enter a valid WhatsApp number'),
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ambulance_whatsapp_number', number);

    setState(() {
      _ambulanceWhatsAppNumber = number;
    });

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Saved'),
          content: const Text('Ambulance WhatsApp number saved. Accident reports will be sent to this number automatically.'),
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

  Future<void> _toggleSOSAutoCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sos_auto_call_enabled', value);
    setState(() {
      _sosAutoCallEnabled = value;
    });
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(value ? 'SOS Auto-Call Enabled' : 'SOS Auto-Call Disabled'),
          content: Text(
            value
                ? 'When SOS is triggered, the app will automatically call your family contact with AI-generated emergency details.'
                : 'SOS auto-calling has been disabled.',
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

  Future<void> _toggleAmbulanceAutoCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ambulance_auto_call_enabled', value);
    setState(() {
      _ambulanceAutoCallEnabled = value;
    });
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(value ? 'Ambulance Auto-Call Enabled' : 'Ambulance Auto-Call Disabled'),
          content: Text(
            value
                ? 'When an accident is detected, the app will automatically call ambulance services with AI-generated accident details.'
                : 'Ambulance auto-calling has been disabled.',
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

  Future<void> _toggleSimpleMode(bool value) async {
    await _simpleModeService.setSimpleMode(value);
    setState(() {
      _isSimpleMode = value;
    });
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(value ? 'Simple Mode Enabled' : 'Simple Mode Disabled'),
          content: Text(
            value
                ? 'You will now see only essential safety features in a clean grid layout. This makes the app easier to use.'
                : 'All features are now available.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                // Return true to indicate settings changed, so home screen can refresh
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CupertinoFormSection.insetGrouped(
                    header: const Text('APP MODE'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.square_grid_2x2),
                        title: const Text('Simple Mode'),
                        subtitle: const Text('Show only essential safety features'),
                        trailing: CupertinoSwitch(
                          value: _isSimpleMode,
                          onChanged: _toggleSimpleMode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('SAFETY SETTINGS'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.heart_fill, color: CupertinoColors.systemRed),
                        title: const Text('Family Contact'),
                        subtitle: _familyContactName != null
                            ? Text('$_familyContactName - $_familyContactNumber')
                            : const Text('Set family contact for SOS alerts'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _showFamilyContactDialog,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.bell_fill, color: CupertinoColors.systemOrange),
                        title: const Text('SOS Ringtone'),
                        subtitle: _sosRingtone == 'Custom' && _customRingtonePath != null
                            ? Text('Custom: ${_getFileName(_customRingtonePath!)}')
                            : Text('Current: $_sosRingtone'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _showRingtoneSelector,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed),
                        title: const Text('SOS Auto-Call'),
                        subtitle: const Text('AI will call family with emergency details'),
                        trailing: CupertinoSwitch(
                          value: _sosAutoCallEnabled,
                          onChanged: (value) => _toggleSOSAutoCall(value),
                        ),
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.phone_fill, color: CupertinoColors.systemRed),
                        title: const Text('Ambulance WhatsApp'),
                        subtitle: _ambulanceWhatsAppNumber != null && _ambulanceWhatsAppNumber!.isNotEmpty
                            ? Text('$_ambulanceWhatsAppNumber')
                            : const Text('Set WhatsApp number for accident alerts'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _showAmbulanceWhatsAppDialog,
                      ),
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.phone_fill, color: CupertinoColors.systemRed),
                        title: const Text('Ambulance Auto-Call'),
                        subtitle: const Text('AI will call ambulance with accident details'),
                        trailing: CupertinoSwitch(
                          value: _ambulanceAutoCallEnabled,
                          onChanged: (value) => _toggleAmbulanceAutoCall(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('AI SETTINGS'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.sparkles, color: CupertinoColors.systemBlue),
                        title: const Text('Gemini API Key'),
                        subtitle: _geminiApiKey != null && _geminiApiKey!.isNotEmpty
                            ? Text('${_geminiApiKey!.substring(0, 8)}...${_geminiApiKey!.substring(_geminiApiKey!.length - 4)}')
                            : const Text('Required for AI Assistant & Accident Detection'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _showGeminiApiKeyDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('ACCOUNT'),
                    children: [
                      const CupertinoListTile(
                        leading: Icon(CupertinoIcons.person),
                        title: Text('Account Settings'),
                        trailing: CupertinoListTileChevron(),
                      ),
                      const CupertinoListTile(
                        leading: Icon(CupertinoIcons.lock),
                        title: Text('Privacy & Security'),
                        trailing: CupertinoListTileChevron(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('NOTIFICATIONS'),
                    children: [
                      const CupertinoListTile(
                        leading: Icon(CupertinoIcons.bell),
                        title: Text('Notification Settings'),
                        trailing: CupertinoListTileChevron(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('DATA'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(CupertinoIcons.arrow_down_circle),
                        title: const Text('Export Trip Data'),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const DataExportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoFormSection.insetGrouped(
                    header: const Text('SUPPORT'),
                    children: [
                      const CupertinoListTile(
                        leading: Icon(CupertinoIcons.question_circle),
                        title: Text('Help & Support'),
                        trailing: CupertinoListTileChevron(),
                      ),
                      const CupertinoListTile(
                        leading: Icon(CupertinoIcons.info),
                        title: Text('About'),
                        trailing: CupertinoListTileChevron(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
