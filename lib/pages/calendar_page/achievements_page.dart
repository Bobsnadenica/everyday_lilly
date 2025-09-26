import 'dart:math';

import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final achievements = [
      {
        'title': 'First Photo Added',
        'description': 'Add your very first photo.',
        'progress': 100,
        'unlocked': true,
        'rewardType': 'quote',
        'reward': [
          'Why don’t scientists trust atoms? Because they make up everything!',
          'I told my computer I needed a break, and it said "No problem, I’ll go to sleep."',
        ],
      },
      {
        'title': '10 Photos Taken',
        'description': 'Take 10 photos in total.',
        'progress': 60,
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
        'progress': 20,
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
        'progress': 40,
        'unlocked': false,
        'rewardType': 'quote',
        'reward': [
          'Why don’t skeletons fight each other? They don’t have the guts.',
          'I’m reading a book about anti-gravity. It’s impossible to put down!',
        ],
      },
      {
        'title': 'Consistent Weekly Uploads',
        'description': 'Add at least one photo every week for 4 weeks.',
        'progress': 75,
        'unlocked': false,
        'rewardType': 'quote',
        'reward': [
          'I told my wife she was drawing her eyebrows too high. She looked surprised.',
          'I would avoid the sushi if I was you. It’s a little fishy.',
        ],
      },
      {
        'title': 'First Note Added',
        'description': 'Attach a note to a photo for the first time.',
        'progress': 100,
        'unlocked': true,
        'rewardType': 'quote',
        'reward': [
          'I’m on a whiskey diet. I’ve lost three days already.',
          'I told my computer I needed a break, and it said "No problem, I’ll go to sleep."',
        ],
      },
      {
        'title': 'Backup Exported',
        'description': 'Export your backup for the first time.',
        'progress': 10,
        'unlocked': false,
        'rewardType': 'quote',
        'reward': [
          'Why do bees have sticky hair? Because they use a honeycomb.',
          'I’m reading a book on the history of glue – can’t put it down.',
        ],
      },
      {
        'title': 'Shared First Timelapse',
        'description': 'Share a timelapse video.',
        'progress': 0,
        'unlocked': false,
        'rewardType': 'quote',
        'reward': [
          'I would tell you a joke about time travel, but you didn’t like it.',
          'Why don’t programmers like nature? It has too many bugs.',
        ],
      },
      {
        'title': 'First Year Completed',
        'description': 'Complete a full year of photos.',
        'progress': 0,
        'unlocked': false,
        'rewardType': 'quote',
        'reward': [
          'I’m reading a book about teleportation. It’s bound to get me somewhere.',
          'Why was the math book sad? Because it had too many problems.',
        ],
      },
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressTextColor = isDark ? Colors.grey[100] : Colors.grey[900];
    final descriptionTextColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final rewardTextColor = isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);
    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final backgroundColor = isDark ? const Color(0xFF2E3C43) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 40),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF26454B), const Color(0xFF2E3C43)]
                  : [Colors.green.shade700, Colors.green.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          child: AppBar(
            title: const Text(
              'Achievements',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final unlocked = achievement['unlocked'] as bool;
          final progress = (achievement['progress'] as int).clamp(0, 100);
          final rewardType = achievement['rewardType'] as String?;
          final reward = achievement['reward'] as List<dynamic>?;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 6,
            shadowColor: isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  color: unlocked ? Colors.green.shade700 : Colors.grey.shade500,
                  size: 38,
                ),
                title: Text(
                  achievement['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: titleTextColor,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['description'] as String,
                        style: TextStyle(
                          color: descriptionTextColor,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!unlocked) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$progress%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: progressTextColor,
                            ),
                          ),
                        ),
                      ],
                      if (unlocked && rewardType == 'quote' && reward != null && reward.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.emoji_emotions_outlined, color: rewardTextColor, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward[random.nextInt(reward.length)] as String,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: rewardTextColor,
                                        fontSize: 18,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (reward.length > 1) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap for reward',
                                        style: TextStyle(
                                          color: rewardTextColor.withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                enabled: unlocked,
              ),
            ),
          );
        },
      ),
    );
  }
}