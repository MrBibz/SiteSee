import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SiteSee Design Tokens
// Single source of truth — import this wherever you need colours or typography.
// ─────────────────────────────────────────────────────────────────────────────

abstract class SiteColors {
  // Backgrounds
  static const bg        = Color(0xFF0D1117);
  static const surface   = Color(0xFF161B22);
  static const surface2  = Color(0xFF1C2230);

  // Borders
  static const border    = Color(0x14FFFFFF); // 8 % white

  // Accent
  static const amber     = Color(0xFFE8A020);
  static const amberDim  = Color(0x1FE8A020); // 12 % amber

  // Semantic
  static const blue      = Color(0xFF58A6FF);
  static const green     = Color(0xFF3FB950);
  static const red       = Color(0xFFF85149);
  static const purple    = Color(0xFFA5A0F7);
  static const muted     = Color(0xFF7D8590);
  static const text      = Color(0xFFE6EDF3);

  // Visibility tints
  static const publicBg    = Color(0x1458A6FF);
  static const publicBdr   = Color(0x3358A6FF);
  static const hiddenBg    = Color(0x14E8A020);
  static const hiddenBdr   = Color(0x33E8A020);
  static const privateBg   = Color(0x14A5A0F7);
  static const privateBdr  = Color(0x33A5A0F7);
}

abstract class SiteFonts {
  // Use Google Fonts package:
  //   google_fonts: ^6.0.0
  // Then replace TextStyle() calls below with:
  //   GoogleFonts.syne(...)  and  GoogleFonts.dmMono(...)
  //
  // For now they fall back to the system sans-serif so the app compiles
  // without the package dependency.
  static TextStyle heading({double size = 18, FontWeight weight = FontWeight.w700}) =>
      TextStyle(fontSize: size, fontWeight: weight, letterSpacing: -0.3, color: SiteColors.text,
          fontFamily: 'Syne');

  static TextStyle mono({double size = 12, Color color = SiteColors.muted}) =>
      TextStyle(fontSize: size, fontFamily: 'DM Mono', color: color, letterSpacing: 0.02);

  static TextStyle body({double size = 14, Color color = SiteColors.text}) =>
      TextStyle(fontSize: size, fontFamily: 'DM Sans', color: color);
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeData — pass to MaterialApp
// ─────────────────────────────────────────────────────────────────────────────

ThemeData buildSiteSeeTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: SiteColors.bg,
    colorScheme: const ColorScheme.dark(
      surface:          SiteColors.surface,
      primary:          SiteColors.amber,
      onPrimary:        Color(0xFF0D1117),
      secondary:        SiteColors.blue,
      onSecondary:      Color(0xFF0D1117),
      error:            SiteColors.red,
      onSurface:        SiteColors.text,
      onSurfaceVariant: SiteColors.muted,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor:  SiteColors.bg,
      foregroundColor:  SiteColors.text,
      elevation:        0,
      centerTitle:      true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: SiteColors.text,
        fontFamily: 'Syne',
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: SiteColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SiteColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SiteColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SiteColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SiteColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: SiteColors.amber, width: 1),
      ),
      labelStyle: const TextStyle(fontSize: 11, fontFamily: 'DM Mono', color: SiteColors.muted),
      hintStyle:  const TextStyle(fontSize: 13, color: SiteColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    dividerTheme: const DividerThemeData(
      color: SiteColors.border,
      thickness: 0.5,
      space: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SiteColors.amber,
        foregroundColor: Color(0xFF0D1117),
        textStyle: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Syne',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SiteColors.amber,
      foregroundColor: Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}