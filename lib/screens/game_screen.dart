import 'dart:async';

import 'package:flutter/material.dart';

import '../models/badges.dart';
import '../models/levels.dart';
import '../models/puzzle.dart';
import '../services/progress.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.progress, required this.level});
  final Progress progress;
  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Level _level = widget.level;
  late SlidePuzzle _puzzle = SlidePuzzle(_level.size);
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _showNumbers = true;
  bool _won = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _restart(Level level) {
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _level = level;
      _puzzle = SlidePuzzle(level.size);
      _won = false;
    });
  }

  Future<void> _onTap(int index) async {
    if (_won) return;
    if (!_puzzle.tap(index)) return;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _ticker = Timer.periodic(
          const Duration(seconds: 1), (_) => setState(() {}));
    }
    setState(() {});
    if (_puzzle.isSolved) {
      _won = true;
      _stopwatch.stop();
      _ticker?.cancel();
      final seconds = _stopwatch.elapsed.inSeconds;
      final fresh =
          await widget.progress.recordWin(_level, _puzzle.moves, seconds);
      if (mounted) _showWin(seconds, fresh);
    }
  }

  void _showWin(int seconds, List<GameBadge> fresh) {
    final hasNext = _level.number < levelCount;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Completado! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_puzzle.moves} movimientos en ${_fmt(seconds)}'),
            const SizedBox(height: 4),
            Text('${_level.image.title} — ${_level.image.credit}',
                style: Theme.of(context).textTheme.bodySmall),
            if (fresh.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Nuevas insignias:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final b in fresh) Text('${b.emoji} ${b.name}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
            child: const Text('Niveles'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _restart(hasNext ? levels[_level.number] : _level);
            },
            child: Text(hasNext ? 'Siguiente nivel' : 'Repetir'),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _preview() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(_level.image.asset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(_level.image.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_level.image.credit),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nivel ${_level.number} · ${_level.label}'),
        actions: [
          IconButton(
            tooltip: 'Ver imagen',
            icon: const Icon(Icons.image_outlined),
            onPressed: _preview,
          ),
          IconButton(
            tooltip: 'Mostrar/ocultar números',
            icon: Icon(_showNumbers ? Icons.pin : Icons.pin_outlined),
            onPressed: () => setState(() => _showNumbers = !_showNumbers),
          ),
          IconButton(
            tooltip: 'Mezclar de nuevo',
            icon: const Icon(Icons.shuffle),
            onPressed: () => _restart(_level),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(Icons.touch_app, '${_puzzle.moves}', 'movimientos'),
                  _Stat(Icons.timer_outlined,
                      _fmt(_stopwatch.elapsed.inSeconds), 'tiempo'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: LayoutBuilder(
                        builder: (context, box) => _Board(
                          puzzle: _puzzle,
                          asset: _level.image.asset,
                          boardSide: box.maxWidth,
                          showNumbers: _showNumbers,
                          onTap: _onTap,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text('${_level.image.title} · ${_level.image.credit}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ]),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _Board extends StatelessWidget {
  const _Board({
    required this.puzzle,
    required this.asset,
    required this.boardSide,
    required this.showNumbers,
    required this.onTap,
  });

  final SlidePuzzle puzzle;
  final String asset;
  final double boardSide;
  final bool showNumbers;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = puzzle.size;
    const gap = 2.0;
    final cell = boardSide / n;
    final children = <Widget>[];

    for (var pos = 0; pos < puzzle.tiles.length; pos++) {
      final tile = puzzle.tiles[pos];
      if (tile == 0) continue;
      // Posición correcta de esta ficha en la imagen.
      final home = tile - 1;
      final hr = home ~/ n, hc = home % n;
      final align = Alignment(
        n == 1 ? 0 : -1 + 2 * hc / (n - 1),
        n == 1 ? 0 : -1 + 2 * hr / (n - 1),
      );
      children.add(
        AnimatedPositioned(
          key: ValueKey(tile),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          left: (pos % n) * cell,
          top: (pos ~/ n) * cell,
          width: cell,
          height: cell,
          child: GestureDetector(
            onTap: () => onTap(pos),
            child: Padding(
              padding: const EdgeInsets.all(gap / 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OverflowBox(
                      maxWidth: boardSide,
                      maxHeight: boardSide,
                      alignment: align,
                      child: SizedBox(
                        width: boardSide,
                        height: boardSide,
                        child: Image.asset(asset, fit: BoxFit.cover),
                      ),
                    ),
                    if (showNumbers)
                      Positioned(
                        left: 4,
                        top: 2,
                        child: Text(
                          '$tile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: cell * 0.28,
                            shadows: const [
                              Shadow(blurRadius: 4, color: Colors.black)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: children);
  }
}
