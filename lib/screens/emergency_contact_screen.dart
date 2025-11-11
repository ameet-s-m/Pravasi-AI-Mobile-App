// lib/screens/emergency_contact_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:contacts_service/contacts_service.dart'; // Temporarily disabled due to compatibility issues

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _savedContactName;
  String? _savedContactNumber;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedContactName = prefs.getString('emergency_contact_name');
      _savedContactNumber = prefs.getString('emergency_contact_number');
      if (_savedContactName != null) {
        _nameController.text = _savedContactName!;
      }
      if (_savedContactNumber != null) {
        _phoneController.text = _savedContactNumber!;
      }
    });
  }

  Future<void> _pickFromContacts() async {
    // Contact picker temporarily disabled - please enter manually
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Contact Picker'),
          content: const Text('Please enter the contact details manually. Contact picker will be available in a future update.'),
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

  Future<void> _saveEmergencyContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please enter both name and phone number'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact_name', _nameController.text);
    await prefs.setString('emergency_contact_number', _phoneController.text);

    setState(() {
      _savedContactName = _nameController.text;
      _savedContactNumber = _phoneController.text;
    });

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Saved'),
          content: const Text('Emergency contact saved successfully'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Emergency Contact'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('EMERGENCY CONTACT'),
              children: [
                CupertinoTextFormFieldRow(
                  prefix: const Text('Name'),
                  placeholder: 'Enter contact name',
                  controller: _nameController,
                ),
                CupertinoTextFormFieldRow(
                  prefix: const Text('Phone'),
                  placeholder: 'Enter phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.person_add),
                  title: const Text('Pick from Contacts'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _pickFromContacts,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _saveEmergencyContact,
              child: const Text('Save Emergency Contact'),
            ),
            if (_savedContactName != null && _savedContactNumber != null) ...[
              const SizedBox(height: 24),
              CupertinoFormSection.insetGrouped(
                header: const Text('CURRENT EMERGENCY CONTACT'),
                children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.person_circle_fill, color: CupertinoColors.systemRed),
                    title: Text(_savedContactName!),
                    subtitle: Text(_savedContactNumber!),
                    trailing: const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemGreen),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• If route deviation is detected, you\'ll be asked to confirm safety\n'
                    '• If no response within 30 seconds, your live location will be sent to this contact\n'
                    '• The contact will receive an SMS with your location and a Google Maps link',
                    style: TextStyle(fontSize: 14),
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

