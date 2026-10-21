/// The training program: ten ranks, ten complexes of ten exercises each,
/// and a shared warm-up. Doses grow with the complex number.
library;

enum DoseUnit { reps, seconds, minutes, meters }

class Dose {
  const Dose(this.sets, this.amount, this.unit);

  final int sets;
  final int amount;
  final DoseUnit unit;

  String get label {
    final suffix = switch (unit) {
      DoseUnit.reps => '',
      DoseUnit.seconds => ' s',
      DoseUnit.minutes => ' min',
      DoseUnit.meters => ' m',
    };
    if (sets <= 1) {
      return unit == DoseUnit.reps ? '$amount reps' : '$amount$suffix';
    }
    return '$sets×$amount$suffix';
  }

  /// Repetitions this dose adds to the reps total (time and distance add 0).
  int get reps => unit == DoseUnit.reps ? sets * amount : 0;

  /// Rough time cost including rest, used only for the duration estimate.
  int get estimatedSeconds => switch (unit) {
        DoseUnit.reps => sets * (amount * 3 + 60),
        DoseUnit.seconds => sets * (amount + 60),
        DoseUnit.minutes => amount * 60,
        DoseUnit.meters => sets * (amount ~/ 2 + 60),
      };
}

enum Muscle {
  legs('Legs'),
  core('Core'),
  arms('Arms'),
  shoulders('Shoulders'),
  back('Back'),
  endurance('Endurance');

  const Muscle(this.label);
  final String label;
}

class ExerciseDef {
  const ExerciseDef({
    required this.id,
    required this.name,
    required this.note,
    required this.unit,
    required this.baseSets,
    required this.baseAmount,
    required this.step,
    this.muscles = const [],
  });

  final String id;
  final String name;
  final String note;
  final DoseUnit unit;
  final int baseSets;
  final int baseAmount;

  /// Amount added per complex above I.
  final int step;
  final List<Muscle> muscles;

  /// Dose for complex [level] (1–10). One extra set every three complexes.
  Dose doseFor(int level) {
    final sets = (unit == DoseUnit.minutes || baseSets <= 1) ? 1 : baseSets + (level - 1) ~/ 3;
    return Dose(sets, baseAmount + step * (level - 1), unit);
  }
}

