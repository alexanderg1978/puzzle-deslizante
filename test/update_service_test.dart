import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/services/update_service.dart';

void main() {
  Map<String, dynamic> release(String tag) => {'tag_name': tag};

  test('ignora los APK de prueba aunque sean lo más nuevo', () {
    final found = UpdateService.latestPreview([
      release('prueba-21'),
      release('v1.0.20'),
      release('v1.0.19'),
    ]);
    expect(found?['tag_name'], 'v1.0.20');
  });

  test('sin previews no hay actualización', () {
    expect(UpdateService.latestPreview([release('prueba-21')]), isNull);
    expect(UpdateService.latestPreview([]), isNull);
  });
}
