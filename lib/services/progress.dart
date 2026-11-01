import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badges.dart';
import '../models/levels.dart';

class WinResult {
  const WinResult(this.stars, this.newBadges, this.improved);
  final int stars;
  final List<GameBadge> newBadges;

  /// true si superó su mejor marca anterior (o es la primera vez).
  final bool improved;
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
    // Si pasó más de un día sin jugar, la racha ya se perdió.
    return gap > 1 ? 0 : (_prefs.getInt(_k('streak')) ?? 0);
  }

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
    if (level != null) {
      final prevMoves = bestMoves(level);
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
    await _updateStreak();

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
      if (gap == 1) {
        current += 1;
      } else if (gap > 1) {
        current = 1;
      } // gap == 0: ya contó hoy
    }
    await _prefs.setInt(_k('streak'), current);
    await _prefs.setString(_k('last_day'), now.toIso8601String());
    if (current > bestStreak) await _prefs.setInt(_k('best_streak'), current);
  }
}