const exercisePool = <ExerciseDef>[
  ExerciseDef(id: 'march', name: 'Loaded march', note: 'Pack on your back, brisk pace', unit: DoseUnit.minutes, baseSets: 1, baseAmount: 8, step: 2, muscles: [Muscle.legs, Muscle.endurance]),
  ExerciseDef(id: 'palus', name: 'Palus strikes', note: 'Strike a bag or post, shield arm up', unit: DoseUnit.seconds, baseSets: 3, baseAmount: 30, step: 5, muscles: [Muscle.arms, Muscle.shoulders, Muscle.endurance]),
  ExerciseDef(id: 'pushups', name: 'Push-ups', note: 'Hands wider than shoulders, body rigid', unit: DoseUnit.reps, baseSets: 3, baseAmount: 8, step: 2, muscles: [Muscle.arms, Muscle.shoulders, Muscle.core]),
  ExerciseDef(id: 'squats', name: 'Squats', note: 'Hold a sandbag or kettlebell from complex IV', unit: DoseUnit.reps, baseSets: 3, baseAmount: 10, step: 2, muscles: [Muscle.legs]),
  ExerciseDef(id: 'pilum', name: 'Pilum throw', note: 'Explosive overhead throw with a medicine ball', unit: DoseUnit.reps, baseSets: 3, baseAmount: 6, step: 1, muscles: [Muscle.shoulders, Muscle.arms, Muscle.core]),
  ExerciseDef(id: 'ditch', name: 'Ditch jumps', note: 'Standing broad jumps, soft landing', unit: DoseUnit.reps, baseSets: 3, baseAmount: 5, step: 1, muscles: [Muscle.legs]),
  ExerciseDef(id: 'carry', name: 'Stone carry', note: "Farmer's walk with heavy stones or bags", unit: DoseUnit.meters, baseSets: 3, baseAmount: 20, step: 5, muscles: [Muscle.back, Muscle.arms, Muscle.core]),
  ExerciseDef(id: 'pullups', name: 'Pull-ups', note: 'From a full hang, chin over the bar', unit: DoseUnit.reps, baseSets: 3, baseAmount: 2, step: 1, muscles: [Muscle.back, Muscle.arms]),
  ExerciseDef(id: 'testudo', name: 'Testudo hold', note: 'Plank, as if holding the shield wall', unit: DoseUnit.seconds, baseSets: 3, baseAmount: 20, step: 5, muscles: [Muscle.core, Muscle.shoulders]),
  ExerciseDef(id: 'charge', name: 'Line charge', note: 'Accelerating sprint, walk back to recover', unit: DoseUnit.meters, baseSets: 4, baseAmount: 20, step: 2, muscles: [Muscle.legs, Muscle.endurance]),
  ExerciseDef(id: 'lunges', name: 'Legionary lunges', note: 'Long steps, back knee near the ground, each leg', unit: DoseUnit.reps, baseSets: 3, baseAmount: 8, step: 1, muscles: [Muscle.legs, Muscle.core]),
  ExerciseDef(id: 'shield_press', name: 'Shield press', note: 'Overhead press with a weight or sandbag', unit: DoseUnit.reps, baseSets: 3, baseAmount: 6, step: 1, muscles: [Muscle.shoulders, Muscle.arms]),
  ExerciseDef(id: 'rampart', name: 'Rampart building', note: 'Lift a sandbag from the ground to your shoulder', unit: DoseUnit.reps, baseSets: 3, baseAmount: 5, step: 1, muscles: [Muscle.back, Muscle.legs, Muscle.core]),
  ExerciseDef(id: 'fall_rise', name: 'Fall and rise', note: 'Burpee: drop to the ground and spring up', unit: DoseUnit.reps, baseSets: 3, baseAmount: 5, step: 1, muscles: [Muscle.endurance, Muscle.legs, Muscle.arms]),
  ExerciseDef(id: 'hang', name: 'Siege hang', note: 'Dead hang from a bar, shoulders active', unit: DoseUnit.seconds, baseSets: 3, baseAmount: 15, step: 5, muscles: [Muscle.back, Muscle.arms]),
  ExerciseDef(id: 'crawl', name: 'Crawl under arrows', note: 'Bear crawl, hips low', unit: DoseUnit.meters, baseSets: 3, baseAmount: 10, step: 2, muscles: [Muscle.core, Muscle.shoulders, Muscle.endurance]),
];

final Map<String, ExerciseDef> exerciseById = {for (final e in exercisePool) e.id: e};

const warmups = <ExerciseDef>[
  ExerciseDef(id: 'w_run', name: 'Running in place', note: '', unit: DoseUnit.minutes, baseSets: 1, baseAmount: 2, step: 0),
  ExerciseDef(id: 'w_rotate', name: 'Shoulder and torso rotations', note: '', unit: DoseUnit.minutes, baseSets: 1, baseAmount: 1, step: 0),
  ExerciseDef(id: 'w_lunge', name: 'Walking lunges, each leg', note: '', unit: DoseUnit.reps, baseSets: 1, baseAmount: 8, step: 1),
  ExerciseDef(id: 'w_bend', name: 'Bends with a staff', note: '', unit: DoseUnit.reps, baseSets: 1, baseAmount: 10, step: 1),
];

class Level {
  const Level(this.number, this.name, this.description, this.exerciseIds);

  final int number;
  final String name;
  final String description;
  final List<String> exerciseIds;

  List<ExerciseDef> get exercises => [for (final id in exerciseIds) exerciseById[id]!];

