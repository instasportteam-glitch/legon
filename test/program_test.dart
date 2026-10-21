import 'package:flutter_test/flutter_test.dart';
import 'package:legonn/data/models.dart';
import 'package:legonn/data/program.dart';

void main() {
  test('ten complexes of ten known exercises', () {
    expect(levels.length, 10);
    for (final level in levels) {
      expect(level.exerciseIds.length, 10, reason: level.name);
      expect(level.exerciseIds.toSet().length, 10, reason: '${level.name} repeats an exercise');
      for (final id in level.exerciseIds) {
        expect(exerciseById.containsKey(id), isTrue, reason: '$id in ${level.name}');
      }
    }
  });

  test('ten ranks with rising thresholds', () {
    expect(ranks.length, 10);
    for (var i = 1; i < ranks.length; i++) {
      expect(ranks[i].threshold, greaterThan(ranks[i - 1].threshold));
    }
    expect(rankIndexFor(0), 0);
    expect(rankIndexFor(4), 0);
    expect(rankIndexFor(5), 1);
    expect(rankIndexFor(30), 4);
    expect(rankIndexFor(1000), 9);
  });

  test('doses grow with the complex', () {
    final pushups = exerciseById['pushups']!;
    expect(pushups.doseFor(1).label, '3×8');
    expect(pushups.doseFor(4).label, '4×14');
    expect(exerciseById['march']!.doseFor(5).label, '16 min');
    expect(exerciseById['palus']!.doseFor(1).label, '3×30 s');
    expect(warmups.first.doseFor(1).label, '2 min');
  });

  test('roman numerals', () {
    expect([for (var i = 1; i <= 10; i++) roman(i)].join(' '), 'I II III IV V VI VII VIII IX X');
  });

  test('workout log survives a JSON round trip', () {
    final log = WorkoutLog(
      id: '1',
      date: DateTime(2026, 10, 19, 8, 10),
      level: 5,
      levelName: "Caesar's March",
      strengthDone: 8,
      strengthTotal: 10,
      customDone: 1,
      warmupDone: 4,
      minutes: 41,
      effort: 8,
      note: 'Felt strong',
      reps: 200,
      muscles: const [Muscle.legs, Muscle.core],
      completed: const ['march', 'pushups'],
    );
    final back = WorkoutLog.fromJson(log.toJson());
    expect(back.counts, isTrue);
    expect(back.muscles, [Muscle.legs, Muscle.core]);
    expect(back.minutes, 41);
    expect(back.date, log.date);
  });
}
