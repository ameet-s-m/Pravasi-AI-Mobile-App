// lib/screens/user_manual_screen.dart
import 'package:flutter/cupertino.dart';

class UserManualScreen extends StatefulWidget {
  const UserManualScreen({super.key});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  int _selectedSection = 0;

  final List<ManualSection> _sections = [
    ManualSection(
      title: 'Getting Started',
      icon: CupertinoIcons.play_circle_fill,
      content: [
        ManualItem(
          title: '1. Grant Permissions',
          description: 'Allow location, camera, contacts, and microphone access for full functionality.',
        ),
        ManualItem(
          title: '2. Set Emergency Contacts',
          description: 'Go to Profile → Emergency Contact to add trusted contacts who will receive alerts.',
        ),
        ManualItem(
          title: '3. Plan Your First Trip',
          description: 'Tap "New Trip" on home screen. You can manually enter details or use OCR to scan tickets.',
        ),
      ],
    ),
    ManualSection(
      title: 'Safety Features',
      icon: CupertinoIcons.shield_fill,
      content: [
        ManualItem(
          title: 'Route Deviation Detection',
          description: 'If driver changes route, app asks for safety confirmation. No response in 30 seconds triggers emergency alert.',
        ),
        ManualItem(
          title: 'SOS Button',
          description: 'Long-press the red SOS button on home screen to instantly send emergency alerts.',
        ),
        ManualItem(
          title: 'Voice Commands',
          description: 'Say "I am safe" or "SOS" during tracking for hands-free safety confirmation.',
        ),
        ManualItem(
          title: 'Route Learning',
          description: 'App learns your daily routes. Unexpected routes require security lock verification.',
        ),
        ManualItem(
          title: 'Emotion Detection',
          description: 'Wearable device integration detects panic/distress and triggers emergency response.',
        ),
      ],
    ),
    ManualSection(
      title: 'Travel Features',
      icon: CupertinoIcons.map_fill,
      content: [
        ManualItem(
          title: 'Navigation',
          description: 'Built-in navigation with turn-by-turn directions. Replaces Google Maps.',
        ),
        ManualItem(
          title: 'Transport Booking',
          description: 'Compare and book Bus, Train, Taxi, Auto, or Flight. Find cheapest options.',
        ),
        ManualItem(
          title: 'Hotel Alerts',
          description: 'Get notified when hotels are nearby. Book directly from the app.',
        ),
        ManualItem(
          title: 'Weather Alerts',
          description: 'Real-time weather updates and travel advisories for your location.',
        ),
        ManualItem(
          title: 'Expense Tracking',
          description: 'Track trip expenses by category. Set budgets and get alerts.',
        ),
        ManualItem(
          title: 'Journey Summary',
          description: 'View complete trip reports with distance, duration, expenses, and safety score.',
        ),
      ],
    ),
    ManualSection(
      title: 'AI Features',
      icon: CupertinoIcons.sparkles,
      content: [
        ManualItem(
          title: 'AI Copilot',
          description: 'Ask questions about travel, safety, routes. Get AI-powered advice using Gemini AI.',
        ),
        ManualItem(
          title: 'OCR Trip Upload',
          description: 'Scan bus/train tickets with camera. App extracts origin, destination, and time automatically.',
        ),
        ManualItem(
          title: 'Accident Detection',
          description: 'Upload photo of accident scene. AI analyzes and calls ambulance if needed.',
        ),
        ManualItem(
          title: 'Motorcycle Mode',
          description: 'Detects accidents from sound, speed, and activity. Auto-calls ambulance.',
        ),
      ],
    ),
    ManualSection(
      title: 'Community Features',
      icon: CupertinoIcons.person_3_fill,
      content: [
        ManualItem(
          title: 'Incident Reporting',
          description: 'Report unsafe areas or incidents to help the community stay safe.',
        ),
        ManualItem(
          title: 'Safe Zones',
          description: 'View and add safe locations. Rate and review safe zones.',
        ),
        ManualItem(
          title: 'Community Alerts',
          description: 'Receive alerts about incidents reported by other users in your area.',
        ),
      ],
    ),
    ManualSection(
      title: 'Child Safety',
      icon: CupertinoIcons.person_2_fill,
      content: [
        ManualItem(
          title: 'Child Tracking',
          description: 'Monitor child\'s location in real-time. Set safe zones and get alerts.',
        ),
        ManualItem(
          title: 'Missing Child Alert',
          description: 'Instantly alert community and emergency contacts if child goes missing.',
        ),
      ],
    ),
    ManualSection(
      title: 'Rewards & Analytics',
      icon: CupertinoIcons.chart_bar_fill,
      content: [
        ManualItem(
          title: 'Earn Points',
          description: 'Get points for safe trips, reporting incidents, and helping community.',
        ),
        ManualItem(
          title: 'Achievements',
          description: 'Unlock badges like "Safety Champion", "Community Hero", "Explorer".',
        ),
        ManualItem(
          title: 'Safety Analytics',
          description: 'View safety scores, trip statistics, and insights about your travel patterns.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('How PRAVASI AI Works'),
      ),
      child: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              border: Border(
                right: BorderSide(
                  color: CupertinoColors.separator,
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: _sections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return CupertinoButton(
                  padding: const EdgeInsets.all(12),
                  color: _selectedSection == index
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.transparent,
                  onPressed: () {
                    setState(() {
                      _selectedSection = index;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        section.icon,
                        size: 20,
                        color: _selectedSection == index
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section.title,
                          style: TextStyle(
                            color: _selectedSection == index
                                ? CupertinoColors.white
                                : CupertinoColors.label,
                            fontWeight: _selectedSection == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Icon(
                      _sections[_selectedSection].icon,
                      size: 40,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _sections[_selectedSection].title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ..._sections[_selectedSection].content.map((item) => _buildManualItem(item)),
                const SizedBox(height: 40),
                _buildQuickTips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualItem(ManualItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.systemPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.lightbulb_fill,
                color: CupertinoColors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Quick Tips',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTip('💡 Always set emergency contacts before traveling'),
          _buildTip('💡 Enable route learning for better safety detection'),
          _buildTip('💡 Use voice commands for hands-free safety'),
          _buildTip('💡 Check weather alerts before starting trips'),
          _buildTip('💡 Track expenses to manage travel budget'),
          _buildTip('💡 Report incidents to help community safety'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: CupertinoColors.white,
          height: 1.5,
        ),
      ),
    );
  }
}

class ManualSection {
  final String title;
  final IconData icon;
  final List<ManualItem> content;

  ManualSection({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class ManualItem {
  final String title;
  final String description;

  ManualItem({
    required this.title,
    required this.description,
  });
}

