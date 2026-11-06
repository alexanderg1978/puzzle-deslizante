import 'dart:math';

import 'package:flutter/material.dart';

import '../models/levels.dart';
import '../services/auth.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'badges_screen.dart';
import 'extras.dart';
import 'game_screen.dart';
import 'update_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.progress});
  final Progress progress;

  void _play(BuildContext context, GameSpec spec) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GameScreen(progress: progress, spec: spec),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final name = progress.playerName ?? 'Invitado';
        final today = DateTime.now();
        final daily = dailySpec(today);
        // Muestra los desbloqueados y dos más bloqueados como anticipo.
        final count = progress.unlockedLevel + 2;
        return GradientScaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: kViolet,
                          child: Text(
                            name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bienvenido',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                name.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const UpdateButton(),
                        IconButton(
                          tooltip: 'Insignias',
                          icon: const Icon(Icons.military_tech_rounded),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BadgesScreen(progress: progress),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar sesión',
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () async {
                            await AuthService.signOut();
                            await progress.endSession();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _Stats(progress: progress)),
                SliverToBoxAdapter(
                  child: _DailyCard(
                    spec: daily,
                    stars: progress.starsOf(daily),
                    onTap: () => _play(context, daily),
                  ),
                ),
                SliverToBoxAdapter(child: HomeExtras(progress: progress)),
                for (var w = 0; w * levelsPerWorld < count; w++) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Text(
                        'Mundo ${w + 1} · ${worldName(w)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: min(levelsPerWorld, count - w * levelsPerWorld),
                      itemBuilder: (context, i) {
                        final spec = levelSpec(w * levelsPerWorld + i + 1);
                        final unlocked = spec.level! <= progress.unlockedLevel;
                        return _LevelTile(
                          spec: spec,
                          unlocked: unlocked,
                          stars: progress.levelStars(spec.level!),
                          onTap: unlocked ? () => _play(context, spec) : null,
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final streak = progress.streak;
    final active = progress.playedToday;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _Chip(
            emoji: '🔥',
            value: '$streak',
            label: streak == 1 ? 'día de racha' : 'días de racha',
            highlight: active,
          ),
          const SizedBox(width: 10),
          _Chip(
            emoji: '⭐',
            value: '${progress.totalStars}',
            label: 'estrellas',
          ),
          const SizedBox(width: 10),
          _Chip(
            emoji: '🧩',
            value: '${progress.totalSolved}',
            label: 'resueltos',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.emoji,
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final String emoji;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Glass(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      radius: 18,
      tint: highlight ? kOrange.withValues(alpha: 0.22) : null,
      child: Column(
        children: [
          Text(
            '$emoji $value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.spec,
    required this.stars,
    required this.onTap,
  });
  final GameSpec spec;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = stars > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [kPink, kViolet]),
            boxShadow: [
              BoxShadow(
                color: kPink.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        '☀️ Reto diario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${spec.label} · ${spec.tileCount} fichas',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      done
                          ? StarRow(count: stars, size: 20)
                          : const Text(
                              '¡Aún no lo has jugado hoy!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                  child: SizedBox(
                    width: 104,
                    child: Image.asset(
                      spec.image.asset,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _gray = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.spec,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });
  final GameSpec spec;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (spec.modifier) {
      Modifier.limited => '⏳',
      Modifier.timed => '⏱️',
      Modifier.none => '',
    };
    Widget photo = Image.asset(
      spec.image.asset,
      fit: BoxFit.cover,
      cacheWidth: 300,
    );
    if (!unlocked) photo = ColorFiltered(colorFilter: _gray, child: photo);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: stars == 3
                ? kGold
                : Colors.white.withValues(alpha: unlocked ? 0.25 : 0.1),
            width: stars == 3 ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              photo,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: unlocked ? 0.05 : 0.6),
                      Colors.black.withValues(alpha: unlocked ? 0.8 : 0.75),
                    ],
                  ),
                ),
              ),
              if (!unlocked)
                const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white54,
                    size: 30,
                  ),
                ),
              Positioned(
                top: 6,
                left: 8,
                child: Text(
                  '${spec.level}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
              ),
              if (icon.isNotEmpty)
                Positioned(top: 8, right: 8, child: Text(icon)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      spec.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (unlocked) StarRow(count: stars, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
