import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';

class PuzzleImage {
  const PuzzleImage(this.asset, this.title, this.credit, {this.filePath});

  /// Ruta del asset incluido en la app, o `remote/<id>` si viene del catálogo
  /// descargado (sirve además como clave en la galería).
  final String asset;
  final String title;
  final String credit;

  /// Archivo local de una imagen del catálogo ya descargada.
  final String? filePath;

  ImageProvider get provider =>
      filePath != null ? FileImage(File(filePath!)) : AssetImage(asset);

  /// Imagen lista para mostrar; [cacheWidth] reduce la memoria en miniaturas.
  Image view({BoxFit fit = BoxFit.cover, double? width, int? cacheWidth}) =>
      Image(
        image: cacheWidth == null
            ? provider
            : ResizeImage(provider, width: cacheWidth),
        fit: fit,
        width: width,
      );
}

/// Imágenes que vienen dentro de la app (siempre disponibles, sin conexión).
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
  PuzzleImage(
    'assets/images/amanecer_tierra.jpg',
    'Amanecer de la Tierra',
    'NASA, Apolo 8, 1968',
  ),
  PuzzleImage(
    'assets/images/saturno.jpg',
    'Saturno',
    'NASA/JPL, Cassini, 2008',
  ),
  PuzzleImage(
    'assets/images/libertad.jpg',
    'La libertad guiando al pueblo',
    'Eugène Delacroix, 1830',
  ),
  PuzzleImage(
    'assets/images/caminante.jpg',
    'El caminante sobre el mar de nubes',
    'Caspar David Friedrich, c. 1818',
  ),
  PuzzleImage('assets/images/grito.jpg', 'El grito', 'Edvard Munch, 1893'),
];

/// Imágenes disponibles para los niveles: las incluidas más las del catálogo
/// que ya se descargaron (las añade CatalogService).
List<PuzzleImage> imagePool = images;

enum Modifier {
  none,

  /// Tope de movimientos: si te pasas, pierdes el intento.
  limited,

  /// Cuenta atrás: si se acaba el tiempo, pierdes el intento (niveles jefe).
  timed,
}

/// Cada 10 niveles empieza un mundo nuevo; el último nivel de cada uno es un
/// jefe contrarreloj.
const levelsPerWorld = 10;

class World {
  const World(this.name, this.emoji);
  final String name;
  final String emoji;
}

const worlds = <World>[
  World('Pradera', '🌱'),
  World('Bosque', '🌲'),
  World('Desierto', '🏜️'),
  World('Océano', '🌊'),
  World('Montaña', '🏔️'),
  World('Volcán', '🌋'),
  World('Ciudad neón', '🌃'),
  World('Espacio', '🚀'),
  World('Galaxia', '🌌'),
];

/// Índice (desde 0) del mundo al que pertenece el nivel [n].
int worldIndexOf(int n) => (n - 1) ~/ levelsPerWorld;

/// Más allá del último mundo se repiten con un número de vuelta (II, III…).
String worldName(int index) {
  final base = worlds[index % worlds.length];
  final lap = index ~/ worlds.length + 1;
  return '${base.emoji} ${base.name}${lap > 1 ? ' $lap' : ''}';
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

  /// Solo el primer nivel enseña los números; el resto se juega con la imagen.
  bool get hasNumbers => level == 1;
  int get tileCount => size * size - 1;
  String get label => '${size}x$size';

  /// Movimientos de referencia para 3 estrellas.
  int get par => (size * size * size * 1.3).round();
  int? get moveLimit =>
      modifier == Modifier.limited ? (par * 2.2).round() : null;

  /// Segundos disponibles en los niveles jefe.
  int? get timeLimit =>
      modifier == Modifier.timed ? 30 + tileCount * 5 : null;

  int starsFor(int moves) => moves <= par
      ? 3
      : moves <= par * 1.7
      ? 2
      : 1;

  /// Clave única para guardar estrellas.
  String get key => isDaily ? 'D$dayKey' : 'L$level';
}

const maxBoardSize = 8;

/// Niveles infinitos: el tablero crece cada 3 niveles hasta 8x8 y cada 5º
/// nivel tiene tope de movimientos y cada 10º (jefe) es contrarreloj. Solo el
/// nivel 1 muestra números.
GameSpec levelSpec(int n) {
  final size = min(3 + (n - 1) ~/ 3, maxBoardSize);
  final modifier = n % levelsPerWorld == 0
      ? Modifier.timed
      : n % 5 == 0
      ? Modifier.limited
      : Modifier.none;
  return GameSpec(
    title: 'Nivel $n',
    size: size,
    image: imagePool[(n - 1) % imagePool.length],
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
    image: imagePool[seed % imagePool.length],
    seed: seed,
    dayKey: key,
  );
}
