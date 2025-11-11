// lib/screens/rewards_screen.dart
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import '../services/rewards_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardsService _rewardsService = RewardsService();
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    await _rewardsService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _redeemReward(String rewardId) async {
    try {
      await _rewardsService.redeemReward(rewardId);
      setState(() {});
      if (mounted) {
        await showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.systemGreen,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text('Reward Redeemed!'),
              ],
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '🎉 Congratulations! Your reward has been redeemed successfully.\n\nYou can use it right away!',
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Awesome!'),
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
            title: const Text('Insufficient Points'),
            content: Text('You need more points to redeem this reward.\n\n$e'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Rewards')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final pointsToNextLevel = ((_rewardsService.level * 100) - _rewardsService.points);
    final progressToNextLevel = _rewardsService.points % 100 / 100.0;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Rewards'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Points Card Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPointsCard(pointsToNextLevel, progressToNextLevel),
              ),
            ),
            
            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickStats(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Achievements Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionHeader('🏆 Achievements', 'View all'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _rewardsService.achievements.length,
                  itemBuilder: (context, index) {
                    return _buildAchievementCard(_rewardsService.achievements[index]);
                  },
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Rewards Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCategorySelector(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Rewards Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionHeader('🎁 Available Rewards', null),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rewards = _getFilteredRewards();
                    if (index >= rewards.length) return null;
                    return _buildRewardCard(rewards[index]);
                  },
                  childCount: _getFilteredRewards().length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionHeader('📊 Recent Activity', null),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRecentActivity(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(int pointsToNextLevel, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CupertinoColors.systemPurple,
            CupertinoColors.systemBlue,
            CupertinoColors.systemTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Points',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_rewardsService.points}',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CupertinoColors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.star_fill,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Level ${_rewardsService.level}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Level',
                    style: TextStyle(
                      color: CupertinoColors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$pointsToNextLevel points needed',
                    style: TextStyle(
                      color: CupertinoColors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withOpacity(0.2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CupertinoColors.white,
                            CupertinoColors.white.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Streak',
            '${_rewardsService.streak} days',
            CupertinoIcons.flame_fill,
            CupertinoColors.systemOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'This Month',
            '${_rewardsService.monthlyPoints} pts',
            CupertinoIcons.calendar,
            CupertinoColors.systemBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Redeemed',
            '${_rewardsService.redeemedCount}',
            CupertinoIcons.gift_fill,
            CupertinoColors.systemGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {},
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemBlue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? CupertinoColors.systemGreen.withOpacity(0.1)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? CupertinoColors.systemGreen
              : CupertinoColors.separator,
          width: achievement.isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.icon,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (achievement.isUnlocked)
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: CupertinoColors.systemGreen,
              size: 20,
            )
          else
            Text(
              '${achievement.points} pts',
              style: const TextStyle(
                fontSize: 10,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['All', 'Discounts', 'Badges', 'Premium', 'Vouchers'];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isSelected
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? CupertinoColors.white
                      : CupertinoColors.label,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final canAfford = _rewardsService.points >= reward.pointsRequired;
    final progress = math.min(_rewardsService.points / reward.pointsRequired, 1.0);
    
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford
              ? CupertinoColors.systemGreen
              : CupertinoColors.separator,
          width: canAfford ? 2 : 1,
        ),
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
          // Reward Icon/Image Area
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getRewardGradient(reward.type),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  _getRewardIcon(reward.type),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          // Reward Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Points and Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${reward.pointsRequired} pts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.secondaryLabel,
                        ),
                      ),
                      if (!canAfford)
                        SizedBox(
                          width: 40,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Redeem Button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: canAfford
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: canAfford
                          ? () => _redeemReward(reward.id)
                          : null,
                      child: Text(
                        canAfford ? 'Redeem' : 'Need ${reward.pointsRequired - _rewardsService.points} more',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canAfford
                              ? CupertinoColors.white
                              : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = _rewardsService.recentActivities;
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No recent activity',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: activities.map((activity) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activity.isEarned
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    activity.isEarned
                        ? CupertinoIcons.arrow_down_circle_fill
                        : CupertinoIcons.gift_fill,
                    color: activity.isEarned
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity.isEarned ? '+${activity.points}' : '-${activity.points}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: activity.isEarned
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemOrange,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Reward> _getFilteredRewards() {
    if (_selectedCategory == 'All') {
      return _rewardsService.availableRewards;
    }
    return _rewardsService.availableRewards.where((reward) {
      switch (_selectedCategory) {
        case 'Discounts':
          return reward.type == RewardType.discount;
        case 'Badges':
          return reward.type == RewardType.badge;
        case 'Premium':
          return reward.type == RewardType.premium;
        case 'Vouchers':
          return reward.type == RewardType.voucher;
        default:
          return true;
      }
    }).toList();
  }

  String _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.badge:
        return '🏅';
      case RewardType.discount:
        return '💰';
      case RewardType.premium:
        return '⭐';
      case RewardType.voucher:
        return '🎫';
    }
  }

  List<Color> _getRewardGradient(RewardType type) {
    switch (type) {
      case RewardType.badge:
        return [
          CupertinoColors.systemYellow.withOpacity(0.3),
          CupertinoColors.systemOrange.withOpacity(0.3),
        ];
      case RewardType.discount:
        return [
          CupertinoColors.systemGreen.withOpacity(0.3),
          CupertinoColors.systemTeal.withOpacity(0.3),
        ];
      case RewardType.premium:
        return [
          CupertinoColors.systemPurple.withOpacity(0.3),
          CupertinoColors.systemBlue.withOpacity(0.3),
        ];
      case RewardType.voucher:
        return [
          CupertinoColors.systemPink.withOpacity(0.3),
          CupertinoColors.systemRed.withOpacity(0.3),
        ];
    }
  }
}
