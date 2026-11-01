import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Lluvia de confeti sin dependencias externas.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Piece {
  _Piece(Random r)
    : x = r.nextDouble(),
      speed = 0.7 + r.nextDouble() * 0.9,
      sway = 0.02 + r.nextDouble() * 0.05,
      phase = r.nextDouble() * pi * 2,
      spin = (r.nextDouble() - 0.5) * 14,
      w = 6 + r.nextDouble() * 6,
      h = 10 + r.nextDouble() * 8,
      delay = r.nextDouble() * 0.35,
      color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    kGold,
    kPink,
    kViolet,
    Color(0xFF4DD0E1),
    Color(0xFF69F0AE),
    kOrange,
  ];

  final double x, speed, sway, phase, spin, w, h, delay;
  final Color color;
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..forward();
  final _pieces = () {
    final r = Random();
    return List.generate(70, (_) => _Piece(r));
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_pieces, _c.value),
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0 || local == 1) continue;
      final dx = (p.x + sin(local * 7 + p.phase) * p.sway) * size.width;
      final dy = (-0.05 + local * p.speed * 1.2) * size.height;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(local * p.spin);
      final paint = Paint()..color = p.color.withValues(alpha: 1 - local * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
