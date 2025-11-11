// lib/screens/driver_verification_screen.dart
import 'package:flutter/cupertino.dart';
import '../models/models.dart';

class DriverVerificationScreen extends StatefulWidget {
  final DriverInfo? driverInfo;
  const DriverVerificationScreen({super.key, this.driverInfo});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _nameController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _phoneController = TextEditingController();
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    if (widget.driverInfo != null) {
      _nameController.text = widget.driverInfo!.name;
      _vehicleController.text = widget.driverInfo!.vehicleNumber;
      _phoneController.text = widget.driverInfo!.phoneNumber;
      _rating = widget.driverInfo!.rating;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.driverInfo == null ? 'Verify Driver' : 'Driver Info'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.driverInfo != null) ...[
              _buildDriverCard(widget.driverInfo!),
              const SizedBox(height: 24),
            ],
            CupertinoFormSection.insetGrouped(
              header: const Text('DRIVER INFORMATION'),
              children: [
                CupertinoTextFormFieldRow(
                  prefix: const Text('Name'),
                  placeholder: 'Driver name',
                  controller: _nameController,
                ),
                CupertinoTextFormFieldRow(
                  prefix: const Text('Vehicle'),
                  placeholder: 'Vehicle number',
                  controller: _vehicleController,
                ),
                CupertinoTextFormFieldRow(
                  prefix: const Text('Phone'),
                  placeholder: 'Phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection.insetGrouped(
              header: const Text('RATING'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _rating = (index + 1).toDouble();
                              });
                            },
                            child: Icon(
                              index < _rating.toInt()
                                  ? CupertinoIcons.star_fill
                                  : CupertinoIcons.star,
                              color: CupertinoColors.systemYellow,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _saveDriverInfo,
              child: const Text('Save Driver Info'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(DriverInfo driver) {
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
        children: [
          if (driver.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            driver.name,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            driver.vehicleNumber,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.star_fill, color: CupertinoColors.systemYellow, size: 20),
              const SizedBox(width: 4),
              Text(
                '${driver.rating.toStringAsFixed(1)} (${driver.totalRides} rides)',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveDriverInfo() {
    // Save driver information
    Navigator.pop(context);
  }
}

