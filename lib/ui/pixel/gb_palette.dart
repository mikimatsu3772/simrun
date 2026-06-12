import 'package:flutter/material.dart';

/// ゲームボーイ4色パレット。docs/ART_DIRECTION.md 参照。
/// この4色+透明以外は原則使わない。
abstract final class Gb {
  static const darkest = Color(0xFF0F380F);
  static const dark = Color(0xFF306230);
  static const light = Color(0xFF8BAC0F);
  static const lightest = Color(0xFF9BBC0F);
}

/// アプリ全体のGBテーマ。
ThemeData gbTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Gb.light,
    onPrimary: Gb.darkest,
    secondary: Gb.lightest,
    onSecondary: Gb.darkest,
    error: Gb.light,
    onError: Gb.darkest,
    surface: Gb.dark,
    onSurface: Gb.lightest,
    surfaceContainerHighest: Gb.dark,
    outline: Gb.light,
  );

  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: 'DotGothic16',
    scaffoldBackgroundColor: Gb.darkest,
    useMaterial3: true,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Gb.darkest,
      foregroundColor: Gb.lightest,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Gb.dark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Gb.light,
        foregroundColor: Gb.darkest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Gb.lightest,
      contentTextStyle: TextStyle(
        color: Gb.darkest,
        fontFamily: 'DotGothic16',
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Gb.light,
      linearTrackColor: Gb.darkest,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Gb.darkest,
      labelStyle: TextStyle(color: Gb.lightest, fontFamily: 'DotGothic16'),
      side: BorderSide(color: Gb.light),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Gb.light,
      inactiveTrackColor: Gb.darkest,
      thumbColor: Gb.lightest,
      valueIndicatorColor: Gb.lightest,
      valueIndicatorTextStyle: TextStyle(
        color: Gb.darkest,
        fontFamily: 'DotGothic16',
      ),
    ),
  );
}
