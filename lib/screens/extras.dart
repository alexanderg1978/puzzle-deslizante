import 'package:flutter/material.dart';

import '../models/levels.dart';
import '../models/quests.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Cofre diario, tienda y galería, más las misiones del día.
class HomeExtras extends StatelessWidget {
  const HomeExtras({super.key, required this.progress});
  final Progress progress;

  Future<void> _openChest(BuildContext context) async {
    final reward = await progress.openChest();
    if (reward == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const Text('🎁', style: TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 8),
            Text(
              '+$reward 💎',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: kGold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vuelve mañana por otro.\nMás racha, más gemas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Genial!'),
          ),
        ],
      ),
    );
  }

  void _openShop(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF241A4A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ShopSheet(progress: progress),
  );

  @override
  Widget build(BuildContext context) {
    final ready = progress.chestReady;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  emoji: '🎁',
                  title: 'Cofre diario',
                  subtitle: ready ? '¡Ábrelo!' : 'Mañana otro',
                  highlight: ready,
                  onTap: ready ? () => _openChest(context) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickCard(
                  emoji: '💎',
                  title: '${progress.gems}',
                  subtitle: '🧊 ${progress.freezes}/$maxFreezes · tienda',
                  onTap: () => _openShop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickCard(
                  emoji: '🖼️',
                  title: 'Galería',
                  subtitle: '${progress.gallery.length}/${images.length} obras',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GalleryScreen(progress: progress),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuestsCard(progress: progress),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      tint: highlight ? kGold.withValues(alpha: 0.28) : null,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 10.5),
          ),
        ],
      ),
    ),
  );
}

class _QuestsCard extends StatelessWidget {
  const _QuestsCard({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) => Glass(
    radius: 20,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Misiones de hoy',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        for (final q in dailyQuests)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  progress.questDone(q)
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: progress.questDone(q) ? kGold : Colors.white38,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          decoration: progress.questDone(q)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (progress.questProgress(q) / q.target).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                        color: kGold,
                        backgroundColor: Colors.white12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '+${q.reward} 💎',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ShopSheet extends StatelessWidget {
  const _ShopSheet({required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: progress,
    builder: (context, _) {
      final full = progress.freezes >= maxFreezes;
      final canBuy = !full && progress.gems >= freezeCost;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tienda',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Tienes 💎 ${progress.gems}',
                style: const TextStyle(color: kGold),
              ),
              const SizedBox(height: 18),
              Glass(
                child: Row(
                  children: [
                    const Text('🧊', style: TextStyle(fontSize: 38)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Congelador de racha (${progress.freezes}/$maxFreezes)',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'Si faltas un día, protege tu racha automáticamente.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: canBuy ? progress.buyFreeze : null,
                      child: Text(full ? 'Lleno' : '💎$freezeCost'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gana gemas resolviendo puzzles, con misiones y con el cofre diario. '
                'Úsalas en pistas (5) y para deshacer (2).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.progress});
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.gallery;
    return GradientScaffold(
      appBar: AppBar(
        title: Text('Galería ${unlocked.length}/${imagePool.length}'),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemCount: imagePool.length,
          itemBuilder: (context, i) {
            final image = imagePool[i];
            final has = unlocked.contains(image.asset);
            return GestureDetector(
              onTap: has ? () => _show(context, image) : null,
              child: Glass(
                radius: 20,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: has
                            ? image.view(
                                width: double.infinity,
                                cacheWidth: 400,
                              )
                            : const ColoredBox(
                                color: Colors.black38,
                                child: Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: Colors.white38,
                                    size: 34,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      has ? image.title : 'Sin descubrir',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      has ? image.credit : 'Completa un nivel con ella',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _show(BuildContext context, PuzzleImage image) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: image.view(fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              image.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(image.credit, style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    ),
  );
}
