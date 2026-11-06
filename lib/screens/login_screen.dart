import 'package:flutter/material.dart';

import '../models/levels.dart';
import '../services/auth.dart';
import '../services/progress.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tile_image.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.progress});
  final Progress progress;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await AuthService.signIn();
      await widget.progress.startSession(
        id: user.id,
        name: user.name,
        email: user.email,
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo iniciar sesión con Google. Puedes jugar como invitado.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Logo(),
                  const SizedBox(height: 28),
                  ShaderMask(
                    shaderCallback: (r) =>
                        const LinearGradient(colors: [Colors.white, kGold])
                            .createShader(r),
                    child: const Text(
                      'Puzzle\nDeslizante',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ordena obras de arte famosas.\n'
                    'Gana estrellas, rachas e insignias.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 36),
                  FilledButton.icon(
                    onPressed: _busy ? null : _google,
                    icon: const CircleAvatar(
                      radius: 11,
                      backgroundColor: kViolet,
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: const Text('Continuar con Google'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF241A4A),
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => widget.progress.startSession(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('Jugar sin registrarme'),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFF8A80)),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Tu progreso se guarda solo en este teléfono.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini puzzle 3x3 flotante con un hueco, como logo.
class _Logo extends StatefulWidget {
  const _Logo();

  @override
  State<_Logo> createState() => _LogoState();
}

class _LogoState extends State<_Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const side = 168.0;
    const n = 3;
    const cell = side / n;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Container(
        width: side + 12,
        height: side + 12,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: kViolet.withValues(alpha: 0.5),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            for (var i = 0; i < 8; i++)
              Positioned(
                left: (i % n) * cell,
                top: (i ~/ n) * cell,
                width: cell,
                height: cell,
                child: Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TileImage(
                      image: images[0].provider,
                      boardSide: side,
                      n: n,
                      row: i ~/ n,
                      col: i % n,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
