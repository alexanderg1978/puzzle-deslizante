import 'dart:convert';
import 'dart:io';

import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  const UpdateInfo(this.build, this.name, this.url, this.notes);
  final int build;
  final String name;
  final String url;
  final String notes;
}

class AppVersion {
  const AppVersion(this.name, this.build);
  final String name;
  final int build;
  @override
  String toString() => 'v$name';
}

/// Actualizaciones OTA: la CI publica cada push a main como pre-release de
/// GitHub (tag v1.0.N, N = número de build) y la app lo descarga e instala.
class UpdateService {
  static const repo = 'alexanderg1978/puzzle-deslizante';

  /// Comprobación automática al abrir la app (los tests la desactivan).
  static bool autoCheck = true;

  static Future<AppVersion> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersion(info.version, int.tryParse(info.buildNumber) ?? 0);
  }

  /// Devuelve la actualización disponible o null si ya tienes la última.
  /// Lanza una excepción si no hay conexión o GitHub no responde.
  static Future<UpdateInfo?> check() async {
    final current = await currentVersion();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$repo/releases?per_page=1'),
      );
      request.headers
        ..set('Accept', 'application/vnd.github+json')
        ..set('User-Agent', 'puzzle-deslizante');
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) {
        throw HttpException('GitHub respondió ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final releases = jsonDecode(body) as List<dynamic>;
      if (releases.isEmpty) return null;

      final release = releases.first as Map<String, dynamic>;
      final tag = release['tag_name'] as String;
      final build = int.tryParse(tag.split('.').last) ?? 0;
      if (build <= current.build) return null;

      final assets = (release['assets'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((a) => (a['name'] as String).endsWith('.apk'));
      if (assets.isEmpty) return null;

      return UpdateInfo(
        build,
        tag,
        assets.first['browser_download_url'] as String,
        (release['body'] as String?)?.trim() ?? '',
      );
    } finally {
      client.close();
    }
  }

  /// Descarga el APK y abre el instalador de Android.
  static Stream<OtaEvent> install(UpdateInfo update) => OtaUpdate().execute(
    update.url,
    destinationFilename: 'puzzle-deslizante.apk',
  );
}
