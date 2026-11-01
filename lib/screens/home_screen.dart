import 'package:flutter/material.dart';

import '../models/badges.dart';
import '../models/levels.dart';
import '../services/auth.dart';
import '../services/progress.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final name = progress.playerName ?? 'Invitado';
        return Scaffold(
          appBar: AppBar(
            title: Text('Hola, ${name.split(' ').first}'),
            actions: [
              IconButton(
                tooltip: 'Insignias',
                icon: const Icon(Icons.military_tech),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BadgesScreen(progress: progress)),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await AuthService.signOut();
                  await progress.endSession();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _StreakBanner(progress: progress),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, i) {
                    final level = levels[i];
                    final unlocked = level.number <= progress.unlockedLevel;
                    final done = progress.isCompleted(level.number);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: unlocked
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                      progress: progress, level: level),
                                ),
                              )
                          : null,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: unlocked
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              unlocked
                                  ? (done ? Icons.check_circle : Icons.play_circle)
                                  : Icons.lock,
                              color: unlocked
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            Text('Nivel ${level.number}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('${level.label} · ${level.tileCount} fichas',
                                style: Theme.of(context).textTheme.bodySmall),
                            if (done)
                              Text('Mejor: ${progress.bestMoves(level.number)} mov.',
                                  style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final streak = progress.streak;
    final text = streak == 0
        ? 'Resuelve un puzzle hoy para iniciar tu racha'
        : progress.playedToday
            ? '¡Racha de $streak ${streak == 1 ? 'día' : 'días'}!'
            : 'Racha de $streak ${streak == 1 ? 'día' : 'días'}: juega hoy para mantenerla';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final owned = progress.badges;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text('Insignias (${owned.length}/${allBadges.length})')),
      body: ListView(
        children: [
          ListTile(
            leading: const Text('🔥', style: TextStyle(fontSize: 28)),
            title: Text('Racha actual: ${progress.streak}'),
            subtitle: Text('Mejor racha: ${progress.bestStreak} · '
                'Puzzles resueltos: ${progress.totalSolved}'),
          ),
          const Divider(),
          for (final b in allBadges)
            ListTile(
              leading: Opacity(
                opacity: owned.contains(b.id) ? 1 : 0.25,
                child: Text(b.emoji, style: const TextStyle(fontSize: 32)),
              ),
              title: Text(b.name),
              subtitle: Text(b.description),
              trailing: owned.contains(b.id)
                  ? Icon(Icons.check_circle, color: scheme.primary)
                  : const Icon(Icons.lock_outline),
            ),
        ],
      ),
    );
  }
}
