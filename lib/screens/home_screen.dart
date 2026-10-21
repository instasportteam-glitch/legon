import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/program.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/format.dart';
import '../ui/widgets.dart';
import '../ui/legion_art.dart';
import 'workout_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final level = levels[app.currentLevel - 1];
    final pad = MediaQuery.paddingOf(context);
    final now = DateTime.now();
    final streak = app.currentStreak;
    final subtitle = streak > 0
        ? '${weekdayLong[now.weekday - 1]} · $streak-day streak'
        : '${weekdayLong[now.weekday - 1]} · start your streak today';

    return ListView(
      padding: EdgeInsets.fromLTRB(20, pad.top + 12, 20, pad.bottom + 24),
      children: [
        _Wordmark(on: app.legOn, onToggle: app.toggleLegOn),
        const SizedBox(height: 18),
        Text('Ave, ${app.displayName}', style: display(32)),
        const SizedBox(height: 4),
        Text(subtitle, style: body(15, color: LegonColors.muted)),
        const SizedBox(height: 16),
        _RankCard(app: app),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.fast),
          switchInCurve: Motion.easeOut,
          switchOutCurve: Motion.easeOut,
          child: app.legOn
              ? _OrdersCard(
                  key: ValueKey('on-${level.number}'),
                  level: level,
                  additions: app.todaysAdditions.length,
                )
              : const _OffDutyCard(key: ValueKey('off')),
        ),
        const SizedBox(height: 26),
        const SectionHeader(title: 'Legion ranks', trailing: '10 complexes'),
        const SizedBox(height: 10),
        _LevelGrid(app: app),
        const SizedBox(height: 12),
        Text(
          'Each rank unlocks the next complex. A workout counts toward your rank when '
          'at least $minExercisesForCredit of its 10 exercises are done.',
          style: body(13, color: LegonColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

/// "LEG [switch] ON": flip it off for a rest day.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.on, required this.onToggle});

  final bool on;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final word = display(
      20,
      weight: FontWeight.w700,
      color: LegonColors.gold,
      letterSpacing: 1.6,
    );
    return Row(
      children: [
        Text('LEG', style: word),
        const SizedBox(width: 10),
        Pressable(
          onTap: onToggle,
          semanticLabel: on
              ? 'On duty. Double tap for a rest day'
              : 'Rest day. Double tap to go on duty',
          child: LegonSwitch(value: on, width: 44, height: 26),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.fast),
          child: Text(on ? 'ON' : 'OFF', key: ValueKey(on), style: word),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final next = app.nextRank;
    final credited = app.creditedWorkouts;
    return LegionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: LegonColors.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x59D4A95A)),
                ),
                child: const Icon(
                  Icons.military_tech_outlined,
                  color: LegonColors.gold,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR RANK', style: eyebrow()),
                    const SizedBox(height: 2),
                    Text(
                      app.rank.name.toUpperCase(),
                      style: display(
                        24,
                        weight: FontWeight.w700,
                        color: LegonColors.goldBright,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${roman(app.rankIndex + 1)} / X',
                style: display(15, color: LegonColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: app.rankProgress),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  next == null
                      ? '$credited workouts'
                      : '$credited of ${next.threshold} workouts',
                  style: body(13, color: LegonColors.muted),
                ),
              ),
              Text(
                next == null
                    ? 'Highest rank reached'
                    : '${next.threshold - credited} to ${next.name}',
                style: body(13, color: LegonColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersCard extends StatelessWidget {
  const _OrdersCard({super.key, required this.level, required this.additions});

  final Level level;
  final int additions;

  @override
  Widget build(BuildContext context) {
    final chips = [
      'Warm-up · ${warmups.length}',
      'Strength · ${level.exercises.length}',
      if (additions > 0) 'Yours · $additions',
      '≈ ${level.estimatedMinutes} min',
    ];
    return LegonCard(
      color: LegonColors.surface2,
      borderColor: const Color(0x66C23A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LegionArt(asset: LegionArt.training, height: 142),
          const SizedBox(height: 14),
          Text("TODAY'S ORDERS", style: eyebrow(color: LegonColors.redText)),
          const SizedBox(height: 4),
          Text(
            'Complex ${roman(level.number)} · ${level.name}',
            style: display(22),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: LegonColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(c, style: body(13)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Fall in',
            icon: Icons.arrow_forward_rounded,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => WorkoutScreen(level: level.number),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffDutyCard extends StatelessWidget {
  const _OffDutyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LegonCard(
      color: LegonColors.surface,
      borderColor: LegonColors.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OFF DUTY', style: eyebrow()),
          const SizedBox(height: 4),
          Text('Rest day', style: display(22)),
          const SizedBox(height: 8),
          Text(
            'Even legionaries rested between marches. Walk, stretch and sleep well. '
            'Flip the switch back on when you are ready to fall in.',
            style: body(14, color: LegonColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _LevelGrid extends StatelessWidget {
  const _LevelGrid({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: levels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 50,
      ),
      itemBuilder: (context, i) {
        final n = i + 1;
        final locked = n > app.unlockedLevel;
        final current = n == app.currentLevel;
        final passed = n < app.unlockedLevel;

        final Color bg;
        final Color fg;
        Border? border;
        if (current) {
          bg = LegonColors.surface2;
          fg = LegonColors.ivory;
          border = Border.all(color: LegonColors.redBright, width: 2);
        } else if (passed) {
          bg = LegonColors.gold;
          fg = LegonColors.surface;
        } else if (!locked) {
          bg = LegonColors.surface2;
          fg = LegonColors.goldBright;
          border = Border.all(color: LegonColors.lineStrong);
        } else {
          bg = const Color(0xFF161210);
          fg = LegonColors.dim;
          border = Border.all(color: const Color(0x24D4A95A));
        }

        return Pressable(
          selected: current,
          semanticLabel: locked
              ? 'Complex ${roman(n)}, locked. Reach ${ranks[i].name} to unlock'
              : 'Complex ${roman(n)}, ${levels[i].name}${current ? ', selected' : ''}',
          onTap: () {
            if (locked) {
              showMessage(
                context,
                'Reach the rank of ${ranks[i].name} to unlock Complex ${roman(n)}.',
              );
            } else {
              app.selectLevel(n);
            }
          },
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.fast),
              curve: Motion.easeOut,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: border,
              ),
              alignment: Alignment.center,
              child: locked
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(roman(n), style: display(14, color: fg)),
                        const SizedBox(width: 3),
                        Icon(Icons.lock_outline_rounded, size: 12, color: fg),
                      ],
                    )
                  : Text(
                      roman(n),
                      style: display(17, weight: FontWeight.w700, color: fg),
                    ),
            ),
          ),
        );
      },
    );
  }
}
