// lib/screens/permissions_disclaimer_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsDisclaimerScreen extends StatefulWidget {
  final VoidCallback? onAccept;
  const PermissionsDisclaimerScreen({super.key, this.onAccept});

  @override
  State<PermissionsDisclaimerScreen> createState() => _PermissionsDisclaimerScreenState();
}

class _PermissionsDisclaimerScreenState extends State<PermissionsDisclaimerScreen> {
  final bool _hasScrolled = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    size: 80,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Permissions Required',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'PRAVASI AI needs the following permissions to keep you safe and provide the best experience.',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildPermissionItem(
                    icon: CupertinoIcons.location_fill,
                    title: 'Location Access',
                    description: 'Required for navigation, route tracking, safety alerts, and location sharing during emergencies.',
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    icon: CupertinoIcons.camera_fill,
                    title: 'Camera Access',
                    description: 'Needed for OCR to scan trip tickets, accident photo detection, and emergency video streaming.',
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    icon: CupertinoIcons.phone_fill,
                    title: 'Phone & Contacts',
                    description: 'Required to call emergency contacts, send SMS alerts, and access your emergency contacts list.',
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    icon: CupertinoIcons.mic_fill,
                    title: 'Microphone',
                    description: 'Needed for voice commands, safety confirmations, and hands-free emergency activation.',
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Notifications',
                    description: 'To receive safety alerts, route deviation warnings, hotel nearby alerts, and emergency notifications.',
                    color: CupertinoColors.systemPurple,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionItem(
                    icon: CupertinoIcons.folder_fill,
                    title: 'Storage Access',
                    description: 'To save trip data, export journey summaries, and store emergency contact information.',
                    color: CupertinoColors.systemTeal,
                  ),
                  const SizedBox(height: 30),
                  Container(
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
                              CupertinoIcons.info_circle_fill,
                              color: CupertinoColors.systemBlue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Why We Need These',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Location: Track your route and detect deviations for safety\n'
                          '• Camera: Scan tickets and detect accidents\n'
                          '• Contacts: Send emergency alerts to your loved ones\n'
                          '• Microphone: Voice-activated safety features\n'
                          '• Notifications: Real-time safety alerts\n'
                          '• Storage: Save your trip history and data',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemYellow,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.lock_shield_fill,
                          color: CupertinoColors.systemYellow,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Privacy Matters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'All data is stored locally on your device. We never share your location or personal information without your explicit consent.',
                                style: TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    CupertinoButton.filled(
                      onPressed: () async {
                        // Request all permissions
                        await _requestPermissions();
                        if (widget.onAccept != null) {
                          widget.onAccept!();
                        }
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Grant Permissions'),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Not Now'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
      Permission.contacts,
      Permission.microphone,
      Permission.notification,
      Permission.storage,
    ];

    for (var permission in permissions) {
      await permission.request();
    }
  }
}

