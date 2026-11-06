import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/levels.dart';

/// Catálogo de imágenes que se descarga solo: un JSON en el repo
/// (`catalog/catalog.json`) lista las imágenes libres de derechos y la app
/// las baja a una carpeta local la primera vez. Sin conexión se siguen usando
/// las que ya estén descargadas y las incluidas en la app.
class CatalogService extends ChangeNotifier {
  CatalogService._();
  static final instance = CatalogService._();

  static const baseUrl =
      'https://raw.githubusercontent.com/alexanderg1978/puzzle-deslizante/main/catalog/';

  /// Los tests la desactivan para no tocar red ni disco.
  static bool enabled = true;

  Directory? _dir;
  final _entries = <_Entry>[];
  var _running = false;

  /// Cuántas imágenes del catálogo están ya en el teléfono.
  int get downloaded => imagePool.length - images.length;

  /// Cuántas imágenes publica el catálogo en total.
  int get total => _entries.length;

  /// Carga lo guardado en disco (rápido, sin red) para tener ya las imágenes.
  Future<void> init() async {
    if (!enabled) return;
    try {
      final base = await getApplicationSupportDirectory();
      _dir = Directory('${base.path}/catalog')..createSync(recursive: true);
      final cached = File('${_dir!.path}/catalog.json');
      if (cached.existsSync()) _parse(cached.readAsStringSync());
      _rebuildPool();
    } catch (e) {
      debugPrint('Catálogo: no se pudo leer la caché ($e)');
    }
  }

  /// Actualiza el catálogo y baja las imágenes que falten, en segundo plano.
  Future<void> sync() async {
    if (!enabled || _dir == null || _running) return;
    _running = true;
    try {
      final body = await _get('${baseUrl}catalog.json');
      final text = utf8.decode(body);
      _parse(text);
      File('${_dir!.path}/catalog.json').writeAsStringSync(text);
      for (final e in _entries) {
        final file = _fileOf(e);
        if (file.existsSync()) continue;
        try {
          final bytes = await _get('$baseUrl${e.file}');
          // Se escribe a un temporal para no dejar imágenes a medias.
          final tmp = File('${file.path}.part')..writeAsBytesSync(bytes);
          tmp.renameSync(file.path);
          _rebuildPool();
        } catch (err) {
          debugPrint('Catálogo: falló ${e.id} ($err)');
        }
      }
    } catch (e) {
      debugPrint('Catálogo: sin conexión ($e)');
    } finally {
      _running = false;
    }
  }

  void _parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    _entries
      ..clear()
      ..addAll(
        (data['images'] as List<dynamic>).map(
          (m) => _Entry.fromJson(m as Map<String, dynamic>),
        ),
      );
  }

  File _fileOf(_Entry e) => File('${_dir!.path}/${e.id}.jpg');

  void _rebuildPool() {
    final remote = [
      for (final e in _entries)
        if (_fileOf(e).existsSync())
          PuzzleImage(
            'remote/${e.id}',
            e.title,
            e.credit,
            filePath: _fileOf(e).path,
          ),
    ];
    imagePool = [...images, ...remote];
    notifyListeners();
  }

  Future<List<int>> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'puzzle-deslizante');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      final out = BytesBuilder();
      await for (final chunk in response) {
        out.add(chunk);
      }
      return out.takeBytes();
    } finally {
      client.close();
    }
  }
}

class _Entry {
  const _Entry(this.id, this.title, this.credit, this.file);
  factory _Entry.fromJson(Map<String, dynamic> m) => _Entry(
    m['id'] as String,
    m['title'] as String,
    m['credit'] as String,
    m['file'] as String,
  );
  final String id;
  final String title;
  final String credit;
  final String file;
}
