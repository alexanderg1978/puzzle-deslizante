/// Misiones diarias: se reinician cada día y pagan gemas al completarse.
class Quest {
  const Quest(this.id, this.title, this.target, this.reward);
  final String id;
  final String title;
  final int target;
  final int reward;
}

const dailyQuests = <Quest>[
  Quest('solve', 'Resuelve 3 puzzles', 3, 10),
  Quest('stars', 'Consigue 6 estrellas', 6, 15),
  Quest('daily', 'Completa el reto diario', 1, 20),
];

const hintCost = 5;
const undoCost = 2;
const freezeCost = 30;
const maxFreezes = 2;
const startingGems = 20;
