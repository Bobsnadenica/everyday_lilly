import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final String status; // unlocked, inProgress, locked
  final Random random;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.status,
    required this.random,
  });

  bool get unlocked => status == 'unlocked';
  bool get inProgress => status == 'inProgress';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.grey[300] : Colors.grey[800];
    final accent = isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00796B);

    final progress = (achievement['progress'] as int).clamp(0, 100);
    final reward = achievement['reward'] as List<dynamic>?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      shadowColor: isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        onTap: () {
          if (unlocked && _hasReward()) {
            _showRewardSheet(context, reward!, accent);
          } else if (inProgress) {
            _showSnack(context, 'Keep going — ${100 - progress}% to unlock!');
          } else {
            _showSnack(context, 'Locked — start this to unlock.');
          }
        },
        leading: Icon(
          unlocked
              ? Icons.check_circle_rounded
              : (inProgress ? Icons.hourglass_bottom_rounded : Icons.lock_outline_rounded),
          color: unlocked ? Colors.green.shade700 : (inProgress ? Colors.amber.shade700 : Colors.grey.shade500),
          size: 36,
        ),
        title: Text(
          achievement['title'] as String,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: titleTextColor),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement['description'] as String,
                style: TextStyle(color: secondaryText, fontSize: 14.5, height: 1.35),
              ),
              const SizedBox(height: 14),

              // Progress bar for locked or in progress
              if (!unlocked) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress / 100),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          inProgress ? Colors.amber.shade700 : Colors.grey.shade500,
                        ),
                        minHeight: 12,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$progress%',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: secondaryText),
                  ),
                ),
              ],

              // Reward preview for unlocked achievements
              if (unlocked && _hasReward()) ...[
                const SizedBox(height: 14),
                _FrostedRewardPreview(
                  text: _peekRewardText(),
                  accent: accent,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to view reward',
                  style: TextStyle(
                    color: accent.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  bool _hasReward() {
    final reward = achievement['reward'] as List<dynamic>?;
    return achievement['rewardType'] == 'quote' && reward != null && reward.isNotEmpty;
  }

  String _peekRewardText() {
    final reward = (achievement['reward'] as List<dynamic>?) ?? const [];
    if (reward.isEmpty) return 'Reward ready!';
    return reward[random.nextInt(reward.length)] as String;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showRewardSheet(BuildContext context, List<dynamic> reward, Color accent) {
    final text = reward.isNotEmpty ? reward[random.nextInt(reward.length)] as String : '🎁 You unlocked a reward!';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.45) : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.25), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Reward Unlocked',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: accent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Nice!'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FrostedRewardPreview extends StatelessWidget {
  final String text;
  final Color accent;

  const _FrostedRewardPreview({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.25), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.emoji_emotions_outlined, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    height: 1.35,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}