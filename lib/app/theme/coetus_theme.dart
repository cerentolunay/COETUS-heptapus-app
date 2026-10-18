import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'coetus_tokens.dart';

ThemeData coetusTheme({
  bool useGoogleFonts = true,
  String? fallbackFontFamily,
}) {
  final base = ThemeData.light(useMaterial3: true);
  TextStyle font(TextStyle style, {bool heading = false}) => !useGoogleFonts
      ? style.copyWith(fontFamily: fallbackFontFamily)
      : heading
      ? GoogleFonts.plusJakartaSans(textStyle: style)
      : GoogleFonts.dmSans(textStyle: style);
  TextStyle head(double size, FontWeight weight, {double spacing = -.4}) =>
      font(
        TextStyle(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          height: 1.2,
          color: CoetusColors.navyInk,
        ),
        heading: true,
      );
  TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = CoetusColors.body,
  }) => font(
    TextStyle(fontSize: size, fontWeight: weight, height: 1.55, color: color),
  );
  final text = TextTheme(
    displaySmall: head(36, FontWeight.w800, spacing: -1.2),
    headlineMedium: head(28, FontWeight.w800, spacing: -.8),
    headlineSmall: head(23, FontWeight.w800),
    titleLarge: head(18, FontWeight.w700),
    titleMedium: head(15, FontWeight.w700, spacing: 0),
    titleSmall: head(13, FontWeight.w600, spacing: 0),
    bodyLarge: body(15),
    bodyMedium: body(13),
    bodySmall: body(12, color: CoetusColors.muted),
    labelLarge: head(15, FontWeight.w700, spacing: 0),
    labelMedium: body(12, weight: FontWeight.w600),
    labelSmall: body(11, weight: FontWeight.w700),
  );
  final scheme = ColorScheme.fromSeed(seedColor: CoetusPalette.purple).copyWith(
    primary: CoetusPalette.purple,
    onPrimary: CoetusPalette.cream,
    primaryContainer: CoetusPalette.lime,
    onPrimaryContainer: CoetusPalette.purple,
    secondary: CoetusPalette.red,
    onSecondary: CoetusPalette.purpleInk,
    secondaryContainer: CoetusPalette.softLavender,
    onSecondaryContainer: CoetusPalette.purple,
    tertiary: CoetusPalette.lime,
    onTertiary: CoetusPalette.purple,
    surface: CoetusPalette.cream,
    onSurface: CoetusPalette.purpleInk,
    onSurfaceVariant: CoetusColors.muted,
    outline: CoetusColors.borderStrong,
    error: CoetusColors.danger,
  );
  return base.copyWith(
    scaffoldBackgroundColor: CoetusPalette.lavender,
    colorScheme: scheme,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: CoetusPalette.purple,
      foregroundColor: CoetusPalette.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      titleTextStyle: text.titleLarge?.copyWith(color: CoetusPalette.cream),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    dividerColor: CoetusColors.border,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CoetusPalette.lime,
        foregroundColor: CoetusPalette.purple,
        disabledBackgroundColor: CoetusPalette.softLavender,
        disabledForegroundColor: CoetusColors.muted,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        textStyle: text.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoetusPalette.lime,
        foregroundColor: CoetusPalette.purple,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: text.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoetusPalette.purple,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: CoetusPalette.purple, width: 1.5),
        textStyle: text.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CoetusPalette.purple,
        textStyle: text.labelMedium,
      ),
    ),
    cardTheme: CardThemeData(
      color: CoetusPalette.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.card),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CoetusPalette.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.sheet),
      ),
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CoetusPalette.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoetusPalette.cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: body(14, color: CoetusColors.hint),
      labelStyle: body(13, color: CoetusColors.muted),
      floatingLabelStyle: body(12, color: CoetusPalette.purple),
      errorStyle: body(12, color: CoetusColors.danger),
      prefixIconColor: CoetusPalette.purple,
      suffixIconColor: CoetusPalette.purple,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.border),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusPalette.purple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.danger, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CoetusPalette.softLavender,
      selectedColor: CoetusPalette.lime,
      labelStyle: body(
        12,
        weight: FontWeight.w700,
        color: CoetusPalette.purple,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: const StadiumBorder(),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: CoetusPalette.purple,
      unselectedLabelColor: CoetusColors.muted,
      labelStyle: text.labelLarge,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: CoetusPalette.purple, width: 3),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CoetusPalette.purple,
      selectedItemColor: CoetusPalette.lime,
      unselectedItemColor: CoetusPalette.cream,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CoetusPalette.purple,
      linearTrackColor: CoetusPalette.softLavender,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: CoetusPalette.purple,
      inactiveTrackColor: CoetusPalette.softLavender,
      thumbColor: CoetusPalette.purple,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CoetusPalette.purple,
      contentTextStyle: body(13, color: CoetusPalette.cream),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
