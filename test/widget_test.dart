import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/models/puzzle.dart';

bool _solvable(List<int> tiles, int size) {
  final flat = tiles.where((t) => t != 0).toList();
  var inversions = 0;
  for (var i = 0; i < flat.length; i++) {
    for (var j = i + 1; j < flat.length; j++) {
      if (flat[i] > flat[j]) inversions++;
    }
  }
  if (size.isOdd) return inversions.isEven;
  final rowFromBottom = size - tiles.indexOf(0) ~/ size;
  return (inversions + rowFromBottom).isOdd;
}

void main() {
  test('el mezclado siempre es resoluble y no está resuelto', () {
    for (final size in [3, 4, 5, 6]) {
      for (var i = 0; i < 20; i++) {
        final p = SlidePuzzle(size, random: Random(i));
        expect(p.isSolved, isFalse);
        expect(_solvable(p.tiles, size), isTrue);
        expect(p.moves, 0);
      }
    }
  });

  test('tap mueve una fila de fichas hacia el hueco', () {
    final p = SlidePuzzle(3);
    p.tiles.setAll(0, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    expect(p.tap(6), isTrue); // desliza el 7 hacia el hueco
    expect(p.tiles, [1, 2, 3, 4, 5, 6, 0, 7, 8]);
    expect(p.moves, 1);
    expect(p.tap(1), isFalse); // no comparte fila/columna con el hueco
  });

  test('detecta puzzle resuelto', () {
    final p = SlidePuzzle(3);
    p.tiles.setAll(0, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    p.tap(8);
    expect(p.isSolved, isTrue);
  });
}
