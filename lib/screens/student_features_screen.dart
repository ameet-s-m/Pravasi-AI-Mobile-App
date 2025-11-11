// lib/screens/student_features_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentFeaturesScreen extends StatefulWidget {
  const StudentFeaturesScreen({super.key});

  @override
  State<StudentFeaturesScreen> createState() => _StudentFeaturesScreenState();
}

class _StudentFeaturesScreenState extends State<StudentFeaturesScreen> {
  bool _isStudentVerified = false;
  String? _studentId;
  String? _institutionName;
  final _studentIdController = TextEditingController();
  final _institutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isStudentVerified = prefs.getBool('student_verified') ?? false;
      _studentId = prefs.getString('student_id');
      _institutionName = prefs.getString('institution_name');
      if (_studentId != null) {
        _studentIdController.text = _studentId!;
      }
      if (_institutionName != null) {
        _institutionController.text = _institutionName!;
      }
    });
  }

  Future<void> _verifyStudent() async {
    if (_studentIdController.text.isEmpty || _institutionController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Missing Information'),
          content: const Text('Please enter Student ID and Institution name'),
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

    // In real app, verify with institution
    // For demo, just save
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('student_verified', true);
    await prefs.setString('student_id', _studentIdController.text);
    await prefs.setString('institution_name', _institutionController.text);

    setState(() {
      _isStudentVerified = true;
      _studentId = _studentIdController.text;
      _institutionName = _institutionController.text;
    });

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Verified!'),
          content: const Text('Student verification successful. You now have access to student discounts!'),
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
        middle: Text('Student Features'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                  const Icon(
                    CupertinoIcons.person_3_fill,
                    size: 60,
                    color: CupertinoColors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Student Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isStudentVerified
                        ? 'Verified Student Account'
                        : 'Verify to unlock student benefits',
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verification Section
            if (!_isStudentVerified) ...[
              CupertinoFormSection.insetGrouped(
                header: const Text('STUDENT VERIFICATION'),
                children: [
                  CupertinoTextFormFieldRow(
                    prefix: const Text('Student ID'),
                    placeholder: 'Enter your student ID',
                    controller: _studentIdController,
                  ),
                  CupertinoTextFormFieldRow(
                    prefix: const Text('Institution'),
                    placeholder: 'School/College name',
                    controller: _institutionController,
                  ),
                  CupertinoButton.filled(
                    onPressed: _verifyStudent,
                    child: const Text('Verify Student Status'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Student Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemGreen,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.systemGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Student Verified',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Student ID', _studentId ?? ''),
                    _buildInfoRow('Institution', _institutionName ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Student Benefits
            CupertinoFormSection.insetGrouped(
              header: const Text('STUDENT BENEFITS'),
              children: [
                _buildBenefitCard(
                  'Transport Discounts',
                  'Get 20% off on bus and train bookings',
                  CupertinoIcons.car_detailed,
                  CupertinoColors.systemBlue,
                  _isStudentVerified,
                ),
                _buildBenefitCard(
                  'Campus Navigation',
                  'Find your way around campus easily',
                  CupertinoIcons.map_fill,
                  CupertinoColors.systemGreen,
                  _isStudentVerified,
                ),
                _buildBenefitCard(
                  'Study Groups',
                  'Find and join study groups nearby',
                  CupertinoIcons.group_solid,
                  CupertinoColors.systemOrange,
                  _isStudentVerified,
                ),
                _buildBenefitCard(
                  'Library Finder',
                  'Locate nearest libraries and study spaces',
                  CupertinoIcons.book_fill,
                  CupertinoColors.systemPurple,
                  _isStudentVerified,
                ),
                _buildBenefitCard(
                  'Budget Tools',
                  'Track expenses and split bills with friends',
                  CupertinoIcons.money_dollar_circle_fill,
                  CupertinoColors.systemTeal,
                  _isStudentVerified,
                ),
                _buildBenefitCard(
                  'Student Events',
                  'Discover events and activities on campus',
                  CupertinoIcons.calendar,
                  CupertinoColors.systemRed,
                  _isStudentVerified,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(
    String title,
    String description,
    IconData icon,
    Color color,
    bool enabled,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? CupertinoColors.white : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? color.withOpacity(0.3) : CupertinoColors.separator,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled ? color.withOpacity(0.1) : CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: enabled ? color : CupertinoColors.secondaryLabel,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: enabled ? CupertinoColors.black : CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled ? CupertinoColors.secondaryLabel : CupertinoColors.tertiaryLabel,
                  ),
                ),
              ],
            ),
          ),
          if (!enabled)
            const Icon(
              CupertinoIcons.lock_fill,
              color: CupertinoColors.secondaryLabel,
              size: 20,
            ),
        ],
      ),
    );
  }
}

