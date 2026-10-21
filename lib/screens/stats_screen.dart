import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/program.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/format.dart';
import '../ui/widgets.dart';
import '../ui/legion_art.dart';

enum Period { week, month, year }

class _Bucket {
  _Bucket(this.label, this.start, this.end);
  final String label;
  final DateTime start;
  final DateTime end;
  int minutes = 0;
}

List<_Bucket> _bucketsFor(Period p, DateTime now) {
  final today = dateOnly(now);
  switch (p) {
    case Period.week:
      final monday = mondayOf(today);
      return [
        for (var i = 0; i < 7; i++)
          _Bucket(
            weekdayShort[i],
            DateTime(monday.year, monday.month, monday.day + i),
            DateTime(monday.year, monday.month, monday.day + i + 1),
          ),
      ];
    case Period.month:
      final monday = mondayOf(today);
      final start = DateTime(monday.year, monday.month, monday.day - 21);
      return [
        for (var i = 0; i < 4; i++)
          _Bucket(
            '${monthShort[DateTime(start.year, start.month, start.day + 7 * i).month - 1]} ${DateTime(start.year, start.month, start.day + 7 * i).day}',
            DateTime(start.year, start.month, start.day + 7 * i),
            DateTime(start.year, start.month, start.day + 7 * (i + 1)),
          ),
      ];
    case Period.year:
      break;
  }
  return [
    for (var m = 1; m <= 12; m++)
      _Bucket(
        monthShort[m - 1].substring(0, 1),
        DateTime(today.year, m, 1),
        DateTime(today.year, m + 1, 1),
      ),
  ];
}

bool _inRange(DateTime d, DateTime start, DateTime end) =>
    !d.isBefore(start) && d.isBefore(end);

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Period _period = Period.week;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    final now = DateTime.now();
    final buckets = _bucketsFor(_period, now);
    final start = buckets.first.start;
    final end = buckets.last.end;
    final inPeriod = <WorkoutLog>[];
    for (final log in app.logs) {
      if (!_inRange(log.date, start, end)) continue;
      inPeriod.add(log);
      for (final b in buckets) {
        if (_inRange(log.date, b.start, b.end)) b.minutes += log.minutes;
      }
    }
    final minutes = inPeriod.fold<int>(0, (s, l) => s + l.minutes);

    // Same-length window right before this one, for the comparison line.
    final prevStart = start.subtract(end.difference(start));
    final prevMinutes = app.logs
        .where((l) => _inRange(l.date, prevStart, start))
        .fold<int>(0, (s, l) => s + l.minutes);

    final periodWord = switch (_period) {
      Period.week => 'this week',
      Period.month => 'in the last 4 weeks',
      Period.year => 'this year',
    };
    final prevWord = switch (_period) {
      Period.week => 'last week',
      Period.month => 'the 4 weeks before',
      Period.year => 'last year',
    };

    String? delta;
    Color deltaColor = LegonColors.muted;
    if (prevMinutes > 0) {
      final pct = ((minutes - prevMinutes) / prevMinutes * 100).round();
      delta = '${pct >= 0 ? '+' : ''}$pct% vs $prevWord';
      deltaColor = pct >= 0 ? LegonColors.positive : LegonColors.redText;
    } else if (minutes > 0) {
      delta = 'Nothing logged $prevWord';
    }

    final muscleCounts = {for (final m in Muscle.values) m: 0};
    for (final l in inPeriod) {
      for (final m in l.muscles) {
        muscleCounts[m] = muscleCounts[m]! + 1;
      }
    }
    final maxMuscle = muscleCounts.values.fold<int>(0, math.max);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, pad.top + 12, 20, pad.bottom + 24),
      children: [
        Text('Stats', style: display(30)),
        const SizedBox(height: 16),
        Segmented(
          labels: const ['Week', 'Month', 'Year'],
          index: _period.index,
          onChanged: (i) => setState(() => _period = Period.values[i]),
        ),
        const SizedBox(height: 16),
        const LegionArt(asset: LegionArt.legacy, height: 100),
        const SizedBox(height: 12),
        LegonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minutes in the line $periodWord',
                style: body(13, color: LegonColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                '$minutes',
                style: display(
                  36,
                  weight: FontWeight.w700,
                  color: LegonColors.goldBright,
                ),
              ),
              if (delta != null)
                Text(delta, style: body(13, color: deltaColor)),
              const SizedBox(height: 14),
              _BarChart(
                key: ValueKey(_period),
                buckets: buckets,
                highlight: _currentBucket(buckets, now),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            StatTile(
              label: 'Workouts',
              value: '${inPeriod.length}',
              sub: '${inPeriod.where((l) => l.counts).length} counted for rank',
            ),
            StatTile(
              label: 'Streak',
              value: '${app.currentStreak} d',
              sub: 'best ${app.bestStreak}',
            ),
            StatTile(
              label: 'Reps',
              value: _thousands(inPeriod.fold<int>(0, (s, l) => s + l.reps)),
              sub: periodWord,
            ),
            StatTile(
              label: 'Exercises done',
              value: '${inPeriod.fold<int>(0, (s, l) => s + l.exercisesDone)}',
              sub: periodWord,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LegonCard(
          radius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Load by muscle group',
                style: body(14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Exercises completed per group, relative to the most-trained one',
                style: body(12, color: LegonColors.muted),
              ),
              const SizedBox(height: 12),
              if (maxMuscle == 0)
                Text(
                  'No workouts in this period yet.',
                  style: body(14, color: LegonColors.muted),
                )
              else
                for (final m in Muscle.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            m.label,
                            style: body(13, color: LegonColors.muted),
                          ),
                        ),
                        Expanded(
                          child: ProgressBar(
                            value: muscleCounts[m]! / maxMuscle,
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${muscleCounts[m]}',
                            textAlign: TextAlign.right,
                            style: body(13),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  int _currentBucket(List<_Bucket> buckets, DateTime now) {
    for (var i = 0; i < buckets.length; i++) {
      if (_inRange(now, buckets[i].start, buckets[i].end)) return i;
    }
    return -1;
  }

  String _thousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({super.key, required this.buckets, required this.highlight});

  final List<_Bucket> buckets;
  final int highlight;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 112.0;
    final maxMinutes = buckets.fold<int>(0, (m, b) => math.max(m, b.minutes));
    final summary = [
      for (final b in buckets) '${b.label} ${b.minutes}',
    ].join(', ');
    return Semantics(
      label: 'Minutes per period: $summary',
      child: ExcludeSemantics(
        child: SizedBox(
          height: maxHeight + 22,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Motion.of(context, const Duration(milliseconds: 420)),
            curve: Motion.easeOut,
            builder: (context, t, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: buckets.length > 8 ? 3 : 5,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.diagonal3Values(1, t, 1),
                            child: Container(
                              height: maxMinutes == 0
                                  ? 4.0
                                  : math.max(
                                      4.0,
                                      buckets[i].minutes /
                                          maxMinutes *
                                          maxHeight,
                                    ),
                              decoration: BoxDecoration(
                                color: buckets[i].minutes == 0
                                    ? LegonColors.track
                                    : (i == highlight
                                          ? LegonColors.redBright
                                          : LegonColors.gold),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            buckets[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: body(11, color: LegonColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
