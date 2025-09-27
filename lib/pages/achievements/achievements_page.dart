import 'dart:math';
import 'package:flutter/material.dart';
import 'package:everyday_lilly/services/achievement_service.dart';

// Import our new widgets
import 'package:everyday_lilly/pages/achievements/achievement_card.dart';
import 'package:everyday_lilly/pages/achievements/achievement_summary.dart';
import 'package:everyday_lilly/pages/achievements/achievement_filters.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

enum AchievementFilter { all, unlocked, inProgress, locked }

class _AchievementsPageState extends State<AchievementsPage> {
  final _random = Random();
  AchievementFilter _filter = AchievementFilter.all;

  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'First Photo Added',
      'description': 'Add your very first photo.',
      'progress': 0,
      'unlocked': false,
      'rewardType': 'quote',
      'reward': [
        'Why don’t scientists trust atoms? Because they make up everything!',
        'I told my computer I needed a break, and it said "No problem, I’ll go to sleep."',
      ],
    },
    {
      'title': '10 Photos Taken',
      'description': 'Take 10 photos in total.',
      'progress': 0,
      'unlocked': false,
      'rewardType': 'quote',
      'reward': [
        'I’m reading a book on anti-gravity. It’s impossible to put down!',
        'Parallel lines have so much in common. It’s a shame they’ll never meet.',
      ],
    },
    {
      'title': '30 Photos Taken',
      'description': 'Take 30 photos in total.',
      'progress': 0,
      'unlocked': false,
      'rewardType': 'quote',
      'reward': [
        'Why did the scarecrow win an award? Because he was outstanding in his field!',
        'I would tell you a construction joke, but I’m still working on it.',
      ],
    },
    {
      'title': '100 Photos Taken',
      'description': 'Capture 100 photos on your journey.',
      'progress': 0,
      'unlocked': false,
      'rewardType': 'quote',
      'reward': [
        'I told a joke about a roof once... it went over everyone’s head.',
        'I’m on a seafood diet. I see food and I eat it.',
      ],
    },
    {
      'title': '10 Days in a Row',
      'description': 'Add a photo 10 days in a row.',
      'progress': 0,
      'unlocked': false,
      'rewardType': 'quote',
      'reward': [
        'Why don’t skeletons fight each other? They don’t have the guts.',
        'I’m reading a book about anti-gravity. It’s impossible to put down!',
      ],
    },
    {
      'title': 'First Note Added',
      'description': 'Attach a note to a photo for the first time.',
      'progress': 0,
      'unlocked': false,
      'rewardType': 'quote',
      'reward': [
        'I’m on a whiskey diet. I’ve lost three days already.',
        'I told my computer I needed a break, and it said "No problem, I’ll go to sleep."',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final photos = await AchievementService.getPhotosTaken();
    final daysWithPhotos = await AchievementService.getDaysWithPhotos();
    final notes = await AchievementService.getNotesAdded();

    for (final a in _achievements) {
      final title = a['title'] as String;

      if (title == 'First Photo Added') {
        a['progress'] = photos > 0 ? 100 : 0;
        a['unlocked'] = photos > 0;
      } else if (title == '10 Photos Taken') {
        final pct = ((photos / 10) * 100).clamp(0, 100).round();
        a['progress'] = pct;
        a['unlocked'] = pct >= 100;
      } else if (title == '30 Photos Taken') {
        final pct = ((photos / 30) * 100).clamp(0, 100).round();
        a['progress'] = pct;
        a['unlocked'] = pct >= 100;
      } else if (title == '100 Photos Taken') {
        final pct = ((photos / 100) * 100).clamp(0, 100).round();
        a['progress'] = pct;
        a['unlocked'] = pct >= 100;
      } else if (title == '10 Days in a Row') {
        final pct = ((daysWithPhotos / 10) * 100).clamp(0, 100).round();
        a['progress'] = pct;
        a['unlocked'] = pct >= 100;
      } else if (title == 'First Note Added') {
        a['progress'] = notes > 0 ? 100 : 0;
        a['unlocked'] = notes > 0;
      }
    }

    setState(() {});
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> list, AchievementFilter filter) {
    switch (filter) {
      case AchievementFilter.unlocked:
        return list.where((a) => _status(a) == 'unlocked').toList();
      case AchievementFilter.inProgress:
        return list.where((a) => _status(a) == 'inProgress').toList();
      case AchievementFilter.locked:
        return list.where((a) => _status(a) == 'locked').toList();
      case AchievementFilter.all:
      default:
        return list;
    }
  }

  String _status(Map<String, dynamic> a) {
    final unlocked = (a['unlocked'] as bool?) ?? false;
    final progress = (a['progress'] as int?) ?? 0;
    if (unlocked || progress >= 100) return 'unlocked';
    if (progress > 0) return 'inProgress';
    return 'locked';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2E3C43) : const Color(0xFFF9FAFB);

    final items = _filtered(_achievements, _filter);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          AchievementSummary(achievements: _achievements),
          const SizedBox(height: 8),
          AchievementFilters(
            filter: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final achievement = items[index];
                return AchievementCard(
                  achievement: achievement,
                  status: _status(achievement),
                  random: _random,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}