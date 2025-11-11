// lib/services/rewards_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class RewardsService {
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  int _points = 0;
  int _level = 1;
  int _streak = 0;
  int _monthlyPoints = 0;
  int _redeemedCount = 0;
  List<Reward> _availableRewards = [];
  List<Achievement> _achievements = [];
  List<Activity> _recentActivities = [];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('reward_points') ?? 0;
    _level = prefs.getInt('reward_level') ?? 1;
    _streak = prefs.getInt('reward_streak') ?? 0;
    _monthlyPoints = prefs.getInt('reward_monthly_points') ?? 0;
    _redeemedCount = prefs.getInt('reward_redeemed_count') ?? 0;
    _loadRewards();
    _loadAchievements();
    _loadRecentActivities();
  }

  void _loadRewards() {
    _availableRewards = [
      Reward(
        id: '1',
        name: 'Safety Badge',
        description: 'Complete 10 safe trips',
        pointsRequired: 100,
        type: RewardType.badge,
      ),
      Reward(
        id: '2',
        name: 'Travel Discount',
        description: '10% off on next booking',
        pointsRequired: 200,
        type: RewardType.discount,
      ),
      Reward(
        id: '3',
        name: 'Premium Features',
        description: 'Unlock premium features for 1 month',
        pointsRequired: 500,
        type: RewardType.premium,
      ),
      Reward(
        id: '4',
        name: 'Community Helper',
        description: 'Report 5 incidents',
        pointsRequired: 150,
        type: RewardType.badge,
      ),
      Reward(
        id: '5',
        name: '20% Off Voucher',
        description: 'Use on any transport booking',
        pointsRequired: 300,
        type: RewardType.voucher,
      ),
      Reward(
        id: '6',
        name: 'Free Trip',
        description: 'One free trip up to ₹500',
        pointsRequired: 1000,
        type: RewardType.voucher,
      ),
      Reward(
        id: '7',
        name: 'Explorer Badge',
        description: 'Travel 500 km',
        pointsRequired: 250,
        type: RewardType.badge,
      ),
      Reward(
        id: '8',
        name: '15% Discount',
        description: 'Save on your next journey',
        pointsRequired: 180,
        type: RewardType.discount,
      ),
    ];
  }

  void _loadAchievements() {
    _achievements = [
      Achievement(
        id: '1',
        name: 'First Trip',
        description: 'Complete your first trip',
        points: 10,
        icon: '🎯',
        isUnlocked: _points >= 10,
      ),
      Achievement(
        id: '2',
        name: 'Safety Champion',
        description: '100 safe trips completed',
        points: 500,
        icon: '🛡️',
        isUnlocked: _points >= 500,
      ),
      Achievement(
        id: '3',
        name: 'Community Hero',
        description: 'Help 10 people in community',
        points: 300,
        icon: '👥',
        isUnlocked: _points >= 300,
      ),
      Achievement(
        id: '4',
        name: 'Explorer',
        description: 'Travel 1000 km',
        points: 200,
        icon: '🗺️',
        isUnlocked: _points >= 200,
      ),
      Achievement(
        id: '5',
        name: 'Early Bird',
        description: 'Complete 5 trips before 8 AM',
        points: 150,
        icon: '🌅',
        isUnlocked: _points >= 150,
      ),
      Achievement(
        id: '6',
        name: 'Night Owl',
        description: 'Complete 5 trips after 10 PM',
        points: 150,
        icon: '🦉',
        isUnlocked: _points >= 150,
      ),
    ];
  }

  void _loadRecentActivities() {
    _recentActivities = [
      Activity(
        description: 'Completed safe trip',
        points: 10,
        date: 'Today',
        isEarned: true,
      ),
      Activity(
        description: 'Redeemed Travel Discount',
        points: 200,
        date: '2 days ago',
        isEarned: false,
      ),
      Activity(
        description: 'Reported incident',
        points: 5,
        date: '3 days ago',
        isEarned: true,
      ),
      Activity(
        description: 'Daily login bonus',
        points: 5,
        date: '4 days ago',
        isEarned: true,
      ),
    ];
  }

  Future<void> addPoints(int points, String reason) async {
    _points += points;
    _monthlyPoints += points;
    await _savePoints();
    await _saveMonthlyPoints();
    await _checkLevelUp();
    await _checkAchievements(reason);
    
    // Add to recent activities
    _recentActivities.insert(0, Activity(
      description: reason,
      points: points,
      date: 'Just now',
      isEarned: true,
    ));
    if (_recentActivities.length > 10) {
      _recentActivities.removeLast();
    }
  }

  Future<void> _checkLevelUp() async {
    final newLevel = (_points / 100).floor() + 1;
    if (newLevel > _level) {
      _level = newLevel;
      await _saveLevel();
    }
  }

  Future<void> _checkAchievements(String reason) async {
    // Update achievement unlock status
    for (var achievement in _achievements) {
      if (!achievement.isUnlocked && _points >= achievement.points) {
        achievement.isUnlocked = true;
      }
    }
  }

  Future<void> redeemReward(String rewardId) async {
    final reward = _availableRewards.firstWhere((r) => r.id == rewardId);
    if (_points >= reward.pointsRequired) {
      _points -= reward.pointsRequired;
      _redeemedCount++;
      await _savePoints();
      await _saveRedeemedCount();
      
      // Add to recent activities
      _recentActivities.insert(0, Activity(
        description: 'Redeemed ${reward.name}',
        points: reward.pointsRequired,
        date: 'Just now',
        isEarned: false,
      ));
      if (_recentActivities.length > 10) {
        _recentActivities.removeLast();
      }
    } else {
      throw Exception('Not enough points');
    }
  }

  Future<void> _savePoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reward_points', _points);
  }

  Future<void> _saveLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reward_level', _level);
  }

  Future<void> _saveMonthlyPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reward_monthly_points', _monthlyPoints);
  }

  Future<void> _saveRedeemedCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reward_redeemed_count', _redeemedCount);
  }

  int get points => _points;
  int get level => _level;
  int get streak => _streak;
  int get monthlyPoints => _monthlyPoints;
  int get redeemedCount => _redeemedCount;
  List<Reward> get availableRewards => _availableRewards;
  List<Achievement> get achievements => _achievements;
  List<Activity> get recentActivities => _recentActivities;
}

class Reward {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final RewardType type;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.type,
  });
}

enum RewardType {
  badge,
  discount,
  premium,
  voucher,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final int points;
  final String icon;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.icon,
    this.isUnlocked = false,
  });
}

class Activity {
  final String description;
  final int points;
  final String date;
  final bool isEarned;

  Activity({
    required this.description,
    required this.points,
    required this.date,
    required this.isEarned,
  });
}
