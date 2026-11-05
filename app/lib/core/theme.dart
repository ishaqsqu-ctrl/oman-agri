import 'package:flutter/material.dart';

/// Bright, friendly palette: deep palm green for structure on a light leaf-white
/// background; each crop brings its own pastel (see crop_art.dart). Falaj blue
/// stays reserved for water data, date amber for heat.
abstract final class Palette {
  static const limestone = Color(0xFFF7F9F4);
  static const palm = Color(0xFF14361F);
  static const palmSoft = Color(0xFFDDEBDF);
  static const falaj = Color(0xFF0B6E7F);
  static const falajSoft = Color(0xFFD5ECEF);
  static const dates = Color(0xFFA8711A);
  static const ink = Color(0xFF16231B);
  static const line = Color(0xFFD5DDD6);

  static const darkBg = Color(0xFF101813);
  static const darkSurface = Color(0xFF18231C);
  static const darkPalm = Color(0xFF8CC7A0);
  static const darkFalaj = Color(0xFF6FC6D3);
  static const darkDates = Color(0xFFE0B05E);
}

/// Headings: Kufi (the lettering of Omani signage). Body: Naskh (easier to read).
const headingFont = 'NotoKufiArabic';
const bodyFont = 'NotoNaskhArabic';

/// Kept for callers that name the app's Arabic family.
const arabicFontFamily = headingFont;

/// Water and heat accents, outside the Material scheme so they stay meaningful.
@immutable
class DataColors extends ThemeExtension<DataColors> {
  const DataColors({required this.water, required this.waterSoft, required this.heat});

  final Color water;
  final Color waterSoft;
  final Color heat;

  static DataColors of(BuildContext context) =>
      Theme.of(context).extension<DataColors>()!;

  @override
  DataColors copyWith({Color? water, Color? waterSoft, Color? heat}) => DataColors(
      water: water ?? this.water,
      waterSoft: waterSoft ?? this.waterSoft,
      heat: heat ?? this.heat);

  @override
  DataColors lerp(DataColors? other, double t) => other == null
      ? this
      : DataColors(
          water: Color.lerp(water, other.water, t)!,
          waterSoft: Color.lerp(waterSoft, other.waterSoft, t)!,
          heat: Color.lerp(heat, other.heat, t)!);
}

TextStyle _k(double size, double weight, {double height = 1.35}) => TextStyle(
    fontFamily: headingFont,
    fontSize: size,
    height: height,
    fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', weight)]);

TextStyle _n(double size, double weight, {double height = 1.6}) => TextStyle(
    fontFamily: bodyFont,
    fontSize: size,
    height: height,
    fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
    fontVariations: [FontVariation('wght', weight)]);

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme = dark
      ? const ColorScheme.dark(
          primary: Palette.darkPalm,
          onPrimary: Palette.darkBg,
          primaryContainer: Color(0xFF234A33),
          onPrimaryContainer: Color(0xFFD7EBDD),
          secondary: Palette.darkFalaj,
          onSecondary: Palette.darkBg,
          tertiary: Palette.darkDates,
          tertiaryContainer: Color(0xFF4A3712),
          onTertiaryContainer: Color(0xFFF3DDB4),
          surface: Palette.darkSurface,
          onSurface: Color(0xFFE4EBE5),
          surfaceContainerHighest: Color(0xFF223028),
          outline: Color(0xFF51625A),
          outlineVariant: Color(0xFF34443B),
        )
      : const ColorScheme.light(
          primary: Palette.palm,
          onPrimary: Colors.white,
          primaryContainer: Palette.palmSoft,
          onPrimaryContainer: Palette.ink,
          secondary: Palette.falaj,
          onSecondary: Colors.white,
          tertiary: Palette.dates,
          tertiaryContainer: Color(0xFFF4E4C8),
          onTertiaryContainer: Color(0xFF3D2A07),
          surface: Colors.white,
          onSurface: Palette.ink,
          surfaceContainerHighest: Color(0xFFE6EBE6),
          outline: Color(0xFF8A988E),
          outlineVariant: Palette.line,
        );
  final ink = scheme.onSurface;
  final text = TextTheme(
    displaySmall: _k(30, 700, height: 1.25),
    headlineMedium: _k(26, 700, height: 1.3),
    headlineSmall: _k(22, 700, height: 1.3),
    titleLarge: _k(18, 650),
    titleMedium: _k(16, 600),
    titleSmall: _k(14, 600),
    labelLarge: _k(14, 600),
    labelMedium: _k(12.5, 550),
    labelSmall: _k(11.5, 500),
    bodyLarge: _n(17, 450),
    bodyMedium: _n(15.5, 450),
    bodySmall: _n(13.5, 450),
  ).apply(bodyColor: ink, displayColor: ink);
  final bg = dark ? Palette.darkBg : Palette.limestone;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: bodyFont,
    textTheme: text,
    scaffoldBackgroundColor: bg,
    splashFactory: InkRipple.splashFactory,
    extensions: [
      dark
          ? const DataColors(
              water: Palette.darkFalaj, waterSoft: Color(0xFF173A40), heat: Palette.darkDates)
          : const DataColors(
              water: Palette.falaj, waterSoft: Palette.falajSoft, heat: Palette.dates),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _k(18, 650).copyWith(color: ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? Palette.darkSurface : Colors.white,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(_k(12, 550).copyWith(color: ink)),
    ),
    chipTheme: ChipThemeData(
      labelStyle: _k(13.5, 550).copyWith(color: ink),
      secondaryLabelStyle: _k(13.5, 600).copyWith(color: scheme.onPrimary),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      backgroundColor: dark ? Palette.darkSurface : Colors.white,
      selectedColor: scheme.primary,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? Palette.darkSurface : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.secondary, width: 2)),
      hintStyle: _n(15.5, 400).copyWith(color: scheme.outline),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? Palette.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
  );
}

/// Soft card shadow used by tiles and sections.
List<BoxShadow> softShadow(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const []
        : [BoxShadow(color: Palette.palm.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4))];
