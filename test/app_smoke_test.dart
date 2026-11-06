import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/main.dart';
import 'package:puzzle_deslizante/services/progress.dart';
import 'package:puzzle_deslizante/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('invitado entra, ve reto diario y abre un nivel sin errores', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    UpdateService.autoCheck = false;
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = await Progress.load();
    await tester.pumpWidget(PuzzleApp(progress: progress));
    expect(find.text('Jugar sin registrarme'), findsOneWidget);

    await tester.tap(find.text('Jugar sin registrarme'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reto diario'), findsOneWidget);
    expect(find.text('Cofre diario'), findsOneWidget);
    expect(find.text('Misiones de hoy'), findsOneWidget);
    await tester.tap(find.text('Jugar · Nivel 1'));
    await tester.pumpAndSettle();
    expect(find.text('Nivel 1 · 3x3'), findsOneWidget);
    expect(find.text('movimientos'), findsOneWidget);
    expect(find.textContaining('Pista'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
