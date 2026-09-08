import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Konfigurasi tema global terpusat untuk aplikasi Mathmo.
///
/// Keputusan tipografi:
/// - **Quicksand**: Font UI utama, headline, body, label (kesan playful & ramah)
/// - **JetBrains Mono**: Font angka matematika dan tabular numerals (sejajar & presisi)
class AppTheme {
  AppTheme._();

  /// Border color default untuk estetika chunky solid.
  static const Color darkBorder = Color(0xFF232B1E);

  /// Menghasilkan [ThemeData] utama aplikasi.
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.quicksandTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF639922), // Onboarding green primary
        primary: const Color(0xFF639922),
        secondary: const Color(0xFFBA7517), // Warm amber
        tertiary: const Color(0xFFD85A30), // Coral orange
        surface: const Color(0xFFFAFDF5),
      ),
      textTheme: baseTextTheme.copyWith(
        // Headline & Title memakai Quicksand bold
        displayLarge: GoogleFonts.quicksand(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: darkBorder,
        ),
        displayMedium: GoogleFonts.quicksand(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkBorder,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: darkBorder,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkBorder,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkBorder,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkBorder,
        ),
      ),
    );
  }

  /// TextStyle khusus untuk angka soal aritmatika dan opsi jawaban di gameplay.
  ///
  /// Menggunakan [GoogleFonts.jetbrainsMono] dengan tabular numerals
  /// agar digit selalu memiliki lebar yang konsisten (monospace) dan mudah dibaca cepat.
  static TextStyle mathNumberStyle({
    double fontSize = 38,
    FontWeight fontWeight = FontWeight.w800,
    Color color = darkBorder,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5,
    );
  }

  /// TextStyle untuk timer & angka statistik ringkas.
  static TextStyle statNumberStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = darkBorder,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// TextStyle untuk tombol jawaban grid 2x2.
  static TextStyle answerButtonStyle({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
    Color color = darkBorder,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
