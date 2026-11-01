import 'package:flutter/material.dart';

import '../models/badges.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final owned = progress.badges;
    return GradientScaffold(
      appBar: AppBar(
        title: Text('Insignias ${progress.badgeCount}/${allBadges.length}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Glass(
              gradient: LinearGradient(
                colors: [
                  kOrange.withValues(alpha: 0.35),
                  kPink.withValues(alpha: 0.25),
                ],
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Racha: ${progress.streak} días',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Mejor racha: ${progress.bestStreak} · '
                          'Retos diarios: ${progress.dailyCount}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final b in allBadges)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Glass(
                  radius: 18,
                  tint: owned.contains(b.id)
                      ? kViolet.withValues(alpha: 0.25)
                      : null,
                  child: Row(
                    children: [
                      Opacity(
                        opacity: owned.contains(b.id) ? 1 : 0.25,
                        child: Text(
                          b.emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              b.description,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        owned.contains(b.id)
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        color: owned.contains(b.id) ? kGold : Colors.white30,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
