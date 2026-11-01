import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/main.dart';
import 'package:puzzle_deslizante/services/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('invitado entra, ve reto diario y abre un nivel sin errores', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = await Progress.load();
    await tester.pumpWidget(PuzzleApp(progress: progress));
    expect(find.text('Jugar sin registrarme'), findsOneWidget);

    await tester.tap(find.text('Jugar sin registrarme'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reto diario'), findsOneWidget);
    expect(find.text('Niveles'), findsOneWidget);

    await tester.tap(find.text('3x3').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Nivel 1'), findsOneWidget);
    expect(find.text('movimientos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
