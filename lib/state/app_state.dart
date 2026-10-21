import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/media_store.dart';
import '../data/models.dart';
import '../data/program.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// All app state, persisted as one JSON document in shared preferences.
class AppState extends ChangeNotifier {
  static const _key = 'legon_state_v1';

  SharedPreferences? _prefs;

  String name = '';
  String? photoPath;
  DateTime joined = DateTime.now();
  final List<WorkoutLog> logs = [];
  final List<CustomExercise> customs = [];
  int? _selectedLevel;

  // Session-only UI state.
  int tab = 0;
  bool legOn = true;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) {
      joined = DateTime.now();
      await _save();
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      name = m['name'] as String? ?? '';
      photoPath = m['photoPath'] as String?;
      joined = DateTime.tryParse(m['joined'] as String? ?? '') ?? DateTime.now();
      _selectedLevel = m['selectedLevel'] as int?;
      logs
        ..clear()
        ..addAll([
          for (final e in (m['logs'] as List? ?? const [])) WorkoutLog.fromJson(e as Map<String, dynamic>),
        ]);
      logs.sort((a, b) => b.date.compareTo(a.date));
      customs
        ..clear()
        ..addAll([
          for (final e in (m['customs'] as List? ?? const [])) CustomExercise.fromJson(e as Map<String, dynamic>),
        ]);
    } catch (_) {
      // Unreadable data: start fresh instead of crashing on launch.
    }
  }

  Future<void> _save() async {
    await _prefs?.setString(
      _key,
      jsonEncode({
        'name': name,
        'photoPath': photoPath,
        'joined': joined.toIso8601String(),
        'selectedLevel': _selectedLevel,
        'logs': [for (final l in logs) l.toJson()],
        'customs': [for (final c in customs) c.toJson()],
      }),
    );
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---- Profile ----

  String get displayName => name.trim().isEmpty ? 'legionary' : name.trim();

  void setName(String value) {
    name = value.trim();
    _changed();
  }

  Future<void> setPhoto(String? path) async {
    final old = photoPath;
    photoPath = path;
    _changed();
    if (old != null && old != path) await deleteMedia(old);
  }

  // ---- Ranks and complexes ----

  int get creditedWorkouts => logs.where((l) => l.counts).length;
  int get rankIndex => rankIndexFor(creditedWorkouts);
  Rank get rank => ranks[rankIndex];
  Rank? get nextRank => rankIndex + 1 < ranks.length ? ranks[rankIndex + 1] : null;

  double get rankProgress {
    final next = nextRank;
    if (next == null) return 1;
    final start = rank.threshold;
    return ((creditedWorkouts - start) / (next.threshold - start)).clamp(0.0, 1.0).toDouble();
  }

  /// Highest complex the user may train: one per rank.
  int get unlockedLevel => rankIndex + 1;

  int get currentLevel {
    final s = _selectedLevel;
    if (s != null && s >= 1 && s <= unlockedLevel) return s;
    return unlockedLevel;
  }

  void selectLevel(int level) {
    if (level < 1 || level > unlockedLevel) return;
    _selectedLevel = level;
    _changed();
  }

  // ---- Navigation helpers ----

  void setTab(int i) {
    if (tab == i) return;
    tab = i;
    notifyListeners();
  }

  void toggleLegOn() {
    legOn = !legOn;
    notifyListeners();
  }

  // ---- Workouts ----

  ({int before, int after}) logWorkout(WorkoutLog log) {
    final before = rankIndex;
    logs.add(log);
    logs.sort((a, b) => b.date.compareTo(a.date));
    _changed();
    return (before: before, after: rankIndex);
  }

  void deleteLog(String id) {
    logs.removeWhere((l) => l.id == id);
    _changed();
  }

  void restoreLog(WorkoutLog log) {
    if (logs.any((l) => l.id == log.id)) return;
    logs.add(log);
    logs.sort((a, b) => b.date.compareTo(a.date));
    _changed();
  }

  // ---- Custom exercises ----

  List<CustomExercise> get todaysAdditions => customs.where((c) => c.addToToday).toList();

  void addCustom(CustomExercise c) {
    customs.insert(0, c);
    _changed();
  }

  void setAddToToday(String id, bool value) {
    final i = customs.indexWhere((c) => c.id == id);
    if (i < 0) return;
    customs[i] = customs[i].copyWith(addToToday: value);
    _changed();
  }

  Future<void> deleteCustom(String id) async {
    final i = customs.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final removed = customs.removeAt(i);
    _changed();
    for (final p in removed.mediaPaths) {
      await deleteMedia(p);
    }
  }

  // ---- Streaks ----

  Set<DateTime> get trainedDays => {for (final l in logs) dateOnly(l.date)};

  int get currentStreak {
    final days = trainedDays;
    var d = dateOnly(DateTime.now());
    if (!days.contains(d)) d = DateTime(d.year, d.month, d.day - 1);
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  int get bestStreak {
    final days = trainedDays.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in days) {
      final follows = prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d;
      run = follows ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  // ---- Reset ----

  Future<void> resetAll() async {
    final files = [
      for (final c in customs) ...c.mediaPaths,
      if (photoPath != null) photoPath!,
    ];
    name = '';
    photoPath = null;
    joined = DateTime.now();
    _selectedLevel = null;
    logs.clear();
    customs.clear();
    tab = 0;
    legOn = true;
    _changed();
    for (final f in files) {
      await deleteMedia(f);
    }
  }
}

/// Makes [AppState] available to the widget tree and rebuilds dependents.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.notifier!;
  }

  /// Access without subscribing to rebuilds (for callbacks).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
