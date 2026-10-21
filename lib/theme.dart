import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:google_fonts/google_fonts.dart';

/// Palette: dark bronze ground, gold for progress, legion red for actions.
class LegonColors {
  static const ground = Color(0xFF0D0A08);
  static const surface = Color(0xFF1A1410);
  static const surface2 = Color(0xFF241B14);
  static const raised = Color(0xFF2A1E16);
  static const track = Color(0xFF2E241B);
  static const gold = Color(0xFFD4A95A);
  static const goldBright = Color(0xFFE8C886);
  static const red = Color(0xFFA8302A);
  static const redBright = Color(0xFFC23A2E);
  static const redText = Color(0xFFE07A6E);
  static const ivory = Color(0xFFF4E9D4);
  static const muted = Color(0xFFB3A089);
  static const dim = Color(0xFF8A7A66);
  static const tabIdle = Color(0xFF9C8A73);
  static const line = Color(0x2ED4A95A);
  static const lineStrong = Color(0x73D4A95A);
  static const positive = Color(0xFF8FBF7A);
}

/// Motion tokens, taken from the animate skill's tables.
class Motion {
  /// Strong ease-out for UI that enters or exits.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// iOS-like drawer / sheet curve.
  static const easeDrawer = Cubic(0.32, 0.72, 0, 1);

  static const press = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 320);
  static const sheetOut = Duration(milliseconds: 280);

  /// True when the user asked the system to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

TextStyle display(
  double size, {
  Color color = LegonColors.ivory,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0,
}) {
  return GoogleFonts.cinzel(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.12,
    // Large display text gets slightly negative tracking.
    letterSpacing: letterSpacing != 0 ? letterSpacing : (size >= 24 ? -0.01 * size : 0),
  );
}

TextStyle body(double size, {Color color = LegonColors.ivory, FontWeight weight = FontWeight.w400, double? height}) {
  return TextStyle(fontSize: size, color: color, fontWeight: weight, height: height);
}

TextStyle eyebrow({Color color = LegonColors.muted}) {
  return TextStyle(fontSize: 12, color: color, letterSpacing: 0.7, fontWeight: FontWeight.w600);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return base.copyWith(
    scaffoldBackgroundColor: LegonColors.ground,
    colorScheme: const ColorScheme.dark(
      primary: LegonColors.gold,
      onPrimary: LegonColors.surface,
      secondary: LegonColors.red,
      onSecondary: LegonColors.ivory,
      surface: LegonColors.surface,
      onSurface: LegonColors.ivory,
      error: LegonColors.redBright,
    ),
    textTheme: base.textTheme.apply(bodyColor: LegonColors.ivory, displayColor: LegonColors.ivory),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: LegonColors.gold,
      selectionColor: Color(0x55D4A95A),
      selectionHandleColor: LegonColors.gold,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LegonColors.surface,
      hintStyle: const TextStyle(color: LegonColors.dim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(LegonColors.line),
      enabledBorder: border(LegonColors.line),
      focusedBorder: border(LegonColors.gold, 1.5),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: LegonColors.gold,
      inactiveTrackColor: LegonColors.track,
      thumbColor: LegonColors.goldBright,
      overlayColor: Color(0x22D4A95A),
      valueIndicatorColor: LegonColors.surface2,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LegonColors.surface2,
      contentTextStyle: TextStyle(color: LegonColors.ivory, fontSize: 15),
      actionTextColor: LegonColors.goldBright,
      behavior: SnackBarBehavior.floating,
    ),
    // iOS-style push everywhere: it tracks the finger and can be swiped back.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
