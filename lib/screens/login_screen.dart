import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../services/progress.dart';

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
      await widget.progress
          .startSession(id: user.id, name: user.name, email: user.email);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'No se pudo iniciar sesión con Google. Puedes jugar como invitado.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 88, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text('Puzzle Deslizante',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Ordena las fichas de obras de arte famosas.\n'
                    'Gana rachas, insignias y sube de nivel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _busy ? null : _google,
                    icon: const Icon(Icons.login),
                    label: const Text('Continuar con Google'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => widget.progress.startSession(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('Jugar sin registrarme'),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Tu progreso se guarda solo en este teléfono.',
                    style: Theme.of(context).textTheme.bodySmall,
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
