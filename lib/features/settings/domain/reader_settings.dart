import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pilihan jenis font ramah disleksia
enum ReaderFontFamily {
  lexend('Lexend', 'Dirancang khusus mengurangi visual crowding'),
  openDyslexic('OpenDyslexic', 'Bobot huruf lebih tebal di bagian bawah'),
  sansSerif('Arial / Sans-Serif', 'Huruf netral standar tanpa serif');

  final String displayName;
  final String description;
  const ReaderFontFamily(this.displayName, this.description);

  TextStyle getTextStyle({
    required double fontSize,
    required double height,
    required double letterSpacing,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    switch (this) {
      case ReaderFontFamily.lexend:
        return GoogleFonts.lexend(
          fontSize: fontSize,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
          fontWeight: fontWeight,
        );
      case ReaderFontFamily.openDyslexic:
        // Coba gunakan font OpenDyslexic lokal jika tersedia di aset,
        // dengan fallback ke GoogleFonts.comicNeue yang terbukti ramah disleksia
        return GoogleFonts.comicNeue(
          fontSize: fontSize + 1.0,
          height: height,
          letterSpacing: letterSpacing + 0.3,
          color: color,
          fontWeight: fontWeight == FontWeight.w700
              ? FontWeight.w700
              : FontWeight.w600,
        );
      case ReaderFontFamily.sansSerif:
        return TextStyle(
          fontFamily: 'Arial',
          fontFamilyFallback: const ['Roboto', 'Helvetica', 'sans-serif'],
          fontSize: fontSize,
          height: height,
          letterSpacing: letterSpacing,
          color: color,
          fontWeight: fontWeight,
        );
    }
  }
}

/// Pilihan tema warna latar belakang & kontras ramah disleksia
enum ReaderColorTheme {
  cream(
    displayName: 'Krem Lembut',
    backgroundColor: Color(0xFFFDFBF7),
    textColor: Color(0xFF1E242B),
    shadingColor: Color(0xFFF3EFE6),
    surfaceColor: Color(0xFFFAF7F0),
    borderColor: Color(0xFFE2DDD5),
    isDark: false,
  ),
  pastelYellow(
    displayName: 'Kuning Pastel',
    backgroundColor: Color(0xFFFFF9E8),
    textColor: Color(0xFF26221A),
    shadingColor: Color(0xFFF7EECD),
    surfaceColor: Color(0xFFFFFDF5),
    borderColor: Color(0xFFE8DCC2),
    isDark: false,
  ),
  lightGrey(
    displayName: 'Abu-abu Muda',
    backgroundColor: Color(0xFFF1F3F5),
    textColor: Color(0xFF1F242B),
    shadingColor: Color(0xFFE5E9EC),
    surfaceColor: Color(0xFFF8F9FA),
    borderColor: Color(0xFFD6DBDF),
    isDark: false,
  ),
  lowContrastDark(
    displayName: 'Dark Mode Kontras Rendah',
    backgroundColor: Color(0xFF1E232A),
    textColor: Color(0xFFD9E2EC),
    shadingColor: Color(0xFF282F39),
    surfaceColor: Color(0xFF262C35),
    borderColor: Color(0xFF384250),
    isDark: true,
  );

  final String displayName;
  final Color backgroundColor;
  final Color textColor;
  final Color shadingColor;
  final Color surfaceColor;
  final Color borderColor;
  final bool isDark;

  const ReaderColorTheme({
    required this.displayName,
    required this.backgroundColor,
    required this.textColor,
    required this.shadingColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.isDark,
  });
}

/// Preferensi tampilan dan suara pembaca untuk disleksia dewasa.
class ReaderSettings {
  final ReaderFontFamily fontFamily;
  final double fontSize;
  final double lineSpacing;
  final double letterSpacing;
  final bool enableLineShading;
  final ReaderColorTheme colorTheme;
  final double speechRate;
  final bool showReadingRuler;

  const ReaderSettings({
    this.fontFamily = ReaderFontFamily.lexend,
    this.fontSize = 18.0,
    this.lineSpacing = 1.8,
    this.letterSpacing = 0.5,
    this.enableLineShading = true,
    this.colorTheme = ReaderColorTheme.cream,
    this.speechRate = 0.48,
    this.showReadingRuler = true,
  });

  ReaderSettings copyWith({
    ReaderFontFamily? fontFamily,
    double? fontSize,
    double? lineSpacing,
    double? letterSpacing,
    bool? enableLineShading,
    ReaderColorTheme? colorTheme,
    double? speechRate,
    bool? showReadingRuler,
  }) {
    return ReaderSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      enableLineShading: enableLineShading ?? this.enableLineShading,
      colorTheme: colorTheme ?? this.colorTheme,
      speechRate: speechRate ?? this.speechRate,
      showReadingRuler: showReadingRuler ?? this.showReadingRuler,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily.name,
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'letterSpacing': letterSpacing,
      'enableLineShading': enableLineShading,
      'colorTheme': colorTheme.name,
      'speechRate': speechRate,
      'showReadingRuler': showReadingRuler,
    };
  }

  factory ReaderSettings.fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      fontFamily: ReaderFontFamily.values.firstWhere(
        (e) => e.name == map['fontFamily'],
        orElse: () => ReaderFontFamily.lexend,
      ),
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.8,
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.5,
      enableLineShading: map['enableLineShading'] as bool? ?? true,
      colorTheme: ReaderColorTheme.values.firstWhere(
        (e) => e.name == map['colorTheme'],
        orElse: () => ReaderColorTheme.cream,
      ),
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.48,
      showReadingRuler: map['showReadingRuler'] as bool? ?? true,
    );
  }
}
