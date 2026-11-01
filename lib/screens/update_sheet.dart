import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/update_service.dart';
import '../theme.dart';

/// Botón de la barra superior: comprueba en segundo plano si hay una
/// versión nueva (punto rojo) y abre el panel de actualizaciones.
class UpdateButton extends StatefulWidget {
  const UpdateButton({super.key});

  @override
  State<UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<UpdateButton> {
  UpdateInfo? _available;

  @override
  void initState() {
    super.initState();
    if (!UpdateService.autoCheck) return;
    UpdateService.check()
        .then((u) {
          if (mounted) setState(() => _available = u);
        })
        .catchError((_) {
          // Sin conexión: se avisa solo si el usuario abre el panel.
        });
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Actualizaciones',
    icon: Badge(
      isLabelVisible: _available != null,
      child: const Icon(Icons.system_update_rounded),
    ),
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241A4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _UpdateSheet(initial: _available),
    ),
  );
}

enum _Phase { checking, upToDate, available, downloading, installing, error }

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({this.initial});
  final UpdateInfo? initial;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  _Phase _phase = _Phase.checking;
  AppVersion? _current;
  UpdateInfo? _update;
  int _progress = 0;
  String _error = '';
  StreamSubscription<OtaEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _update = widget.initial;
    _check();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _phase = _Phase.checking);
    try {
      _current = await UpdateService.currentVersion();
      _update = await UpdateService.check();
      if (!mounted) return;
      setState(
        () => _phase = _update == null ? _Phase.upToDate : _Phase.available,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = 'No se pudo buscar actualizaciones. Revisa tu conexión.';
      });
    }
  }

  void _install() {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
    });
    _sub = UpdateService.install(_update!).listen(
      (event) {
        if (!mounted) return;
        setState(() {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              _phase = _Phase.downloading;
              _progress = int.tryParse(event.value ?? '') ?? _progress;
            case OtaStatus.INSTALLING:
            case OtaStatus.INSTALLATION_DONE:
              _phase = _Phase.installing;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _phase = _Phase.error;
              _error =
                  'Permite instalar apps de esta fuente y vuelve a intentarlo.';
            default:
              _phase = _Phase.error;
              _error =
                  'Falló la descarga o instalación (${event.status.name}).';
          }
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.error;
          _error = 'Falló la descarga. Revisa tu conexión.';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Actualizaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (_current != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Versión instalada: ${_current!} (build ${_current!.build})',
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 20),
            ..._body(),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() => switch (_phase) {
    _Phase.checking => const [
      CircularProgressIndicator(),
      SizedBox(height: 12),
      Text('Buscando…'),
    ],
    _Phase.upToDate => [
      const Text('✅', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      const Text('Ya tienes la última versión'),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _check, child: const Text('Buscar de nuevo')),
    ],
    _Phase.available => [
      const Text('🚀', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text(
        'Nueva versión ${_update!.name}',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      if (_update!.notes.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          _update!.notes,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _install,
        icon: const Icon(Icons.download_rounded),
        label: const Text('Descargar e instalar'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      ),
    ],
    _Phase.downloading => [
      LinearProgressIndicator(
        value: _progress == 0 ? null : _progress / 100,
        minHeight: 10,
        borderRadius: BorderRadius.circular(8),
        color: kGold,
      ),
      const SizedBox(height: 12),
      Text('Descargando… $_progress%'),
    ],
    _Phase.installing => const [
      Text('📦', style: TextStyle(fontSize: 40)),
      SizedBox(height: 8),
      Text('Abriendo el instalador de Android…'),
    ],
    _Phase.error => [
      const Text('⚠️', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text(_error, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _check, child: const Text('Reintentar')),
    ],
  };
}
