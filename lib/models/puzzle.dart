import 'dart:math';

/// Estado de un puzzle deslizante de [size] x [size].
/// `tiles[i]` es el número de ficha en la posición i; 0 es el hueco.
class SlidePuzzle {
  SlidePuzzle(this.size, {Random? random})
      : _random = random ?? Random(),
        tiles = List.generate(size * size, (i) => (i + 1) % (size * size)) {
    shuffle();
  }

  final int size;
  final Random _random;
  final List<int> tiles;
  int moves = 0;

  int get emptyIndex => tiles.indexOf(0);

  bool get isSolved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  /// Mezcla con movimientos legales desde el estado resuelto, así siempre
  /// tiene solución.
  void shuffle() {
    var empty = tiles.length - 1;
    var previous = -1;
    final steps = size * size * 30;
    for (var s = 0; s < steps; s++) {
      final options = _neighbours(empty).where((n) => n != previous).toList();
      final next = options[_random.nextInt(options.length)];
      tiles[empty] = tiles[next];
      tiles[next] = 0;
      previous = empty;
      empty = next;
    }
    if (isSolved) {
      shuffle();
      return;
    }
    moves = 0;
  }

  List<int> _neighbours(int index) {
    final r = index ~/ size;
    final c = index % size;
    return [
      if (r > 0) index - size,
      if (r < size - 1) index + size,
      if (c > 0) index - 1,
      if (c < size - 1) index + 1,
    ];
  }

  /// Mueve la ficha en [index] (y las de su fila/columna que estorben)
  /// hacia el hueco. Devuelve true si hubo movimiento.
  bool tap(int index) {
    final empty = emptyIndex;
    final r = index ~/ size, c = index % size;
    final er = empty ~/ size, ec = empty % size;
    if (index == empty || (r != er && c != ec)) return false;

    final step = r == er ? (c < ec ? 1 : -1) : (r < er ? size : -size);
    var cursor = empty;
    while (cursor != index) {
      tiles[cursor] = tiles[cursor - step];
      cursor -= step;
    }
    tiles[index] = 0;
    moves++;
    return true;
  }
}
