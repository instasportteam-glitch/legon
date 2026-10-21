import 'program.dart';

class WorkoutLog {
  WorkoutLog({
    required this.id,
    required this.date,
    required this.level,
    required this.levelName,
    required this.strengthDone,
    required this.strengthTotal,
    required this.customDone,
    required this.warmupDone,
    required this.minutes,
    required this.effort,
    required this.note,
    required this.reps,
    required this.muscles,
    required this.completed,
  });

  final String id;
  final DateTime date;
  final int level;
  final String levelName;
  final int strengthDone;
  final int strengthTotal;
  final int customDone;
  final int warmupDone;
  final int minutes;

  /// Perceived effort, 1–10.
  final int effort;
  final String note;
  final int reps;

  /// One entry per completed exercise per muscle it works (duplicates are the point).
  final List<Muscle> muscles;
  final List<String> completed;

  bool get counts => strengthDone >= minExercisesForCredit;
  int get exercisesDone => strengthDone + customDone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'level': level,
        'levelName': levelName,
        'strengthDone': strengthDone,
        'strengthTotal': strengthTotal,
        'customDone': customDone,
        'warmupDone': warmupDone,
        'minutes': minutes,
        'effort': effort,
        'note': note,
        'reps': reps,
        'muscles': [for (final m in muscles) m.name],
        'completed': completed,
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        level: j['level'] as int,
        levelName: j['levelName'] as String? ?? '',
        strengthDone: j['strengthDone'] as int? ?? 0,
        strengthTotal: j['strengthTotal'] as int? ?? 10,
        customDone: j['customDone'] as int? ?? 0,
        warmupDone: j['warmupDone'] as int? ?? 0,
        minutes: j['minutes'] as int? ?? 0,
        effort: j['effort'] as int? ?? 5,
        note: j['note'] as String? ?? '',
        reps: j['reps'] as int? ?? 0,
        muscles: [
          for (final m in (j['muscles'] as List? ?? const []))
            if (Muscle.values.any((v) => v.name == m)) Muscle.values.byName(m as String),
        ],
        completed: [for (final c in (j['completed'] as List? ?? const [])) c as String],
      );
}

enum MediaKind { video, photo }

class CustomExercise {
  CustomExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.isWarmup,
    required this.sets,
    required this.reps,
    required this.muscles,
    required this.mediaKind,
    required this.mediaPaths,
    required this.addToToday,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isWarmup;
  final int sets;
  final int reps;
  final Set<Muscle> muscles;
  final MediaKind? mediaKind;
  final List<String> mediaPaths;
  final bool addToToday;
  final DateTime createdAt;

  Dose get dose => Dose(sets, reps, DoseUnit.reps);
  bool get hasVideo => mediaKind == MediaKind.video && mediaPaths.isNotEmpty;
  bool get hasPhotos => mediaKind == MediaKind.photo && mediaPaths.isNotEmpty;

  CustomExercise copyWith({bool? addToToday}) => CustomExercise(
        id: id,
        name: name,
        description: description,
        isWarmup: isWarmup,
        sets: sets,
        reps: reps,
        muscles: muscles,
        mediaKind: mediaKind,
        mediaPaths: mediaPaths,
        addToToday: addToToday ?? this.addToToday,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isWarmup': isWarmup,
        'sets': sets,
        'reps': reps,
        'muscles': [for (final m in muscles) m.name],
        'mediaKind': mediaKind?.name,
        'mediaPaths': mediaPaths,
        'addToToday': addToToday,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomExercise.fromJson(Map<String, dynamic> j) => CustomExercise(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        isWarmup: j['isWarmup'] as bool? ?? false,
        sets: j['sets'] as int? ?? 3,
        reps: j['reps'] as int? ?? 10,
        muscles: {
          for (final m in (j['muscles'] as List? ?? const []))
            if (Muscle.values.any((v) => v.name == m)) Muscle.values.byName(m as String),
        },
        mediaKind: switch (j['mediaKind']) {
          'video' => MediaKind.video,
          'photo' => MediaKind.photo,
          _ => null,
        },
        mediaPaths: [for (final p in (j['mediaPaths'] as List? ?? const [])) p as String],
        addToToday: j['addToToday'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
