import 'levels.dart';

/// Cada cuántos niveles hay un cofre de hito.
const milestoneEvery = 5;

/// Gemas del cofre al completar por primera vez el nivel [level] (múltiplo de
/// [milestoneEvery]).
int milestoneReward(int level) => 20 + level;

/// Mínimo de victorias perfectas seguidas para cobrar bono de combo.
const comboMinimum = 2;

/// Gemas extra por combo: sube con la racha de 3 estrellas, hasta 10.
int comboBonusFor(int combo) => combo >= comboMinimum ? combo.clamp(0, 10) : 0;

/// "Ingenio": mide lo eficiente que fue la partida frente al par y crece con
/// el tamaño del tablero, así un 6x6 limpio vale más que un 3x3 limpio.
int ingenuityOf(GameSpec spec, int moves) {
  if (moves <= 0) return 0;
  final efficiency = (spec.par / moves).clamp(0.0, 1.25);
  return (efficiency * 100 * (0.7 + spec.size * 0.1)).round();
}

/// Título del elogio según el rendimiento.
String praiseTitle(GameSpec spec, int stars, int moves) {
  if (stars == 3 && moves <= spec.par * 0.8) return '¡Genio!';
  return switch (stars) {
    3 => '¡Maestro!',
    2 => '¡Muy bien!',
    _ => '¡Completado!',
  };
}

String difficultyName(GameSpec spec) {
  if (spec.modifier == Modifier.timed) return 'Jefe';
  if (spec.modifier == Modifier.limited) return 'Reto';
  return switch (spec.size) {
    3 => 'Fácil',
    4 => 'Normal',
    5 => 'Difícil',
    6 => 'Experto',
    _ => 'Maestro',
  };
}

/// Frase personal bajo el título; cambia según lo que acaba de pasar.
String praiseLine(
  GameSpec spec, {
  required int stars,
  required int moves,
  required int seconds,
  required bool record,
  required int combo,
}) {
  if (record) return '¡Has batido tu récord en este nivel!';
  if (combo >= 3) return '¡$combo victorias perfectas seguidas!';
  if (stars == 3 && spec.size >= 5) {
    return 'Los tableros de ${spec.label} son solo un calentamiento para ti';
  }
  final pick = (moves + seconds) % 3;
  if (stars == 3) {
    return const [
      'Tienes ojo de artista',
      'Esa estrategia fue de manual',
      'Casi sin errores, impresionante',
    ][pick];
  }
  if (stars == 2) {
    return const [
      'Cada vez más cerca de la perfección',
      'Un par de movimientos menos y son 3 estrellas',
      'Vas por muy buen camino',
    ][pick];
  }
  return const [
    'Lo importante es terminar: ahora, a mejorar',
    'La práctica hace al maestro',
    'Puedes rejugarlo para conseguir más estrellas',
  ][pick];
}

/// Mensaje al perder, que anima a reintentar al ver lo cerca que estuviste.
String nearMissLine(int misplaced) {
  if (misplaced <= 0) return '¡Estabas a un paso!';
  if (misplaced == 1) return '¡Casi! Te faltaba 1 ficha por colocar';
  return '¡Casi! Te faltaban $misplaced fichas por colocar';
}
