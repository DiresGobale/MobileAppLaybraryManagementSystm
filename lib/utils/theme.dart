import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Academic-inspired Material 3 theme for Injibara University Library.
/// Palette: deep navy (primary), academic gold (accent), cream surfaces.
class AppTheme {
  const AppTheme._();

  // ---- Brand palette ----
  static const Color primary = Color(0xFF1E3A5F);       // deep academic navy
  static const Color primaryLight = Color(0xFF2E5A8F);
  static const Color primaryDark = Color(0xFF13243B);
  static const Color accent = Color(0xFFC9A961);        // academic gold
  static const Color accentDark = Color(0xFFA8873F);
  static const Color burgundy = Color(0xFF7B2D3E);      // academic warmth
  static const Color cream = Color(0xFFFAF8F3);
  static const Color ink = Color(0xFF1A1A2E);
  static const Color slate = Color(0xFF5B6B7F);
  static const Color success = Color(0xFF2E7D52);
  static const Color warning = Color(0xFFD4882A);
  static const Color danger = Color(0xFFB3261E);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: Colors.white,
      background: cream,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: ink,
      onSurface: ink,
      onBackground: ink,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      dividerColor: const Color(0xFFE5E0D5),
      textTheme: GoogleFonts.ptSerifTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 34, fontWeight: FontWeight.w700, color: ink, height: 1.15,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 26, fontWeight: FontWeight.w700, color: ink, height: 1.2,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22, fontWeight: FontWeight.w600, color: primary,
        ),
        titleLarge: GoogleFonts.ptSerif(
          fontSize: 18, fontWeight: FontWeight.w700, color: ink,
        ),
        titleMedium: GoogleFonts.ptSerif(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink,
        ),
        bodyLarge: GoogleFonts.ptSerif(
          fontSize: 15, color: ink, height: 1.55,
        ),
        bodyMedium: GoogleFonts.ptSerif(
          fontSize: 13.5, color: slate, height: 1.5,
        ),
        labelLarge: GoogleFonts.ptSerif(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 1.5,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shadowColor: primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: _inputDecoration(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.ptSerif(fontSize: 14.5, fontWeight: FontWeight.w700),
          elevation: 1.5,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.35), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.ptSerif(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.ptSerif(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withOpacity(0.18),
        labelStyle: GoogleFonts.ptSerif(color: ink, fontWeight: FontWeight.w600, fontSize: 12.5),
        side: BorderSide(color: accent.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: slate,
        selectedLabelStyle: GoogleFonts.ptSerif(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.ptSerif(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        scrimColor: primary.withOpacity(0.35),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFE5E0D5),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.ptSerif(fontSize: 14.5, fontWeight: FontWeight.w600, color: ink),
        subtitleTextStyle: GoogleFonts.ptSerif(fontSize: 12.5, color: slate),
      ),
    );
    return base;
  }

  static InputDecorationTheme _inputDecoration() => InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.ptSerif(color: slate, fontSize: 13.5),
        hintStyle: GoogleFonts.ptSerif(color: slate.withOpacity(0.7), fontSize: 13.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFD6CFBE), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.8),
        ),
      );
}
