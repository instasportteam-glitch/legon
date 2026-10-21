import 'package:flutter/material.dart';

import '../theme.dart';

/// Decorative artwork is bundled locally and never replaces accessible UI text.
class LegionArt extends StatelessWidget {
  const LegionArt({
    super.key,
    required this.asset,
    this.height = 140,
    this.alignment = Alignment.center,
    this.radius = 14,
  });

  static const commander = 'assets/art/commander.png';
  static const training = 'assets/art/training.png';
  static const legacy = 'assets/art/legacy.png';

  final String asset;
  final double height;
  final Alignment alignment;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: alignment,
          cacheWidth: 1200,
          errorBuilder: (_, _, _) =>
              const ColoredBox(color: LegonColors.surface2),
        ),
      ),
    ),
  );
}

/// The content determines the height, including when Dynamic Type is enlarged.
class LegionPanel extends StatelessWidget {
  const LegionPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            LegionArt.commander,
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
            cacheWidth: 1200,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: LegonColors.surface2),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .30),
                  LegonColors.ground.withValues(alpha: .95),
                ],
              ),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 228),
          padding: const EdgeInsets.fromLTRB(18, 80, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LegonColors.gold.withValues(alpha: .35)),
          ),
          child: child,
        ),
      ],
    ),
  );
}
