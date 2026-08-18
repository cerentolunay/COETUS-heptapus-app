import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'coetus_tokens.dart';

/// Coetus ThemeData.
/// pubspec.yaml: google_fonts: ^6.2.1
///
/// MaterialApp(theme: coetusTheme(), home: ...)
ThemeData coetusTheme() {
  final base = ThemeData.light(useMaterial3: true);

  // Başlık: Plus Jakarta Sans · Gövde: DM Sans
  TextStyle head(double size, FontWeight w, {double ls = -0.4, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        height: 1.2,
        color: c ?? CoetusColors.navyInk,
      );

  TextStyle body(double size, FontWeight w, {Color? c, double h = 1.55}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: w,
        height: h,
        color: c ?? CoetusColors.body,
      );

  final textTheme = TextTheme(
    displaySmall: head(30, FontWeight.w800, ls: -0.9),
    headlineMedium: head(27, FontWeight.w800, ls: -0.7),
    headlineSmall: head(22, FontWeight.w800, ls: -0.5),
    titleLarge: head(17, FontWeight.w700, ls: -0.2),
    titleMedium: head(14, FontWeight.w700, ls: 0),
    titleSmall: head(13, FontWeight.w600, ls: 0),
    bodyLarge: body(13.5, FontWeight.w400, h: 1.6),
    bodyMedium: body(13, FontWeight.w400),
    bodySmall: body(11.5, FontWeight.w400, c: CoetusColors.muted, h: 1.45),
    labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0),
    labelMedium: body(12, FontWeight.w500, c: CoetusColors.muted),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
      color: CoetusColors.muted,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: CoetusColors.oat,
    colorScheme: base.colorScheme.copyWith(
      primary: CoetusColors.navy,
      onPrimary: CoetusColors.oat,
      secondary: CoetusColors.coral,
      onSecondary: Colors.white,
      surface: CoetusColors.card,
      onSurface: CoetusColors.ink,
      error: CoetusColors.danger,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: CoetusColors.navy,
      foregroundColor: CoetusColors.oat,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: head(15, FontWeight.w700, c: CoetusColors.oat),
      systemOverlayStyle: null,
    ),
    dividerColor: CoetusColors.border,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CoetusColors.navy,
        foregroundColor: CoetusColors.oat,
        disabledBackgroundColor: const Color(0x1F1E3A63),
        disabledForegroundColor: const Color(0x661B2436),
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CoetusRadius.button)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoetusColors.navy,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: CoetusColors.navy, width: 1.5),
        textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CoetusRadius.button)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CoetusColors.navy,
        textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: CoetusColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CoetusRadius.card)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoetusColors.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: body(13.5, FontWeight.w400, c: CoetusColors.hint),
      labelStyle: body(11.5, FontWeight.w500, c: CoetusColors.muted),
      floatingLabelStyle: body(11.5, FontWeight.w500, c: CoetusColors.navy),
      errorStyle: body(11, FontWeight.w400, c: CoetusColors.danger),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoetusRadius.input),
        borderSide: const BorderSide(color: CoetusColors.danger, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CoetusColors.navyTint,
      labelStyle: body(12, FontWeight.w600, c: CoetusColors.navy),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: const StadiumBorder(),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: CoetusColors.navy,
      unselectedLabelColor: CoetusColors.hint,
      labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5, fontWeight: FontWeight.w500),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: CoetusColors.navy, width: 2.5),
        insets: EdgeInsets.only(top: 6),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CoetusColors.navy,
      selectedItemColor: CoetusColors.oat,
      unselectedItemColor: Color(0x99F5EFE4),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showUnselectedLabels: true,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CoetusColors.navyInk,
      contentTextStyle: body(13, FontWeight.w400, c: CoetusColors.oat),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
