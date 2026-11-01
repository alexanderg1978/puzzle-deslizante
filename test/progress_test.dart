import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/models/levels.dart';
import 'package:puzzle_deslizante/models/puzzle.dart';
import 'package:puzzle_deslizante/models/quests.dart';
import 'package:puzzle_deslizante/services/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('deshacer restaura el tablero y la pista señala la ficha correcta', () {
    final p = SlidePuzzle(3);
    p.tiles.setAll(0, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    expect(p.hint(), (7, 8)); // casilla 7 espera la ficha 8, que está en 8
    expect(p.canUndo, isFalse);
    p.tap(8);
    expect(p.isSolved, isTrue);
    expect(p.hint(), isNull);
    expect(p.undo(), isTrue);
    expect(p.tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    expect(p.undo(), isFalse);
  });

  test('ganar da gemas, avanza misiones y desbloquea la galería', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = await Progress.load();
    expect(progress.gems, startingGems);

    final spec = levelSpec(1);
    final result = await progress.recordWin(spec, spec.par, 40);
    expect(result.stars, 3);
    expect(result.gems, 5 + 3 * 3);
    expect(progress.gems, startingGems + result.gems);
    expect(progress.gallery, contains(spec.image.asset));
    expect(progress.questProgress(dailyQuests[0]), 1);
    expect(progress.questProgress(dailyQuests[1]), 3);

    // Repetir el mismo nivel sin mejorar solo da 1 gema.
    final again = await progress.recordWin(spec, spec.par, 40);
    expect(again.gems, 1);
  });

  test('misión de estrellas paga una sola vez al completarse', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = await Progress.load();
    final spec = levelSpec(1);
    await progress.recordWin(spec, spec.par, 40); // 3 estrellas
    final second = await progress.recordWin(spec, spec.par, 40); // 6 -> misión
    expect(second.completedQuests.map((q) => q.id), ['stars']);
    final third = await progress.recordWin(spec, spec.par, 40);
    expect(third.completedQuests.map((q) => q.id), ['solve']);
    final fourth = await progress.recordWin(spec, spec.par, 40);
    expect(fourth.completedQuests, isEmpty);
  });

  test(
    'cofre diario se abre una vez al día y la tienda limita congeladores',
    () async {
      SharedPreferences.setMockInitialValues({});
      final progress = await Progress.load();
      expect(progress.chestReady, isTrue);
      final reward = await progress.openChest();
      expect(reward, inInclusiveRange(10, 30));
      expect(progress.chestReady, isFalse);
      expect(await progress.openChest(), isNull);

      await progress.addGems(200);
      expect(await progress.buyFreeze(), isTrue);
      expect(await progress.buyFreeze(), isTrue);
      expect(await progress.buyFreeze(), isFalse); // máximo 2
      expect(progress.freezes, maxFreezes);
    },
  );
}
