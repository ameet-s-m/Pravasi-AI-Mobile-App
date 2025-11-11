// lib/screens/profile_switcher_screen.dart
import 'package:flutter/cupertino.dart';
import '../services/family_service.dart';

class ProfileSwitcherScreen extends StatefulWidget {
  const ProfileSwitcherScreen({super.key});

  @override
  State<ProfileSwitcherScreen> createState() => _ProfileSwitcherScreenState();
}

class _ProfileSwitcherScreenState extends State<ProfileSwitcherScreen> {
  final FamilyService _familyService = FamilyService();
  String? _currentProfile;
  final List<Profile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    await _familyService.initialize();
    final current = _familyService.getCurrentProfile();
    
    setState(() {
      _currentProfile = current;
      _profiles.clear();
      _profiles.addAll([
        Profile(
          id: 'personal',
          name: 'Personal',
          icon: CupertinoIcons.person_fill,
          color: CupertinoColors.systemBlue,
        ),
        Profile(
          id: 'work',
          name: 'Work',
          icon: CupertinoIcons.briefcase_fill,
          color: CupertinoColors.systemPurple,
        ),
      ]);
      
      // Add family profiles
      final members = _familyService.getMembers();
      for (var member in members) {
        _profiles.add(Profile(
          id: member.id,
          name: member.name,
          icon: _getIconForRelationship(member.relationship),
          color: CupertinoColors.systemGreen,
        ));
      }
    });
  }

  IconData _getIconForRelationship(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'parent':
        return CupertinoIcons.person_2_fill;
      case 'child':
        return CupertinoIcons.person_fill;
      case 'spouse':
        return CupertinoIcons.heart_fill;
      default:
        return CupertinoIcons.person_fill;
    }
  }

  Future<void> _switchProfile(String profileId) async {
    await _familyService.switchProfile(profileId);
    setState(() {
      _currentProfile = profileId;
    });
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Profile Switched'),
          content: Text('Switched to ${_profiles.firstWhere((p) => p.id == profileId).name} profile'),
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

  Future<void> _addNewProfile() async {
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (context) {
        String profileName = '';
        return CupertinoAlertDialog(
          title: const Text('New Profile'),
          content: CupertinoTextField(
            placeholder: 'Profile name',
            onChanged: (value) => profileName = value,
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Create'),
              onPressed: () => Navigator.pop(context, profileName),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      final newProfile = Profile(
        id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        icon: CupertinoIcons.person_fill,
        color: CupertinoColors.systemOrange,
      );
      
      setState(() {
        _profiles.add(newProfile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Switch Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _addNewProfile,
          child: const Icon(CupertinoIcons.add_circled),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Profile
            Container(
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
                children: [
                  const Text(
                    'Current Profile',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentProfile != null)
                    Text(
                      _profiles.firstWhere(
                        (p) => p.id == _currentProfile,
                        orElse: () => _profiles.first,
                      ).name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profiles List
            CupertinoFormSection.insetGrouped(
              header: const Text('AVAILABLE PROFILES'),
              children: _profiles.map((profile) {
                final isActive = profile.id == _currentProfile;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? profile.color.withOpacity(0.1)
                        : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive 
                          ? profile.color
                          : CupertinoColors.separator,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: CupertinoListTile(
                    leading: Icon(
                      profile.icon,
                      color: profile.color,
                      size: 28,
                    ),
                    title: Text(
                      profile.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.systemGreen,
                          )
                        : null,
                    onTap: () => _switchProfile(profile.id),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle_fill,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Different profiles help you organize personal, work, and family trips separately.',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Profile {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Profile({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

