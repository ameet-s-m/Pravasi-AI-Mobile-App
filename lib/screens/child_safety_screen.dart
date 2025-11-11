// lib/screens/child_safety_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import '../services/child_safety_service.dart';
import '../widgets/safety_zone_lock_dialog.dart';
import 'map_location_picker_screen.dart';

class ChildSafetyScreen extends StatefulWidget {
  const ChildSafetyScreen({super.key});

  @override
  State<ChildSafetyScreen> createState() => _ChildSafetyScreenState();
}

class _ChildSafetyScreenState extends State<ChildSafetyScreen> {
  final ChildSafetyService _childService = ChildSafetyService();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
    _setupListeners();
  }

  Future<void> _initializeService() async {
    await _childService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _setupListeners() {
    _childService.onChildMissing = (childId) {
      _showMissingChildAlert(childId);
    };
    
    _childService.onChildOutOfZone = (childId, position) {
      _showOutOfZoneAlert(childId, position);
    };

    _childService.onSafetyZoneAlert = (childId, position) {
      _showSafetyZoneLockDialog(childId, position);
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _showMissingChildAlert(String childId) {
    final child = _childService.children.firstWhere((c) => c.id == childId);
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🚨 Missing Child Alert'),
        content: Text('${child.name} may be missing!\n\nLast seen: ${child.lastUpdateTime}'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Report Missing'),
            onPressed: () {
              _childService.reportChildMissing(childId);
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showOutOfZoneAlert(String childId, Position position) {
    // This is handled by the lock dialog now
  }

  void _showSafetyZoneLockDialog(String childId, Position position) {
    final child = _childService.children.firstWhere((c) => c.id == childId);
    
    // Check if dialog is already showing
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SafetyZoneLockDialog(
        userName: child.name,
        currentPosition: position,
        onUnlocked: () {
          // User confirmed they are safe
          print('${child.name} confirmed safety');
        },
        onTimeout: () {
          // Timeout - send SOS
          _childService.sendSOSAlert(childId, position);
          if (mounted) {
            showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('🚨 SOS ALERT SENT'),
                content: Text(
                  'SOS alert has been sent to emergency contacts for ${child.name}.\n\n'
                  'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Child Safety'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_childService.children.isEmpty)
              _buildAddChildSection()
            else ...[
              ..._childService.children.map((child) => _buildChildCard(child)),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () => _showAddChildDialog(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add_circled, size: 20),
                    SizedBox(width: 8),
                    Text('Add Another Child'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
      child: const Column(
        children: [
          Icon(CupertinoIcons.person_2_fill, size: 50, color: CupertinoColors.white),
          SizedBox(height: 12),
          Text(
            'Child Safety Monitoring',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track and protect your children',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddChildSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('ADD CHILD'),
      children: [
        CupertinoTextFormFieldRow(
          prefix: const Text('Name'),
          placeholder: 'Child name',
          controller: _nameController,
        ),
        CupertinoTextFormFieldRow(
          prefix: const Text('Age'),
          placeholder: 'Age',
          controller: _ageController,
          keyboardType: TextInputType.number,
        ),
        CupertinoButton.filled(
          onPressed: _addChild,
          child: const Text('Add Child'),
        ),
      ],
    );
  }

  Widget _buildChildCard(ChildProfile child) {
    final isTracking = _childService.children.any((c) => c.id == child.id && c.lastKnownPosition != null);
    final timeSinceUpdate = DateTime.now().difference(child.lastUpdateTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: child.isMissing 
            ? CupertinoColors.systemRed.withOpacity(0.1)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: child.isMissing
            ? Border.all(color: CupertinoColors.systemRed, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemBlue,
                      CupertinoColors.systemPurple,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    child.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (child.isMissing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'MISSING',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.person_fill,
                          size: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Age: ${child.age}',
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 14,
                          ),
                        ),
                        if (isTracking) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Tracking',
                            style: TextStyle(
                              color: CupertinoColors.systemGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (child.lastKnownPosition != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_fill,
                        size: 16,
                        color: CupertinoColors.systemBlue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Last Known Location',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${child.lastKnownPosition!.latitude.toStringAsFixed(6)}, ${child.lastKnownPosition!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated: ${_formatTimeAgo(timeSinceUpdate)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (child.safeZones.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 16,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${child.safeZones.length} Safe Zone(s) Configured',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: isTracking ? CupertinoColors.systemGrey : CupertinoColors.systemBlue,
                  onPressed: () => _startTracking(child.id),
                  child: Text(isTracking ? 'Tracking Active' : 'Start Tracking'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemRed,
                  onPressed: () => _reportMissing(child.id),
                  child: const Text('Report Missing'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemGreen,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => _addSafetyZone(child.id),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.add_circled, size: 16),
                      SizedBox(width: 4),
                      Text('Add Zone', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => _checkInLocation(child.id),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.location_fill, size: 16),
                      SizedBox(width: 4),
                      Text('Check In', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemOrange,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => _setSchoolLocation(child.id),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.building_2_fill, size: 16),
                      SizedBox(width: 4),
                      Text('Set School', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemPurple,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => _setHomeLocation(child.id),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.house_fill, size: 16),
                      SizedBox(width: 4),
                      Text('Set Home', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            color: CupertinoColors.systemIndigo,
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: () => _manageEmergencyContacts(child.id),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.person_2_fill, size: 16),
                SizedBox(width: 8),
                Text('Emergency Contacts'),
              ],
            ),
          ),
          if (child.isMissing)
            const SizedBox(height: 8),
          if (child.isMissing)
            CupertinoButton.filled(
              color: CupertinoColors.systemGreen,
              onPressed: () => _markFound(child.id),
              child: const Text('Mark as Found'),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }

  Future<void> _addChild() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please enter child name and age'),
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

    final child = ChildProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      age: int.tryParse(_ageController.text) ?? 0,
    );

    await _childService.addChild(child);
    setState(() {
      _nameController.clear();
      _ageController.clear();
    });
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Child Added'),
          content: Text('${child.name} has been added to safety monitoring.'),
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

  void _showAddChildDialog() {
    _nameController.clear();
    _ageController.clear();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Child'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Child Name',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _ageController,
              placeholder: 'Age',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              Navigator.pop(context);
              _addChild();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startTracking(String childId) async {
    await _childService.startTrackingChild(childId);
    setState(() {});
  }

  Future<void> _reportMissing(String childId) async {
    await _childService.reportChildMissing(childId);
    setState(() {});
  }

  Future<void> _addSafetyZone(String childId) async {
    final child = _childService.children.firstWhere((c) => c.id == childId);
    
    // Show options for adding safety zone
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Add Safety Zone for ${child.name}'),
        message: const Text('Select how you want to set the safety zone'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addSafetyZoneFromMap(childId);
            },
            child: const Text('Select from Map'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addSafetyZoneFromCurrentLocation(childId);
            },
            child: const Text('Use Current Location'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSafetyZoneFromMap(String childId) async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select Safety Zone Location',
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      _showSafetyZoneForm(childId, selectedPosition);
    }
  }

  Future<void> _addSafetyZoneFromCurrentLocation(String childId) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        _showSafetyZoneForm(childId, position);
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not get current location: $e'),
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

  void _showSafetyZoneForm(String childId, Position position) {
    final nameController = TextEditingController();
    double radius = 500.0; // Default 500 meters

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Add Safety Zone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Zone Name (e.g., Home, School)',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Safety Zone Radius',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${radius.toInt()} meters',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoSlider(
                  value: radius,
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() {
                      radius = value;
                    });
                  },
                ),
                const Text(
                  'Adjust the radius of your safety zone',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.center,
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
              child: const Text('Add Zone'),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    final child = _childService.children.firstWhere((c) => c.id == childId);
                    final zone = SafeZone(
                      name: nameController.text,
                      latitude: position.latitude,
                      longitude: position.longitude,
                      radius: radius,
                    );
                    
                    // Create new list with added zone
                    final updatedSafeZones = List<SafeZone>.from(child.safeZones)..add(zone);
                    
                    // Create updated child profile
                    final updatedChild = ChildProfile(
                      id: child.id,
                      name: child.name,
                      age: child.age,
                      lastKnownPosition: child.lastKnownPosition,
                      safeZones: updatedSafeZones,
                    );
                    
                    // Remove old child and add updated one
                    _childService.children.removeWhere((c) => c.id == childId);
                    await _childService.addChild(updatedChild);
                    
                    Navigator.pop(context);
                    if (mounted) {
                      setState(() {});
                      
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Success'),
                          content: Text('Safety zone added! The app will alert if ${child.name} leaves this zone.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    if (mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Error'),
                          content: Text('Failed to add safety zone: $e'),
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkInLocation(String childId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      await _childService.checkInChildLocation(childId, position);
      
      if (mounted) {
        setState(() {});
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Location Checked In'),
            content: Text(
              'Location updated successfully.\n'
              'Lat: ${position.latitude.toStringAsFixed(6)}\n'
              'Lng: ${position.longitude.toStringAsFixed(6)}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Could not get location: $e'),
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

  Future<void> _setSchoolLocation(String childId) async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select School Location',
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      await _childService.setSchoolLocation(childId, selectedPosition);
      setState(() {});
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('School Location Set'),
          content: const Text('School location has been saved. The app will monitor if your child is at school during school hours.'),
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

  Future<void> _setHomeLocation(String childId) async {
    final selectedPosition = await Navigator.of(context).push<Position>(
      CupertinoPageRoute(
        builder: (context) => MapLocationPickerScreen(
          title: 'Select Home Location',
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      await _childService.setHomeLocation(childId, selectedPosition);
      setState(() {});
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Home Location Set'),
          content: const Text('Home location has been saved. The app will monitor if your child is at home when expected.'),
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

  Future<void> _manageEmergencyContacts(String childId) async {
    final child = _childService.children.firstWhere((c) => c.id == childId);
    final contacts = await _childService.getEmergencyContacts(childId);
    
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: Text('Emergency Contacts for ${child.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No emergency contacts added yet.'),
                  )
                else
                  ...contacts.map((contact) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                contact['phone'] ?? '',
                                style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            await _childService.removeEmergencyContact(childId, contact['phone'] ?? '');
                            setDialogState(() {});
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed),
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: CupertinoColors.separator,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                const SizedBox(height: 8),
                const Text('Add New Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Contact Name',
                  padding: const EdgeInsets.all(12),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: phoneController,
                  placeholder: 'Phone Number',
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
              child: const Text('Add Contact'),
              onPressed: () async {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  await _childService.addEmergencyContact(
                    childId,
                    nameController.text,
                    phoneController.text,
                  );
                  Navigator.pop(context);
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markFound(String childId) async {
    await _childService.markChildFound(childId);
    setState(() {});
    
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Child Marked as Found'),
          content: const Text('The missing child alert has been cleared.'),
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

