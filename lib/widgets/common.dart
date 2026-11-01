import 'package:flutter/material.dart';

import '../theme.dart';

/// Fondo degradado con halos de color difuminados.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1038), Color(0xFF2B1A66), Color(0xFF0E2650)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Glow(color: kPink.withValues(alpha: 0.28), size: 260),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Glow(color: kViolet.withValues(alpha: 0.35), size: 320),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// Scaffold con el fondo degradado de la app.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({super.key, this.appBar, required this.body});
  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) => AppBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: body,
    ),
  );
}

/// Tarjeta translúcida tipo cristal.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.tint,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null
          ? (tint ?? Colors.white.withValues(alpha: 0.08))
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: child,
  );
}

/// Fila de 3 estrellas, [count] llenas.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.count, this.size = 16});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Icon(
          i < count ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < count ? kGold : Colors.white30,
        ),
    ],
  );
}
