class PuzzleImage {
  const PuzzleImage(this.asset, this.title, this.credit);
  final String asset;
  final String title;
  final String credit;
}

/// Obras de dominio público (Wikimedia Commons / NASA).
const images = <PuzzleImage>[
  PuzzleImage('assets/images/noche_estrellada.jpg', 'La noche estrellada',
      'Vincent van Gogh, 1889'),
  PuzzleImage('assets/images/gran_ola.jpg', 'La gran ola de Kanagawa',
      'Katsushika Hokusai, c. 1831'),
  PuzzleImage('assets/images/perla.jpg', 'La joven de la perla',
      'Johannes Vermeer, c. 1665'),
  PuzzleImage('assets/images/tierra.jpg', 'La canica azul', 'NASA, 1972'),
  PuzzleImage('assets/images/venus.jpg', 'El nacimiento de Venus',
      'Sandro Botticelli, c. 1485'),
  PuzzleImage('assets/images/girasoles.jpg', 'Los girasoles',
      'Vincent van Gogh, 1889'),
  PuzzleImage('assets/images/mona_lisa.jpg', 'La Gioconda',
      'Leonardo da Vinci, c. 1503'),
];

class Level {
  const Level(this.number, this.size, this.image);
  final int number;
  final int size;
  final PuzzleImage image;

  /// Fichas móviles (sin contar el hueco).
  int get tileCount => size * size - 1;
  String get label => '${size}x$size';
}

const levelCount = 16;

/// Cada 4 niveles el tablero crece: 3x3 (8 fichas), 4x4 (15), 5x5 (24), 6x6 (35).
final levels = List<Level>.generate(
  levelCount,
  (i) => Level(i + 1, 3 + i ~/ 4, images[i % images.length]),
);
