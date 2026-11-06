import 'dart:math';

import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/models/levels.dart';
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

  test('los niveles crecen hasta 8x8 y alternan retos', () {
    expect(levelSpec(1).size, 3);
    expect(levelSpec(3).size, 3);
    expect(levelSpec(4).size, 4);
    expect(levelSpec(13).size, 7);
    expect(levelSpec(500).size, 8);
    expect(levelSpec(5).modifier, Modifier.limited);
    expect(levelSpec(7).modifier, Modifier.none);
    expect(levelSpec(10).modifier, Modifier.timed);
    expect(levelSpec(10).timeLimit, greaterThan(0));
    expect(levelSpec(5).timeLimit, isNull);
    expect(worldIndexOf(10), 0);
    expect(worldIndexOf(11), 1);
    expect(worldName(9), contains('2'));
    expect(levelSpec(1).hasNumbers, isTrue);
    expect(levelSpec(2).hasNumbers, isFalse);
    expect(levelSpec(1).moveLimit, isNull);
    expect(levelSpec(5).moveLimit, greaterThan(levelSpec(5).par));
  });

  test('las estrellas dependen de los movimientos', () {
    final s = levelSpec(1);
    expect(s.starsFor(s.par), 3);
    expect(s.starsFor(s.par + 1), 2);
    expect(s.starsFor((s.par * 1.7).floor()), 2);
    expect(s.starsFor(s.par * 3), 1);
  });

  test('el reto diario es igual para la misma fecha', () {
    final a = dailySpec(DateTime(2026, 11, 2));
    final b = dailySpec(DateTime(2026, 11, 2, 23, 59));
    expect(a.dayKey, '20261102');
    expect(a.size, b.size);
    expect(a.image.asset, b.image.asset);
    final p1 = SlidePuzzle(a.size, random: Random(a.seed));
    final p2 = SlidePuzzle(b.size, random: Random(b.seed));
    expect(p1.tiles, p2.tiles);
  });

  test('detecta puzzle resuelto', () {
    final p = SlidePuzzle(3);
    p.tiles.setAll(0, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    p.tap(8);
    expect(p.isSolved, isTrue);
  });

  test('las imágenes del catálogo descargadas entran en los niveles', () {
    final remote = PuzzleImage('remote/x', 'T', 'C', filePath: '/tmp/x.jpg');
    expect(remote.provider, isA<FileImage>());
    expect(images.first.provider, isA<AssetImage>());
    imagePool = [...images, remote];
    addTearDown(() => imagePool = images);
    expect(levelSpec(images.length + 1).image.asset, 'remote/x');
    expect(levelSpec(1).image.asset, images.first.asset);
  });
}
