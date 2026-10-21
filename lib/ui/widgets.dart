import 'package:flutter/material.dart';

import '../theme.dart';

/// Tap target that shrinks slightly the moment a finger lands on it
/// (feedback on pointer-down, not on release), then commits on tap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.selected,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool? selected;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduced = Motion.reduced(context);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: Listener(
        onPointerDown: enabled ? (_) => _set(true) : null,
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapCancel: () => _set(false),
          child: AnimatedScale(
            scale: _down && !reduced ? widget.scale : 1,
            duration: Motion.press,
            curve: Motion.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class LegonCard extends StatelessWidget {
  const LegonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = LegonColors.surface,
    this.borderColor,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 8, this.color = LegonColors.gold});

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: LegonColors.track),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0).toDouble()),
              duration: Motion.of(context, const Duration(milliseconds: 400)),
              curve: Motion.easeOut,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height / 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: display(18), semanticsLabel: title)),
        if (trailing != null) Text(trailing!, style: body(13, color: LegonColors.muted)),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap, this.icon, this.height = 50});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? LegonColors.red : LegonColors.track,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: body(17, weight: FontWeight.w600, color: enabled ? LegonColors.ivory : LegonColors.dim)),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: enabled ? LegonColors.ivory : LegonColors.dim),
            ],
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onTap, this.icon, this.height = 44});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LegonColors.lineStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: LegonColors.goldBright),
              const SizedBox(width: 6),
            ],
            Text(label, style: body(14, weight: FontWeight.w600, color: LegonColors.goldBright)),
          ],
        ),
      ),
    );
  }
}

/// Pill used for single and multiple choice.
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap, this.filled = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Filled gold when selected (single choice) vs outlined (multi choice).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? (filled ? LegonColors.gold : LegonColors.raised) : Colors.transparent;
    final fg = selected ? (filled ? LegonColors.surface : LegonColors.goldBright) : LegonColors.muted;
    return Pressable(
      onTap: onTap,
      selected: selected,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        curve: Motion.easeOut,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? LegonColors.gold : LegonColors.line),
        ),
        child: Text(label, style: body(14, weight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

/// Segmented control with a sliding indicator.
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: LegonColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.easeOut,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFF3A2D20), borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: body(14,
                              weight: i == index ? FontWeight.w600 : FontWeight.w400,
                              color: i == index ? LegonColors.ivory : LegonColors.muted),
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

class LegonSwitch extends StatelessWidget {
  const LegonSwitch({super.key, required this.value, this.width = 50, this.height = 30});

  final bool value;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.fast);
    return AnimatedContainer(
      duration: d,
      curve: Motion.easeOut,
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? LegonColors.red : const Color(0xFF3A2F25),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: AnimatedAlign(
        duration: d,
        curve: Motion.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: height - 6,
          height: height - 6,
          decoration: const BoxDecoration(color: LegonColors.ivory, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Round check mark used on exercise rows.
class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.checked, this.size = 26});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.fast);
    return AnimatedContainer(
      duration: d,
      curve: Motion.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? LegonColors.gold : Colors.transparent,
        border: Border.all(color: checked ? LegonColors.gold : const Color(0xFF5C4E40), width: 2),
      ),
      child: AnimatedScale(
        duration: d,
        curve: Motion.easeOut,
        scale: checked ? 1 : 0.6,
        child: AnimatedOpacity(
          duration: d,
          opacity: checked ? 1 : 0,
          child: Icon(Icons.check_rounded, size: size * 0.6, color: LegonColors.surface),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.sub});

  final String value;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return LegonCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: body(13, color: LegonColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: display(22, weight: FontWeight.w700, color: LegonColors.goldBright)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, style: body(12, color: LegonColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// Small rounded "back" control matching the iOS pattern: chevron + previous title.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      semanticLabel: 'Back to $label',
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded, color: LegonColors.goldBright, size: 28),
            Text(label, style: body(17, color: LegonColors.goldBright)),
          ],
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String text, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(text),
    action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ));
}