  int get estimatedMinutes {
    var seconds = 0;
    for (final w in warmups) {
      seconds += w.doseFor(number).estimatedSeconds;
    }
    for (final e in exercises) {
      seconds += e.doseFor(number).estimatedSeconds;
    }
    return (seconds / 60).round();
  }
}

const levels = <Level>[
  Level(1, "Recruit's Drill", 'Tirocinium: the basics every recruit learned before carrying a shield.',
      ['march', 'pushups', 'squats', 'lunges', 'testudo', 'ditch', 'palus', 'fall_rise', 'hang', 'charge']),
  Level(2, 'First Watch', 'Longer marches and the first crawl drills of camp life.',
      ['march', 'palus', 'pushups', 'squats', 'lunges', 'testudo', 'carry', 'ditch', 'crawl', 'charge']),
  Level(3, 'The Palisade', 'Every evening the legion built a fortified camp. Lift, carry, dig.',
      ['march', 'rampart', 'pushups', 'squats', 'carry', 'testudo', 'palus', 'pilum', 'hang', 'charge']),
  Level(4, 'Shield and Sword', 'Weapons drill at the palus and the first pilum throws.',
      ['palus', 'shield_press', 'pushups', 'lunges', 'testudo', 'pilum', 'ditch', 'carry', 'pullups', 'charge']),
  Level(5, "Caesar's March", 'A warm-up and ten exercises legionaries used to prepare for the march and the battle line.',
      ['march', 'palus', 'pushups', 'squats', 'pilum', 'ditch', 'carry', 'pullups', 'testudo', 'charge']),
  Level(6, 'The Standard', 'The signifer carried the standard into battle. Strength to hold it high.',
      ['march', 'shield_press', 'pullups', 'squats', 'rampart', 'fall_rise', 'crawl', 'testudo', 'pilum', 'charge']),
  Level(7, "The Century's Wall", 'Eighty men moving as one. Endurance under the shield wall.',
      ['palus', 'pushups', 'lunges', 'rampart', 'carry', 'testudo', 'pullups', 'ditch', 'fall_rise', 'charge']),
  Level(8, 'Siege of Alesia', 'Miles of walls built around the enemy. Heavy lifting and long holds.',
      ['march', 'rampart', 'squats', 'shield_press', 'hang', 'pullups', 'crawl', 'carry', 'fall_rise', 'charge']),
  Level(9, "Tribune's Trial", 'An officer leads from the front. Everything, harder.',
      ['march', 'palus', 'pullups', 'pushups', 'squats', 'pilum', 'carry', 'testudo', 'fall_rise', 'charge']),
  Level(10, "Legate's Triumph", 'The final complex. Finish it and march through Rome.',
      ['march', 'rampart', 'shield_press', 'pullups', 'squats', 'lunges', 'carry', 'testudo', 'fall_rise', 'charge']),
];

class Rank {
  const Rank(this.name, this.meaning, this.threshold);

  final String name;
  final String meaning;

  /// Credited workouts needed to hold this rank.
  final int threshold;
}

const ranks = <Rank>[
  Rank('Tiro', 'Recruit, learning the drill', 0),
  Rank('Miles', 'Soldier of the line', 5),
  Rank('Immunis', 'Skilled soldier, spared camp chores', 12),
  Rank('Tesserarius', 'Keeper of the watchword', 20),
  Rank('Optio', "The centurion's second in command", 30),
  Rank('Signifer', 'Bearer of the standard', 42),
  Rank('Centurio', 'Commander of a century', 56),
  Rank('Primus Pilus', 'First centurion of the legion', 72),
  Rank('Tribunus', 'Senior officer of the legion', 90),
  Rank('Legatus', 'Commander of the legion', 110),
];

/// A workout counts toward rank when at least this many strength
/// exercises were completed.
const minExercisesForCredit = 7;

int rankIndexFor(int creditedWorkouts) {
  var index = 0;
  for (var i = 0; i < ranks.length; i++) {
    if (creditedWorkouts >= ranks[i].threshold) index = i;
  }
  return index;
}

String roman(int n) => const ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'][n - 1];
