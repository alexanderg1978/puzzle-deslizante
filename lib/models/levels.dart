import 'dart:math';

class PuzzleImage {
  const PuzzleImage(this.asset, this.title, this.credit);
  final String asset;
  final String title;
  final String credit;
}

/// Obras de dominio público (Wikimedia Commons / NASA).
const images = <PuzzleImage>[
  PuzzleImage(
    'assets/images/noche_estrellada.jpg',
    'La noche estrellada',
    'Vincent van Gogh, 1889',
  ),
  PuzzleImage(
    'assets/images/gran_ola.jpg',
    'La gran ola de Kanagawa',
    'Katsushika Hokusai, c. 1831',
  ),
  PuzzleImage(
    'assets/images/perla.jpg',
    'La joven de la perla',
    'Johannes Vermeer, c. 1665',
  ),
  PuzzleImage('assets/images/tierra.jpg', 'La canica azul', 'NASA, 1972'),
  PuzzleImage(
    'assets/images/venus.jpg',
    'El nacimiento de Venus',
    'Sandro Botticelli, c. 1485',
  ),
  PuzzleImage(
    'assets/images/girasoles.jpg',
    'Los girasoles',
    'Vincent van Gogh, 1889',
  ),
  PuzzleImage(
    'assets/images/mona_lisa.jpg',
    'La Gioconda',
    'Leonardo da Vinci, c. 1503',
  ),
];

enum Modifier {
  none,

  /// Tope de movimientos: si te pasas, pierdes el intento.
  limited,

  /// Sin números en las fichas: solo la imagen.
  blind,
}

/// Todo lo necesario para jugar una partida: un nivel o el reto diario.
class GameSpec {
  const GameSpec({
    required this.title,
    required this.size,
    required this.image,
    this.modifier = Modifier.none,
    this.level,
    this.seed,
    this.dayKey,
  });

  final String title;
  final int size;
  final PuzzleImage image;
  final Modifier modifier;
  final int? level;

  /// Semilla del mezclado (solo el reto diario, igual para todos ese día).
  final int? seed;

  /// yyyymmdd si es el reto diario.
  final String? dayKey;

  bool get isDaily => dayKey != null;
  int get tileCount => size * size - 1;
  String get label => '${size}x$size';

  /// Movimientos de referencia para 3 estrellas.
  int get par => (size * size * size * 1.3).round();
  int? get moveLimit =>
      modifier == Modifier.limited ? (par * 2.2).round() : null;

  int starsFor(int moves) => moves <= par
      ? 3
      : moves <= par * 1.7
      ? 2
      : 1;

  /// Clave única para guardar estrellas.
  String get key => isDaily ? 'D$dayKey' : 'L$level';
}

const maxBoardSize = 8;

/// Niveles infinitos: el tablero crece cada 4 niveles hasta 8x8; cada 5º
/// nivel tiene tope de movimientos y cada 7º va sin números.
GameSpec levelSpec(int n) {
  final size = min(3 + (n - 1) ~/ 4, maxBoardSize);
  final modifier = n % 7 == 0
      ? Modifier.blind
      : n % 5 == 0
      ? Modifier.limited
      : Modifier.none;
  return GameSpec(
    title: 'Nivel $n',
    size: size,
    image: images[(n - 1) % images.length],
    modifier: modifier,
    level: n,
  );
}

String dayKeyOf(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

/// Reto diario: mismo puzzle para todos los que jueguen ese día.
GameSpec dailySpec(DateTime d) {
  final key = dayKeyOf(d);
  final seed = int.parse(key);
  return GameSpec(
    title: 'Reto diario',
    size: 3 + seed % 4,
    image: images[seed % images.length],
    seed: seed,
    dayKey: key,
  );
}
