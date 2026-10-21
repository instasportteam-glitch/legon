import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/program.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../ui/legion_art.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, required this.level});

  final int level;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final DateTime _start = DateTime.now();
  final Set<String> _warm = {};
  final Set<String> _done = {};

  void _toggle(Set<String> set, String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!set.remove(id)) set.add(id);
    });
  }

  Future<void> _finish(Level level, List<CustomExercise> additions) async {
    final exercises = level.exercises;
    final strengthDone = exercises.where((e) => _done.contains(e.id)).length;
    final customDone = additions.where((c) => _done.contains(c.id)).toList();
    if (strengthDone == 0 && customDone.isEmpty && _warm.isEmpty) {
      showMessage(context, 'Check off at least one exercise first.');
      return;
    }

    final result = await showModalBottomSheet<({int effort, String note})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: LegonColors.surface,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(
        duration: Motion.sheet,
        reverseDuration: Motion.sheetOut,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _FinishSheet(strengthDone: strengthDone, total: exercises.length),
    );
    if (result == null || !mounted) return;

    final app = AppScope.read(context);
    final doneDefs = exercises.where((e) => _done.contains(e.id)).toList();
    final reps =
        doneDefs.fold<int>(0, (s, e) => s + e.doseFor(level.number).reps) +
        customDone.fold<int>(0, (s, c) => s + c.dose.reps);
    final now = DateTime.now();
    final log = WorkoutLog(
      id: now.microsecondsSinceEpoch.toString(),
      date: now,
      level: level.number,
      levelName: level.name,
      strengthDone: strengthDone,
      strengthTotal: exercises.length,
      customDone: customDone.length,
      warmupDone: _warm.length,
      minutes: math.max(1, now.difference(_start).inMinutes),
      effort: result.effort,
      note: result.note.trim(),
      reps: reps,
      muscles: [
        for (final e in doneDefs) ...e.muscles,
        for (final c in customDone) ...c.muscles,
      ],
      completed: _done.toList(),
    );

    HapticFeedback.mediumImpact();
    final change = app.logWorkout(log);
    final navigator = Navigator.of(context);
    app.setTab(1);
    navigator.pop();

    if (change.after > change.before) {
      await showRankUp(navigator.context, ranks[change.after]);
    } else if (!log.counts) {
      showMessage(
        navigator.context,
        'Logged. Complete $minExercisesForCredit of ${exercises.length} exercises for it to count toward your rank.',
      );
    } else {
      final next = app.nextRank;
      showMessage(
        navigator.context,
        next == null
            ? 'Logged. Ave, ${app.rank.name}!'
            : 'Logged. ${next.threshold - app.creditedWorkouts} more to ${next.name}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = levels[widget.level - 1];
    final exercises = level.exercises;
    final additions = app.todaysAdditions;
    final strengthDone = exercises.where((e) => _done.contains(e.id)).length;
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, pad.top + 4, 20, pad.bottom + 170),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BackLink(label: 'Legion'),
              ),
              const SizedBox(height: 8),
              Text(
                'RANK ${roman(level.number)} · ${ranks[level.number - 1].name.toUpperCase()}',
                style: eyebrow(color: LegonColors.redText),
              ),
              const SizedBox(height: 6),
              Text(level.name, style: display(30)),
              const SizedBox(height: 6),
              Text(
                level.description,
                style: body(15, color: LegonColors.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value:
                          '${warmups.length + exercises.length + additions.length}',
                      label: 'Exercises',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      value: '${level.estimatedMinutes}',
                      label: 'Minutes',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      value: roman(level.number),
                      label: 'Difficulty',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Warm-up · Exercitatio',
                trailing: 'tap to check off',
              ),
              const SizedBox(height: 10),
              LegonCard(
                padding: EdgeInsets.zero,
                radius: 18,
                child: Column(
                  children: [
                    for (var i = 0; i < warmups.length; i++)
                      _WarmRow(
                        name: warmups[i].name,
                        dose: warmups[i].doseFor(level.number).label,
                        done: _warm.contains(warmups[i].id),
                        last: i == warmups.length - 1,
                        onTap: () => _toggle(_warm, warmups[i].id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const LegionArt(asset: LegionArt.training, height: 190),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Strength complex'),
              const SizedBox(height: 10),
              for (var i = 0; i < exercises.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ExerciseTile(
                    badge: roman(i + 1),
                    name: exercises[i].name,
                    note: exercises[i].note,
                    dose: exercises[i].doseFor(level.number).label,
                    done: _done.contains(exercises[i].id),
                    onTap: () => _toggle(_done, exercises[i].id),
                  ),
                ),
              if (additions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'Your additions'),
                const SizedBox(height: 10),
                for (final c in additions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExerciseTile(
                      badge: '+',
                      name: c.name,
                      note: c.description.isEmpty
                          ? (c.isWarmup ? 'Your warm-up' : 'Your exercise')
                          : c.description.split('\n').first,
                      dose: c.dose.label,
                      done: _done.contains(c.id),
                      onTap: () => _toggle(_done, c.id),
                    ),
                  ),
              ],
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FinishBar(
              done: strengthDone,
              total: exercises.length,
              onFinish: () => _finish(level, additions),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmRow extends StatelessWidget {
  const _WarmRow({
    required this.name,
    required this.dose,
    required this.done,
    required this.last,
    required this.onTap,
  });

  final String name;
  final String dose;
  final bool done;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: done,
      scale: 0.99,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0x1AD4A95A))),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: body(15))),
            Text(dose, style: body(14, color: LegonColors.muted)),
            const SizedBox(width: 12),
            CheckDot(checked: done, size: 22),
          ],
        ),
      ),
    );
  }
}

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.badge,
    required this.name,
    required this.note,
    required this.dose,
    required this.done,
    required this.onTap,
  });

  final String badge;
  final String name;
  final String note;
  final String dose;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: done,
      semanticLabel: '$name, $dose, ${done ? 'done' : 'not done'}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          curve: Motion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: done ? const Color(0xFF1F1812) : LegonColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? const Color(0x73D4A95A) : const Color(0x1FD4A95A),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LegonColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: display(
                    14,
                    weight: FontWeight.w700,
                    color: LegonColors.goldBright,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: body(16, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: body(13, color: LegonColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(dose, style: body(14, color: LegonColors.goldBright)),
              const SizedBox(width: 12),
              CheckDot(checked: done),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishBar extends StatelessWidget {
  const _FinishBar({
    required this.done,
    required this.total,
    required this.onFinish,
  });

  final int done;
  final int total;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, math.max(16, bottom + 8)),
          decoration: const BoxDecoration(
            color: Color(0xD1140F0C),
            border: Border(top: BorderSide(color: LegonColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Completed',
                      style: body(14, color: LegonColors.muted),
                    ),
                  ),
                  Text(
                    '$done / $total',
                    style: body(14, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ProgressBar(value: total == 0 ? 0 : done / total, height: 6),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Finish and log to journal',
                onTap: onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishSheet extends StatefulWidget {
  const _FinishSheet({required this.strengthDone, required this.total});

  final int strengthDone;
  final int total;

  @override
  State<_FinishSheet> createState() => _FinishSheetState();
}

class _FinishSheetState extends State<_FinishSheet> {
  double _effort = 7;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = widget.strengthDone >= minExercisesForCredit;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log this workout', style: display(22)),
          const SizedBox(height: 6),
          Text(
            counts
                ? '${widget.strengthDone} of ${widget.total} exercises · counts toward your rank'
                : '${widget.strengthDone} of ${widget.total} exercises · $minExercisesForCredit needed to count toward your rank',
            style: body(
              14,
              color: counts ? LegonColors.positive : LegonColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Effort', style: body(15, weight: FontWeight.w600)),
              ),
              Text(
                '${_effort.round()} / 10',
                style: body(15, color: LegonColors.goldBright),
              ),
            ],
          ),
          Slider(
            value: _effort,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_effort.round()}',
            onChanged: (v) {
              if (v.round() != _effort.round()) HapticFeedback.selectionClick();
              setState(() => _effort = v);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Notes: how did it feel? Anything to remember?',
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Save to journal',
            onTap: () => Navigator.of(
              context,
            ).pop((effort: _effort.round(), note: _note.text)),
          ),
        ],
      ),
    );
  }
}

/// Rank-up is rare, so it gets the one celebratory moment in the app.
Future<void> showRankUp(BuildContext context, Rank rank) {
  HapticFeedback.heavyImpact();
  final reduced = Motion.reduced(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xB3000000),
    transitionDuration: reduced
        ? const Duration(milliseconds: 200)
        : const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.easeOut);
      return FadeTransition(
        opacity: curved,
        child: reduced
            ? child
            : ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
                child: child,
              ),
      );
    },
    pageBuilder: (context, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Material(
          color: LegonColors.surface,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: LegonColors.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: LegonColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.military_tech_rounded,
                    color: LegonColors.gold,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text('NEW RANK', style: eyebrow(color: LegonColors.redText)),
                const SizedBox(height: 6),
                Text(
                  rank.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: display(
                    30,
                    weight: FontWeight.w700,
                    color: LegonColors.goldBright,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rank.meaning,
                  textAlign: TextAlign.center,
                  style: body(15, color: LegonColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  'A new complex is unlocked.',
                  textAlign: TextAlign.center,
                  style: body(14, color: LegonColors.muted),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Ave!',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
