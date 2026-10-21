import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/program.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/format.dart';
import '../ui/widgets.dart';
import '../ui/legion_art.dart';
import 'create_exercise_screen.dart';
import 'custom_exercise_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(20, pad.top + 12, 20, pad.bottom + 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('Journal', style: display(30))),
            Pressable(
              onTap: () => showCreateExerciseSheet(context),
              semanticLabel: 'Add a custom exercise',
              child: Container(
                height: 44,
                padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                decoration: BoxDecoration(
                  color: LegonColors.red,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: LegonColors.ivory,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text('Custom', style: body(15, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const LegionArt(asset: LegionArt.legacy, height: 140),
        const SizedBox(height: 16),
        _WeekStrip(trained: app.trainedDays),
        if (app.customs.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader(
            title: 'My exercises',
            trailing: '${app.customs.length}',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: app.customs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _CustomCard(exercise: app.customs[i]),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SectionHeader(title: 'Workouts'),
        const SizedBox(height: 10),
        if (app.logs.isEmpty)
          LegonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No entries yet', style: display(17)),
                const SizedBox(height: 6),
                Text(
                  'Finish a workout and it will be logged here with your time, effort and notes.',
                  style: body(14, color: LegonColors.muted, height: 1.4),
                ),
              ],
            ),
          )
        else
          for (final log in app.logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(log.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    color: LegonColors.red,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: LegonColors.ivory,
                  ),
                ),
                onDismissed: (_) {
                  app.deleteLog(log.id);
                  showMessage(
                    context,
                    'Entry deleted',
                    actionLabel: 'Undo',
                    onAction: () => app.restoreLog(log),
                  );
                },
                child: _LogCard(log: log, currentLevel: app.currentLevel),
              ),
            ),
        if (app.logs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Swipe an entry left to delete it.',
              style: body(12, color: LegonColors.dim),
            ),
          ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.trained});

  final Set<DateTime> trained;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final monday = mondayOf(today);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];
    final count = days.where(trained.contains).length;
    return LegonCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatWeekRange(monday),
                  style: body(14, weight: FontWeight.w600),
                ),
              ),
              Text(
                '$count of 7 days',
                style: body(14, color: LegonColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Semantics(
                    label:
                        '${weekdayLong[i]} ${days[i].day}, ${trained.contains(days[i]) ? 'trained' : 'no workout'}',
                    child: ExcludeSemantics(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: days[i] == today
                              ? LegonColors.surface2
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              weekdayShort[i],
                              style: body(11, color: LegonColors.muted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${days[i].day}',
                              style: body(
                                16,
                                weight: FontWeight.w600,
                                color: days[i] == today
                                    ? LegonColors.goldBright
                                    : LegonColors.ivory,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: trained.contains(days[i])
                                    ? LegonColors.gold
                                    : const Color(0xFF3A2F25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log, required this.currentLevel});

  final WorkoutLog log;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final tagColor = log.level == currentLevel
        ? LegonColors.redText
        : LegonColors.goldBright;
    return LegonCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderColor: const Color(0x1FD4A95A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatLogDate(log.date),
                  style: body(13, color: LegonColors.muted),
                ),
              ),
              Text(
                'Complex ${roman(log.level)}',
                style: body(13, weight: FontWeight.w600, color: tagColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(log.levelName, style: display(17)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                '${log.minutes} min',
                style: body(13, color: LegonColors.goldBright),
              ),
              Text(
                '${log.strengthDone} / ${log.strengthTotal}',
                style: body(13, color: LegonColors.goldBright),
              ),
              if (log.customDone > 0)
                Text(
                  '+${log.customDone} yours',
                  style: body(13, color: LegonColors.goldBright),
                ),
              Text(
                'Effort ${log.effort}/10',
                style: body(13, color: LegonColors.goldBright),
              ),
            ],
          ),
          if (log.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              log.note,
              style: body(14, color: LegonColors.muted, height: 1.4),
            ),
          ],
          if (!log.counts) ...[
            const SizedBox(height: 8),
            Text(
              'Did not count toward rank',
              style: body(12, color: LegonColors.dim),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  const _CustomCard({required this.exercise});

  final CustomExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '${exercise.name}, ${exercise.dose.label}',
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => CustomExerciseScreen(id: exercise.id),
        ),
      ),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 132,
          child: LegonCard(
            radius: 18,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 82,
                    width: double.infinity,
                    child: exercise.hasPhotos
                        ? Image.file(
                            File(exercise.mediaPaths.first),
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            errorBuilder: (_, __, ___) =>
                                const _MediaPlaceholder(
                                  icon: Icons.image_not_supported_outlined,
                                ),
                          )
                        : _MediaPlaceholder(
                            icon: exercise.hasVideo
                                ? Icons.play_circle_outline_rounded
                                : Icons.fitness_center_rounded,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.dose.label,
                  style: body(12, color: LegonColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LegonColors.surface2,
      child: Center(child: Icon(icon, color: LegonColors.gold, size: 30)),
    );
  }
}
