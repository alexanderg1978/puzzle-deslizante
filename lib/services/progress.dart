import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badges.dart';
import '../models/levels.dart';
import '../models/praise.dart';
import '../models/quests.dart';

class WinResult {
  const WinResult(
    this.stars,
    this.newBadges,
    this.improved,
    this.gems,
    this.completedQuests, {
    this.record = false,
    this.ingenuity = 0,
    this.bestIngenuity = false,
    this.combo = 0,
    this.comboBonus = 0,
    this.doubled = false,
    this.chestGems = 0,
    this.newImage = false,
  });
  final int stars;

  /// Mejoró su mejor marca de movimientos en este nivel (no la primera vez).
  final bool record;

  /// Puntuación de ingenio de la partida y si es la mejor hasta ahora.
  final int ingenuity;
  final bool bestIngenuity;

  /// Victorias perfectas seguidas (incluida esta) y gemas extra que dio.
  final int combo;
  final int comboBonus;

  /// Primera victoria del día: las gemas se duplican.
  final bool doubled;

  /// Gemas del cofre de hito (0 si este nivel no lo daba).
  final int chestGems;

  /// La obra se añadió a la galería con esta victoria.
  final bool newImage;
  final List<GameBadge> newBadges;

  /// true si superó su mejor marca anterior (o es la primera vez).
  final bool improved;

  /// Gemas ganadas por la partida (sin contar misiones).
  final int gems;

  /// Misiones diarias que se completaron con esta victoria.
  final List<Quest> completedQuests;
}

/// Progreso guardado solo en el teléfono (SharedPreferences), sin servidor.
/// Cada jugador (cuenta de Google o invitado) tiene su propio espacio.
class Progress extends ChangeNotifier {
  Progress._(this._prefs);

  final SharedPreferences _prefs;
  String _user = 'guest';

  static Future<Progress> load() async =>
      Progress._(await SharedPreferences.getInstance());

  // ---- sesión ----
  String? get playerName => _prefs.getString('session_name');
  String? get playerEmail => _prefs.getString('session_email');
  bool get hasSession => _prefs.getBool('session_active') ?? false;

  /// [id] es el id de Google, o null para jugar como invitado.
  Future<void> startSession({String? id, String? name, String? email}) async {
    _user = id ?? 'guest';
    await _prefs.setBool('session_active', true);
    await _prefs.setString('session_user', _user);
    await _setOrRemove('session_name', name);
    await _setOrRemove('session_email', email);
    notifyListeners();
  }

  Future<void> endSession() async {
    await _prefs.setBool('session_active', false);
    notifyListeners();
  }

  void restoreUser() {
    _user = _prefs.getString('session_user') ?? 'guest';
  }

