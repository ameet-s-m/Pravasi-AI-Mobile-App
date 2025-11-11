// lib/screens/elderly_care_mode_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ElderlyCareModeScreen extends StatefulWidget {
  const ElderlyCareModeScreen({super.key});

  @override
  State<ElderlyCareModeScreen> createState() => _ElderlyCareModeScreenState();
}

class _ElderlyCareModeScreenState extends State<ElderlyCareModeScreen> {
  bool _isElderlyModeEnabled = false;
  bool _voiceGuidance = true;
  bool _largeFonts = true;
  bool _bigButtons = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isElderlyModeEnabled = prefs.getBool('elderly_mode_enabled') ?? false;
      _voiceGuidance = prefs.getBool('elderly_voice_guidance') ?? true;
      _largeFonts = prefs.getBool('elderly_large_fonts') ?? true;
      _bigButtons = prefs.getBool('elderly_big_buttons') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('elderly_mode_enabled', _isElderlyModeEnabled);
    await prefs.setBool('elderly_voice_guidance', _voiceGuidance);
    await prefs.setBool('elderly_large_fonts', _largeFonts);
    await prefs.setBool('elderly_big_buttons', _bigButtons);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = _largeFonts ? 24.0 : 16.0;
    final buttonHeight = _bigButtons ? 70.0 : 50.0;
    final bigButtons = _bigButtons;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Elderly Care Mode',
          style: TextStyle(fontSize: fontSize),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(bigButtons ? 24 : 16),
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(bigButtons ? 32 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemOrange,
                    CupertinoColors.systemRed,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.person_fill,
                    size: bigButtons ? 80 : 60,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(height: bigButtons ? 20 : 16),
                  Text(
                    'Elderly Care Mode',
                    style: TextStyle(
                      fontSize: fontSize + 8,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: bigButtons ? 12 : 8),
                  Text(
                    'Easy-to-use interface with large fonts and big buttons',
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      color: CupertinoColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: bigButtons ? 32 : 24),

            // Enable/Disable Toggle
            Container(
              padding: EdgeInsets.all(bigButtons ? 24 : 20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CupertinoColors.separator),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Elderly Care Mode',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: bigButtons ? 8 : 4),
                        Text(
                          'Makes the app easier to use',
                          style: TextStyle(
                            fontSize: fontSize - 4,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isElderlyModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isElderlyModeEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: bigButtons ? 24 : 16),

            // Settings
            if (_isElderlyModeEnabled) ...[
              _buildSettingTile(
                'Large Fonts',
                'Makes text easier to read',
                _largeFonts,
                (value) {
                  setState(() {
                    _largeFonts = value;
                  });
                  _saveSettings();
                },
                fontSize,
              ),
              SizedBox(height: bigButtons ? 16 : 12),
              _buildSettingTile(
                'Big Buttons',
                'Larger touch targets',
                _bigButtons,
                (value) {
                  setState(() {
                    _bigButtons = value;
                  });
                  _saveSettings();
                },
                fontSize,
              ),
              SizedBox(height: bigButtons ? 16 : 12),
              _buildSettingTile(
                'Voice Guidance',
                'Audio instructions for navigation',
                _voiceGuidance,
                (value) {
                  setState(() {
                    _voiceGuidance = value;
                  });
                  _saveSettings();
                },
                fontSize,
              ),
              SizedBox(height: bigButtons ? 32 : 24),

              // Emergency Button
              SizedBox(
                height: buttonHeight * 1.5,
                width: double.infinity,
                child: CupertinoButton.filled(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Trigger emergency
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text(
                          'Emergency Alert',
                          style: TextStyle(fontSize: fontSize),
                        ),
                        content: Text(
                          'Emergency contacts will be notified',
                          style: TextStyle(fontSize: fontSize - 4),
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: Text('OK', style: TextStyle(fontSize: fontSize)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: fontSize + 8,
                        color: CupertinoColors.white,
                      ),
                      SizedBox(width: bigButtons ? 16 : 12),
                      Text(
                        'EMERGENCY',
                        style: TextStyle(
                          fontSize: fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    double fontSize,
  ) {
    final bigButtons = _bigButtons;
    return Container(
      padding: EdgeInsets.all(bigButtons ? 20 : 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: bigButtons ? 4 : 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: fontSize - 4,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

