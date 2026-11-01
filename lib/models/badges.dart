class GameBadge {
  const GameBadge(this.id, this.name, this.description, this.emoji);
  final String id;
  final String name;
  final String description;
  final String emoji;
}

const allBadges = <GameBadge>[
  GameBadge('first_win', 'Primer paso', 'Completa tu primer puzzle', '🧩'),
  GameBadge('solved_10', 'Constante', 'Completa 10 puzzles', '🔟'),
  GameBadge('solved_30', 'Maestro', 'Completa 30 puzzles', '🏆'),
  GameBadge('streak_3', 'Calentando', 'Racha de 3 días', '🔥'),
  GameBadge('streak_7', 'Semana perfecta', 'Racha de 7 días', '📅'),
  GameBadge('streak_30', 'Imparable', 'Racha de 30 días', '🌟'),
  GameBadge('size_4', 'Jugador 4x4', 'Resuelve un tablero 4x4', '🎯'),
  GameBadge('size_5', 'Jugador 5x5', 'Resuelve un tablero 5x5', '🚀'),
  GameBadge('size_6', 'Jugador 6x6', 'Resuelve un tablero 6x6', '👑'),
  GameBadge('speed', 'Rayo', 'Resuelve un 3x3 en menos de 30 s', '⚡'),
  GameBadge('all_levels', 'Leyenda', 'Completa todos los niveles', '💎'),
];
