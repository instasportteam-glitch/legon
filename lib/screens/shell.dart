import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _TabSpec('Legion', Icons.shield_outlined, Icons.shield),
  _TabSpec('Journal', Icons.menu_book_outlined, Icons.menu_book),
  _TabSpec('Stats', Icons.bar_chart_rounded, Icons.bar_chart_rounded),
  _TabSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

/// Root with the four tabs. Tabs are switched tens of times a day, so the
/// change is a short cross-fade only — no movement.
class Shell extends StatelessWidget {
  const Shell({super.key});

  Widget _page(int i) => switch (i) {
        0 => const HomeScreen(),
        1 => const JournalScreen(),
        2 => const StatsScreen(),
        _ => const ProfileScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: Motion.of(context, Motion.fast),
        switchInCurve: Motion.easeOut,
        switchOutCurve: Motion.easeOut,
        child: KeyedSubtree(key: ValueKey(app.tab), child: _page(app.tab)),
      ),
      bottomNavigationBar: _TabBar(index: app.tab, onSelect: app.setTab),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Translucent material: content scrolls underneath and stays faintly visible.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xC7140F0C),
            border: Border(top: BorderSide(color: LegonColors.line)),
          ),
          padding: EdgeInsets.only(top: 6, bottom: math.max(8, bottom), left: 8, right: 8),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: Pressable(
                    onTap: () => onSelect(i),
                    selected: i == index,
                    semanticLabel: _tabs[i].label,
                    child: SizedBox(
                      height: 52,
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              i == index ? _tabs[i].activeIcon : _tabs[i].icon,
                              size: 24,
                              color: i == index ? LegonColors.goldBright : LegonColors.tabIdle,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _tabs[i].label,
                              style: body(11,
                                  weight: FontWeight.w600,
                                  color: i == index ? LegonColors.goldBright : LegonColors.tabIdle),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
