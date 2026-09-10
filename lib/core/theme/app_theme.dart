import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Konfigurasi tema global terpusat untuk aplikasi iTHUNG.
///
/// Keputusan tipografi:
/// - **Quicksand**: Font UI utama, headline, body, label (kesan playful & ramah)
/// - **JetBrains Mono**: Font angka matematika dan tabular numerals (sejajar & presisi)
class AppTheme {
  AppTheme._();

  // ── Palet Warna Terpusat (Cozy Warm Stationery & Woodwork) ────────
  /// Teks utama dan outline kontras ramah mata (menggantikan hitam pekat).
  static const Color colorEspresso = Color(0xFF3A2E2B);

  /// Teks sekunder, label, dan elemen pendukung.
  static const Color colorTaupe = Color(0xFF8F7E6D);

  /// Aksen primer brand (bintang, streak, tab aktif).
  static const Color colorHoney = Color(0xFFF6C443);

  /// Aksen kayu gelap (bayangan & aksen serat kayu).
  static const Color colorWoodDark = Color(0xFF633B1D);

  /// Aksen kayu hangat / gantungan binder kalender (saddle brown).
  static const Color colorWoodMedium = Color(0xFF9C663D);

  /// Aksen kayu muda / highlight kayu pine.
  static const Color colorWoodLight = Color(0xFFDDB988);

  /// Border kayu tegas untuk plang dan kontainer kayu.
  static const Color colorWoodBorder = Color(0xFF87532A);

  /// Warna isian permukaan papan kayu.
  static const Color colorWoodPlank = Color(0xFFF4E5CA);

  /// Permukaan kertas putih bersih khusus soal matematika.
  static const Color colorPaperWhite = Color(0xFFFFFFFF);

  /// Permukaan kartu vanilla cream hangat untuk UI non-game.
  static const Color colorVanillaCard = Color(0xFFFFFDF7);

  /// Latar belakang kanvas dasar hangat (warm oatmeal/sandy cream).
  static const Color colorSandyCanvas = Color(0xFFF4EBD0);

  /// Warna sukses / jawaban benar / forest sage green.
  static const Color colorSage = Color(0xFF5E9E52);

  /// Warna peringatan / wrong / terracotta coral.
  static const Color colorCoral = Color(0xFFE26D50);

  /// Border color default (diarahkan ke [colorEspresso] demi kompatibilitas).
  static const Color darkBorder = colorEspresso;

  // ── Token semantik tersentralisasi (hasil audit UI) ───────────────
  /// Border cream kartu vanilla (menggantikan literal 0xFFDECFA8).
  static const Color colorCardBorder = Color(0xFFDECFA8);

  /// Hijau sukses tegas (menggantikan literal 0xFF2E7D32).
  static const Color colorSuccess = Color(0xFF2E7D32);

  /// Latar hijau lembut (menggantikan literal 0xFFE8F5E9).
  static const Color colorSuccessSoft = Color(0xFFE8F5E9);

  /// Merah bahaya tegas (menggantikan literal 0xFFD32F2F).
  static const Color colorDanger = Color(0xFFD32F2F);

  /// Latar merah lembut (menggantikan literal 0xFFFFF2EE).
  static const Color colorDangerSoft = Color(0xFFFFF2EE);

  /// Fallback kanvas saat theme provider belum siap.
  static const Color fallbackCanvas = Color(0xFFEAF3DE);

  /// Fallback aksen saat theme provider belum siap.
  static const Color fallbackAccent = Color(0xFF639922);

  /// Badge status tamu / anonim / info.
  static const Color badgeGuestBg = Color(0xFFF3EDD9);
  static const Color badgeInfoBg = Color(0xFFE5F1F8);
  static const Color badgeInfoFg = Color(0xFF2C6D9E);

  /// Menghasilkan [ThemeData] utama aplikasi.
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.quicksandTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colorSandyCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorHoney,
        primary: colorHoney,
        secondary: colorWoodMedium,
        tertiary: colorCoral,
        surface: colorSandyCanvas,
      ),
      textTheme: baseTextTheme.copyWith(
        // Headline & Title memakai Quicksand bold warna Espresso
        displayLarge: GoogleFonts.quicksand(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: colorEspresso,
        ),
        displayMedium: GoogleFonts.quicksand(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colorEspresso,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorEspresso,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorEspresso,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorEspresso,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorEspresso,
        ),
      ),
    );
  }

  /// TextStyle khusus untuk angka soal aritmatika dan opsi jawaban di gameplay.
  ///
  /// Menggunakan font [JetBrainsMono] lokal yang di-bundle di assets
  /// agar glif matematika (seperti ×, ÷, −, +) dan tabular numerals selalu konsisten,
  /// 100% offline, dan bebas dari substitusi/fallback OEM Android font.
  static TextStyle mathNumberStyle({
    double fontSize = 38,
    FontWeight fontWeight = FontWeight.w800,
    Color color = colorEspresso,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
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
    Color color = colorEspresso,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// TextStyle untuk tombol jawaban grid 2x2.
  static TextStyle answerButtonStyle({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
    Color color = colorEspresso,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// TextStyle khusus untuk nama brand aplikasi "iTHUNG" menggunakan font kustom Baberry.
  static TextStyle brandTitleStyle({
    double fontSize = 62,
    Color color = colorHoney,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Baberry',
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