  Future<void> _setOrRemove(String key, String? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value);
    }
  }

  String _k(String key) => '$_user/$key';

  // ---- niveles y estrellas ----
  int get unlockedLevel => _prefs.getInt(_k('unlocked')) ?? 1;
  int get totalSolved => _prefs.getInt(_k('solved')) ?? 0;
  int get totalStars => _prefs.getInt(_k('stars_total')) ?? 0;
  int starsOf(GameSpec spec) => _prefs.getInt(_k('stars_${spec.key}')) ?? 0;
  int levelStars(int level) => _prefs.getInt(_k('stars_L$level')) ?? 0;
  int? bestMoves(int level) => _prefs.getInt(_k('best_moves_$level'));
  int? bestSeconds(int level) => _prefs.getInt(_k('best_secs_$level'));
  bool isCompleted(int level) => levelStars(level) > 0;

  // ---- reto diario ----
  int get dailyCount => _prefs.getInt(_k('daily_count')) ?? 0;
  bool dailyDone(DateTime d) =>
      (_prefs.getInt(_k('stars_D${dayKeyOf(d)}')) ?? 0) > 0;

  // ---- racha ----
  int get streak {
    final last = _prefs.getString(_k('last_day'));
    if (last == null) return 0;
    final gap = _dayNumber(DateTime.now()) - _dayNumber(DateTime.parse(last));
    // Cada día perdido gasta un congelador; sin ellos la racha se pierde.
    final missed = gap - 1;
    return missed > freezes ? 0 : (_prefs.getInt(_k('streak')) ?? 0);
  }

  // ---- gemas, congeladores, cofre ----
  int get gems => _prefs.getInt(_k('gems')) ?? startingGems;
  int get freezes => _prefs.getInt(_k('freezes')) ?? 0;
  bool get chestReady =>
      _prefs.getString(_k('chest_day')) != dayKeyOf(DateTime.now());

  Future<void> addGems(int n) async {
    await _prefs.setInt(_k('gems'), gems + n);
    notifyListeners();
  }

  /// Gasta [n] gemas; devuelve false si no alcanzan.
  Future<bool> spendGems(int n) async {
    if (gems < n) return false;
    await _prefs.setInt(_k('gems'), gems - n);
    notifyListeners();
    return true;
  }

  Future<bool> buyFreeze() async {
    if (freezes >= maxFreezes || !await spendGems(freezeCost)) return false;
    await _prefs.setInt(_k('freezes'), freezes + 1);
    notifyListeners();
    return true;
  }

  /// Abre el cofre diario: 10 a 30 gemas más un extra por racha (máx. +10).
  /// Devuelve las gemas ganadas o null si ya se abrió hoy.
  Future<int?> openChest() async {
    if (!chestReady) return null;
    final reward = 10 + Random().nextInt(21) + streak.clamp(0, 10);
    await _prefs.setString(_k('chest_day'), dayKeyOf(DateTime.now()));
    await addGems(reward);
    return reward;
  }

  // ---- misiones diarias ----
  String get _today => dayKeyOf(DateTime.now());
  int questProgress(Quest q) => _prefs.getInt(_k('q_${_today}_${q.id}')) ?? 0;
  bool questDone(Quest q) => questProgress(q) >= q.target;

  // ---- galería ----
  Set<String> get gallery =>
      (_prefs.getStringList(_k('gallery')) ?? []).toSet();

  /// Niveles seguidos ganados con 3 estrellas.
  int get combo => _prefs.getInt(_k('combo')) ?? 0;
  int get bestCombo => _prefs.getInt(_k('best_combo')) ?? 0;
  int get bestIngenuity => _prefs.getInt(_k('best_ingenuity')) ?? 0;

  int get bestStreak => _prefs.getInt(_k('best_streak')) ?? 0;
  bool get playedToday {
    final last = _prefs.getString(_k('last_day'));
    return last != null &&
        _dayNumber(DateTime.now()) == _dayNumber(DateTime.parse(last));
  }

  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  // ---- insignias ----
  Set<String> get badges => (_prefs.getStringList(_k('badges')) ?? []).toSet();
  int get badgeCount => allBadges.where((b) => badges.contains(b.id)).length;

  /// Registra una victoria y devuelve estrellas e insignias nuevas.
  Future<WinResult> recordWin(GameSpec spec, int moves, int seconds) async {
    final stars = spec.starsFor(moves);
    final oldStars = starsOf(spec);
    final improved = stars > oldStars;

    if (improved) {
      await _prefs.setInt(_k('stars_${spec.key}'), stars);
      await _prefs.setInt(_k('stars_total'), totalStars + stars - oldStars);
    }

    final level = spec.level;
    var record = false;
    if (level != null) {
      final prevMoves = bestMoves(level);
      record = prevMoves != null && moves < prevMoves;
      if (prevMoves == null || moves < prevMoves) {
        await _prefs.setInt(_k('best_moves_$level'), moves);
      }
      final prevSecs = bestSeconds(level);
      if (prevSecs == null || seconds < prevSecs) {
        await _prefs.setInt(_k('best_secs_$level'), seconds);
      }
      if (level >= unlockedLevel) {
        await _prefs.setInt(_k('unlocked'), level + 1);
      }
    } else if (oldStars == 0) {
      await _prefs.setInt(_k('daily_count'), dailyCount + 1);
    }

    await _prefs.setInt(_k('solved'), totalSolved + 1);
    // La primera victoria del día duplica las gemas.
    final doubled = !playedToday;
    await _updateStreak();

    // Combo: niveles seguidos con 3 estrellas. El bono solo se cobra si la
    // partida da recompensa (no se puede abusar rejugando).
    final newCombo = stars == 3 ? combo + 1 : 0;
    await _prefs.setInt(_k('combo'), newCombo);
    if (newCombo > bestCombo) await _prefs.setInt(_k('best_combo'), newCombo);
    final rewarded = oldStars == 0 || improved;
    final comboBonus = rewarded ? comboBonusFor(newCombo) : 0;

    // Ingenio: se guarda el mejor.
    final ingenuity = ingenuityOf(spec, moves);
    final bestIngenuityNow = ingenuity > bestIngenuity;
    if (bestIngenuityNow) await _prefs.setInt(_k('best_ingenuity'), ingenuity);

    // Cofre de hito cada [milestoneEvery] niveles, solo la primera vez.
    final chestGems =
        level != null && oldStars == 0 && level % milestoneEvery == 0
        ? milestoneReward(level)
        : 0;

    // Gemas: recompensa completa la primera vez, por estrellas mejoradas
    // después, y 1 por repetir.
    // Vencer a un jefe (contrarreloj) por primera vez da un bono extra.
    final baseGems =
        (oldStars == 0
            ? 5 + 3 * stars
            : improved
            ? 3 * (stars - oldStars)
            : 1) +
        (oldStars == 0 && spec.modifier == Modifier.timed ? bossBonus : 0) +
        comboBonus;
    final gemsEarned = baseGems * (doubled ? 2 : 1) + chestGems;
    var questGems = 0;
    final doneQuests = <Quest>[];
    for (final q in dailyQuests) {
      if (questDone(q)) continue;
      final add = switch (q.id) {
        'solve' => 1,
        'stars' => stars,
        'daily' => spec.isDaily ? 1 : 0,
        _ => 0,
      };
      if (add == 0) continue;
      await _prefs.setInt(_k('q_${_today}_${q.id}'), questProgress(q) + add);
      if (questDone(q)) {
        doneQuests.add(q);
        questGems += q.reward;
      }
    }
    await addGems(gemsEarned + questGems);

    final shown = gallery;
    final newImage = !shown.contains(spec.image.asset);
    if (newImage) {
      await _prefs.setStringList(_k('gallery'), [...shown, spec.image.asset]);
    }

    final owned = badges;
    final earned = <String>{
      'first_win',
      if (totalSolved >= 10) 'solved_10',
      if (totalSolved >= 30) 'solved_30',
      if (streak >= 3) 'streak_3',
      if (streak >= 7) 'streak_7',
      if (streak >= 30) 'streak_30',
      if (spec.size >= 4) 'size_4',
      if (spec.size >= 5) 'size_5',
      if (spec.size >= 6) 'size_6',
      if (spec.size >= 8) 'size_8',
      if (spec.size == 3 && seconds < 30) 'speed',
      if (stars == 3) 'perfect',
      if (totalStars >= 50) 'stars_50',
      if (totalStars >= 150) 'stars_150',
      if (level != null && level >= 25) 'level_25',
      if (level != null && level >= 50) 'level_50',
      if (spec.modifier != Modifier.none) 'challenge',
      if (spec.modifier == Modifier.timed) 'boss',
      if (spec.isDaily) 'daily_1',
      if (dailyCount >= 7) 'daily_7',
    };
    final fresh = earned.difference(owned);
    if (fresh.isNotEmpty) {
      await _prefs.setStringList(_k('badges'), {...owned, ...earned}.toList());
    }
    notifyListeners();
    return WinResult(
      stars,
      allBadges.where((b) => fresh.contains(b.id)).toList(),
      improved,
      gemsEarned,
      doneQuests,
      record: record,
      ingenuity: ingenuity,
      bestIngenuity: bestIngenuityNow,
      combo: newCombo,
      comboBonus: comboBonus,
      doubled: doubled,
      chestGems: chestGems,
      newImage: newImage,
    );
  }

  Future<void> _updateStreak() async {
    final now = DateTime.now();
    final last = _prefs.getString(_k('last_day'));
    final today = _dayNumber(now);
    var current = _prefs.getInt(_k('streak')) ?? 0;
    if (last == null) {
      current = 1;
    } else {
      final gap = today - _dayNumber(DateTime.parse(last));
      final missed = gap - 1;
      if (gap == 1) {
        current += 1;
      } else if (gap > 1) {
        if (missed <= freezes) {
          // Los congeladores cubren los días perdidos y la racha sigue.
          await _prefs.setInt(_k('freezes'), freezes - missed);
          current += 1;
        } else {
          current = 1;
        }
      } // gap == 0: ya contó hoy
    }
    await _prefs.setInt(_k('streak'), current);
    await _prefs.setString(_k('last_day'), now.toIso8601String());
    if (current > bestStreak) await _prefs.setInt(_k('best_streak'), current);
  }
}
