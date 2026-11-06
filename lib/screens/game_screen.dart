import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/levels.dart';
import '../models/puzzle.dart';
import '../models/quests.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/tile_image.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.progress, required this.spec});
  final Progress progress;
  final GameSpec spec;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameSpec _spec = widget.spec;
  late SlidePuzzle _puzzle = _newPuzzle();
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _showNumbers = true;
  bool _over = false;
  bool _peek = false;
  Timer? _peekTimer;
  (int target, int from)? _hint;

  SlidePuzzle _newPuzzle() => SlidePuzzle(
    _spec.size,
    random: _spec.seed == null ? null : Random(_spec.seed),
  );

  @override
  void dispose() {
    _ticker?.cancel();
    _peekTimer?.cancel();
    super.dispose();
  }

  void _start(GameSpec spec) {
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _spec = spec;
      _puzzle = _newPuzzle();
      _over = false;
      _hint = null;
      _peek = false;
    });
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _useHint() async {
    if (_over || _puzzle.hint() == null) return;
    if (!await widget.progress.spendGems(hintCost)) {
      _toast('Necesitas $hintCost 💎 para una pista');
      return;
    }
    // La pista enseña un instante la imagen completa y marca la ficha a mover.
    _peekTimer?.cancel();
    setState(() {
      _hint = _puzzle.hint();
      _peek = true;
    });
    _peekTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _peek = false);
    });
  }

  Future<void> _undo() async {
    if (_over || !_puzzle.canUndo) return;
    if (!await widget.progress.spendGems(undoCost)) {
      _toast('Necesitas $undoCost 💎 para deshacer');
      return;
    }
    _puzzle.undo();
    setState(() => _hint = null);
  }

  Future<void> _onTap(int index) async {
    if (_over) return;
    if (!_puzzle.tap(index)) return;
    _hint = null;
    HapticFeedback.selectionClick();
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final limit = _spec.timeLimit;
        if (limit != null && _stopwatch.elapsed.inSeconds >= limit && !_over) {
          _finish();
          HapticFeedback.heavyImpact();
          setState(() {});
          _showLoss(timeUp: true);
          return;
        }
        setState(() {});
      });
    }
    setState(() {});

    if (_puzzle.isSolved) {
      _finish();
      final seconds = _stopwatch.elapsed.inSeconds;
      final result = await widget.progress.recordWin(
        _spec,
        _puzzle.moves,
        seconds,
      );
      HapticFeedback.mediumImpact();
      if (mounted) _showWin(seconds, result);
    } else if (_spec.moveLimit != null && _puzzle.moves >= _spec.moveLimit!) {
      _finish();
      _showLoss();
    }
  }

  void _finish() {
    _over = true;
    _stopwatch.stop();
    _ticker?.cancel();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _showLoss({bool timeUp = false}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(timeUp ? 'Se acabó el tiempo ⏱️' : 'Sin movimientos 😵'),
        content: Text(
          timeUp
              ? 'No lo lograste en ${_fmt(_spec.timeLimit!)}. ¡Inténtalo otra vez!'
              : 'Llegaste al tope de ${_spec.moveLimit} movimientos. ¡Inténtalo otra vez!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
            child: const Text('Salir'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _start(_spec);
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showWin(int seconds, WinResult result) {
    final next = _spec.level == null ? null : levelSpec(_spec.level! + 1);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      pageBuilder: (context, _, _) => Stack(
        children: [
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: const Color(0xFF241A4A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: kViolet.withValues(alpha: 0.5),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¡Completado!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedStars(count: result.stars),
                    const SizedBox(height: 14),
                    Text(
                      '${_puzzle.moves} movimientos · ${_fmt(seconds)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+${result.gems} 💎',
                      style: const TextStyle(
                        color: kGold,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final q in result.completedQuests)
                      Text(
                        'Misión: ${q.title} · +${q.reward} 💎',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    if (result.stars < 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Con ${_spec.par} movimientos o menos: 3 estrellas',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${_spec.image.title} — ${_spec.image.credit}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (result.newBadges.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Glass(
                        radius: 16,
                        tint: kGold.withValues(alpha: 0.18),
                        child: Column(
                          children: [
                            const Text(
                              'Nueva insignia',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            for (final b in result.newBadges)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${b.emoji} ${b.name}'),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(this.context);
                            },
                            child: const Text('Inicio'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (next != null) {
                                _start(next);
                              } else {
                                Navigator.pop(this.context);
                              }
                            },
                            child: Text(next != null ? 'Siguiente' : 'Listo'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }

  void _preview() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _spec.image.view(),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _spec.image.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _spec.image.credit,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numbers = _showNumbers && _spec.hasNumbers;
    final limit = _spec.moveLimit;
    final timeLimit = _spec.timeLimit;
    return GradientScaffold(
      appBar: AppBar(
        title: Text('${_spec.title} · ${_spec.label}'),
        actions: [
          IconButton(
            tooltip: 'Ver imagen',
            icon: const Icon(Icons.image_rounded),
            onPressed: _preview,
          ),
          if (_spec.hasNumbers)
            IconButton(
              tooltip: 'Mostrar/ocultar números',
              icon: Icon(_showNumbers ? Icons.pin_rounded : Icons.pin_outlined),
              onPressed: () => setState(() => _showNumbers = !_showNumbers),
            ),
          IconButton(
            tooltip: 'Mezclar de nuevo',
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: () => _start(_spec),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      Icons.touch_app_rounded,
                      limit == null
                          ? '${_puzzle.moves}'
                          : '${_puzzle.moves}/$limit',
                      'movimientos',
                      warn: limit != null && _puzzle.moves >= limit * 0.85,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(
                      Icons.timer_outlined,
                      _fmt(
                        timeLimit == null
                            ? _stopwatch.elapsed.inSeconds
                            : max(0, timeLimit - _stopwatch.elapsed.inSeconds),
                      ),
                      timeLimit == null ? 'tiempo' : 'tiempo restante',
                      warn:
                          timeLimit != null &&
                          timeLimit - _stopwatch.elapsed.inSeconds <= 10,
                    ),
                  ),
                ],
              ),
              if (_spec.modifier != Modifier.none)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    timeLimit != null
                        ? '⏱️ Jefe: resuélvelo en ${_fmt(timeLimit)}'
                        : '⏳ Reto: máximo $limit movimientos',
                    style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: kViolet.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) => Stack(
                          children: [
                            _Board(
                              puzzle: _puzzle,
                              image: _spec.image.provider,
                              boardSide: box.maxWidth,
                              showNumbers: numbers,
                              onTap: _onTap,
                              hint: _hint,
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: _peek ? 1 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _spec.image.view(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: widget.progress,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.lightbulb_rounded,
                          label: 'Pista',
                          cost: hintCost,
                          enabled: !_over && widget.progress.gems >= hintCost,
                          onTap: _useHint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Glass(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        child: Text(
                          '💎 ${widget.progress.gems}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.undo_rounded,
                          label: 'Deshacer',
                          cost: undoCost,
                          enabled:
                              !_over &&
                              _puzzle.canUndo &&
                              widget.progress.gems >= undoCost,
                          onTap: _undo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '${_spec.image.title} · ${_spec.image.credit}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStars extends StatelessWidget {
  const _AnimatedStars({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: i < count ? 1 : 0.35),
          duration: Duration(milliseconds: 450 + i * 280),
          curve: Curves.elasticOut,
          builder: (_, v, _) => Transform.scale(
            scale: v,
            child: Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: i == 1 ? 68 : 54,
              color: i < count ? kGold : Colors.white38,
            ),
          ),
        ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, {this.warn = false});
  final IconData icon;
  final String value;
  final String label;
  final bool warn;

  @override
  Widget build(BuildContext context) => Glass(
    radius: 16,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    tint: warn ? const Color(0x55FF5252) : null,
    child: Row(
      children: [
        Icon(icon, size: 22, color: kGold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final int cost;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.4,
    child: GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: kGold),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label · 💎$cost',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Board extends StatelessWidget {
  const _Board({
    required this.puzzle,
    required this.image,
    required this.boardSide,
    required this.showNumbers,
    required this.onTap,
    this.hint,
  });

  final SlidePuzzle puzzle;
  final ImageProvider image;
  final double boardSide;
  final bool showNumbers;
  final ValueChanged<int> onTap;

  /// (casilla destino, posición actual de la ficha) si hay una pista activa.
  final (int target, int from)? hint;

  @override
  Widget build(BuildContext context) {
    final n = puzzle.size;
    final cell = boardSide / n;
    final radius = (cell * 0.14).clamp(3.0, 12.0);
    final children = <Widget>[];

    final h = hint;
    if (h != null) {
      // Marca la casilla a la que debe ir la ficha señalada.
      children.add(
        Positioned(
          left: (h.$1 % n) * cell,
          top: (h.$1 ~/ n) * cell,
          width: cell,
          height: cell,
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: kGold, width: 2),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (var pos = 0; pos < puzzle.tiles.length; pos++) {
      final tile = puzzle.tiles[pos];
      if (tile == 0) continue;
      final home = tile - 1; // posición correcta en la imagen
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
              padding: const EdgeInsets.all(1.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: pos == h?.$2 ? kGold : Colors.white38,
                    width: pos == h?.$2 ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TileImage(
                        image: image,
                        boardSide: boardSide,
                        n: n,
                        row: home ~/ n,
                        col: home % n,
                      ),
                      if (showNumbers)
                        Positioned(
                          left: 5,
                          top: 2,
                          child: Text(
                            '$tile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: (cell * 0.28).clamp(9.0, 22.0),
                              shadows: const [
                                Shadow(blurRadius: 4, color: Colors.black),
                                Shadow(blurRadius: 8, color: Colors.black),
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
        ),
      );
    }
    return Stack(children: children);
  }
}
