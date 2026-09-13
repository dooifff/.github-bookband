import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A [Color] that also supports Material-style shade indexing, e.g.
/// `AppTheme.accent[50]`. Shades are tuned for the dark luxury palette, so
/// low indexes are subtle gold/color tints over the dark surfaces.
class ShadedColor extends Color {
  final Map<int, Color> shades;

  const ShadedColor(int value, this.shades) : super(value);

  Color operator [](int shade) => shades[shade] ?? this;
}

class AppTheme {
  // ═══════════════════════════════════════════════
  // Core Palette — Premium Dark Luxury
  // ═══════════════════════════════════════════════
  static const Color primary = Color(0xFF050508);
  static const Color secondary = Color(0xFF0A0A10);
  static const ShadedColor accent = ShadedColor(0xFFD4AF37, {
    50: Color(0x14D4AF37),
    100: Color(0x1FD4AF37),
    200: Color(0x33D4AF37),
    600: Color(0xFFE6C247),
    700: Color(0xFFE6C247),
    800: Color(0xFFB8960E),
  });
  static const Color accentHover = Color(0xFFE6C247);
  static const Color accentDark = Color(0xFFB8960E);

  // Surfaces — deep, layered blacks
  static const Color surface = Color(0xFF0C0C14);
  static const Color surfaceLight = Color(0xFF14141E);
  static const Color surfaceLighter = Color(0xFF1C1C2A);
  static const Color surfaceElevated = Color(0xFF20202E);

  // Borders
  static const Color border = Color(0xFF1E1E2C);
  static const Color borderLight = Color(0xFF2A2A3C);
  static const Color borderAccent = Color(0x2ED4AF37);

  // Text
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9898B0);
  static const Color textMuted = Color(0xFF5A5A72);
  static const Color textAccent = Color(0xFFD4AF37);

  // Semantic
  static const ShadedColor success = ShadedColor(0xFF22C55E, {
    50: Color(0x1422C55E),
    100: Color(0x1F22C55E),
    700: Color(0xFF4ADE80),
    800: Color(0xFF15803D),
  });
  static const Color warning = Color(0xFFEAB308);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gold glow
  static const Color goldGlow = Color(0x1ED4AF37);
  static const Color goldGlowStrong = Color(0x40D4AF37);

  // ═══════════════════════════════════════════════
  // Backward-compatible aliases
  // ═══════════════════════════════════════════════
  static const Color primaryColor = accent;
  static const Color cardColor = surface;
  static const Color borderColor = border;
  static const Color dividerColor = borderLight;
  /// Alias for primary — used as scaffold background in older files
  static const Color backgroundColor = primary;

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentDark, accent, accentHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0E0E18), Color(0xFF12121E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surfaceLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════
  // Dark Theme
  // ═══════════════════════════════════════════════
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: primary,

      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: secondary,
        surface: surface,
        error: danger,
        onPrimary: primary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.02),
        displayMedium: textTheme.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.02),
        headlineLarge: textTheme.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.01),
        headlineMedium: textTheme.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.01),
        headlineSmall: textTheme.headlineSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: textTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
        titleSmall: textTheme.titleSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textSecondary, height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary, height: 1.5),
        bodySmall: textTheme.bodySmall?.copyWith(color: textMuted, height: 1.4),
        labelLarge: textTheme.labelLarge?.copyWith(color: accent, fontWeight: FontWeight.w600, letterSpacing: 0.02),
        labelMedium: textTheme.labelMedium?.copyWith(color: textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.04),
        labelSmall: textTheme.labelSmall?.copyWith(color: textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.06),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.01),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: borderAccent, width: 1),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x140C0C14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: danger, width: 1.5)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 0.5, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: accent,
        disabledColor: surfaceLighter,
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 0.5),
        ),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: surfaceLighter,
        thumbColor: accent,
        overlayColor: goldGlow,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return surfaceLighter;
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Decorations & Utilities
  // ═══════════════════════════════════════════════

  static BoxDecoration get cardDecoration => const BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(BorderSide(color: border, width: 0.5)),
  );

  static BoxDecoration get glassCard => BoxDecoration(
    color: const Color(0xB30C0C14),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: goldGlow, width: 0.5),
  );

  static TextStyle goldTextStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      foreground: Paint()
        ..shader = const LinearGradient(
          colors: [accent, accentHover, accent],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
    );
  }

  static List<BoxShadow> get luxuryShadow => [
    BoxShadow(color: primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: goldGlow, blurRadius: 40, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(color: accent.withOpacity(0.08), blurRadius: 30, spreadRadius: -4),
  ];
}
