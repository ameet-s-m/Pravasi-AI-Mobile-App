// lib/screens/community_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/dummy_data.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedSegment = 0;
  final Map<int, String> _segments = {
    0: 'All',
    1: 'Walking',
    2: 'Heritage',
    3: 'Data'
  };

  List<CommunityTrip> get _filteredTrips {
    // Use dummy data for demonstration
    if (_selectedSegment == 0) {
      return DummyData.communityTrips;
    }
    
    final filterTag = _segments[_selectedSegment]!.toLowerCase();
    return DummyData.communityTrips.where((trip) {
      return trip.tags.any((tag) => tag.toLowerCase().contains(filterTag));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Community'),
            middle: const Text('Community'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSegmentedControl<int>(
                children: _segments.map((key, value) => MapEntry(
                  key,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
                onValueChanged: (int value) {
                  setState(() {
                    _selectedSegment = value;
                  });
                },
                groupValue: _selectedSegment,
              ),
            ),
          ),
          _filteredTrips.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.group,
                          size: 64,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Community Trips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Community trips feature coming soon.\nReal trips will be shown here.',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _filteredTrips.length) return null;
                      return _buildCommunityTripCard(context, _filteredTrips[index]);
                    },
                    childCount: _filteredTrips.length,
                  ),
                ),
        ],
      )
    );
  }

  Widget _buildCommunityTripCard(BuildContext context, CommunityTrip trip) {
    final isHeritage = trip.tags.any((tag) => tag.toLowerCase().contains('heritage'));
    final isWalking = trip.tags.any((tag) => tag.toLowerCase().contains('walking'));
    final isData = trip.tags.any((tag) => tag.toLowerCase().contains('data'));
    
    Color categoryColor = CupertinoColors.systemBlue;
    if (isHeritage) {
      categoryColor = CupertinoColors.systemPurple;
    } else if (isWalking) categoryColor = CupertinoColors.systemGreen;
    else if (isData) categoryColor = CupertinoColors.systemOrange;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withOpacity(0.08),
              categoryColor.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.1),
              blurRadius: 12,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [categoryColor, categoryColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      trip.avatarLetter,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.author,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildTripInfoRow(
                    CupertinoIcons.calendar,
                    trip.date,
                    categoryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTripInfoRow(
                    CupertinoIcons.group,
                    trip.participants,
                    categoryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              trip.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withOpacity(0.15),
                      categoryColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Join Trip'),
                      content: Text('You have successfully joined "${trip.title}"!'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [categoryColor, categoryColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Join Trip',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripInfoRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: CupertinoColors.label,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}