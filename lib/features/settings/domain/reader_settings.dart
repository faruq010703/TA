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
    double wordSpacing = 2.0,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    switch (this) {
      case ReaderFontFamily.lexend:
        return GoogleFonts.lexend(
          fontSize: fontSize,
          height: height,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          color: color,
          fontWeight: fontWeight,
        );
      case ReaderFontFamily.openDyslexic:
        return GoogleFonts.comicNeue(
          fontSize: fontSize + 1.0,
          height: height,
          letterSpacing: letterSpacing + 0.3,
          wordSpacing: wordSpacing + 0.5,
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
          wordSpacing: wordSpacing,
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
    backgroundColor: Color(0xFFF4EEDD), // #F4EEDD krem ramah Irlen Syndrome
    textColor: Color(0xFF1E242B),
    shadingColor: Color(0xFFECE5D2),
    surfaceColor: Color(0xFFFAF7EF),
    borderColor: Color(0xFFDFD7C4),
    isDark: false,
  ),
  peach(
    displayName: 'Peach Hangat',
    backgroundColor: Color(0xFFFEEFE3), // #FEEFE3 peach lembut
    textColor: Color(0xFF2E2620),
    shadingColor: Color(0xFFF7DFD0),
    surfaceColor: Color(0xFFFFF6F0),
    borderColor: Color(0xFFE8D0BF),
    isDark: false,
  ),
  pastelBlue(
    displayName: 'Pastel Blue',
    backgroundColor: Color(0xFFE8F1F5), // #E8F1F5 biru pastel teduh
    textColor: Color(0xFF1E252B),
    shadingColor: Color(0xFFD6E4EB),
    surfaceColor: Color(0xFFF2F7FA),
    borderColor: Color(0xFFCADAE3),
    isDark: false,
  ),
  lowContrastDark(
    displayName: 'Dark Mode Lembut',
    backgroundColor: Color(0xFF1E1E1E), // #1E1E1E kontras rendah
    textColor: Color(0xFFD4D4D4), // #D4D4D4 teks lembut
    shadingColor: Color(0xFF282828),
    surfaceColor: Color(0xFF252525),
    borderColor: Color(0xFF383838),
    isDark: true,
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
  final double wordSpacing;
  final bool enableLineShading;
  final ReaderColorTheme colorTheme;
  final double speechRate;
  final double pitch;
  final int interWordPauseMs;
  final bool phonicSyllableColoring;
  final bool showReadingRuler;

  const ReaderSettings({
    this.fontFamily = ReaderFontFamily.lexend,
    this.fontSize = 18.0,
    this.lineSpacing = 1.8,
    this.letterSpacing = 1.2,
    this.wordSpacing = 2.0,
    this.enableLineShading = true,
    this.colorTheme = ReaderColorTheme.cream,
    this.speechRate = 0.8,
    this.pitch = 1.0,
    this.interWordPauseMs = 200,
    this.phonicSyllableColoring = false,
    this.showReadingRuler = true,
  });

  ReaderSettings copyWith({
    ReaderFontFamily? fontFamily,
    double? fontSize,
    double? lineSpacing,
    double? letterSpacing,
    double? wordSpacing,
    bool? enableLineShading,
    ReaderColorTheme? colorTheme,
    double? speechRate,
    double? pitch,
    int? interWordPauseMs,
    bool? phonicSyllableColoring,
    bool? showReadingRuler,
  }) {
    return ReaderSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      enableLineShading: enableLineShading ?? this.enableLineShading,
      colorTheme: colorTheme ?? this.colorTheme,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      interWordPauseMs: interWordPauseMs ?? this.interWordPauseMs,
      phonicSyllableColoring:
          phonicSyllableColoring ?? this.phonicSyllableColoring,
      showReadingRuler: showReadingRuler ?? this.showReadingRuler,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily.name,
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'letterSpacing': letterSpacing,
      'wordSpacing': wordSpacing,
      'enableLineShading': enableLineShading,
      'colorTheme': colorTheme.name,
      'speechRate': speechRate,
      'pitch': pitch,
      'interWordPauseMs': interWordPauseMs,
      'phonicSyllableColoring': phonicSyllableColoring,
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
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 1.2,
      wordSpacing: (map['wordSpacing'] as num?)?.toDouble() ?? 2.0,
      enableLineShading: map['enableLineShading'] as bool? ?? true,
      colorTheme: ReaderColorTheme.values.firstWhere(
        (e) => e.name == map['colorTheme'],
        orElse: () => ReaderColorTheme.cream,
      ),
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.8,
      pitch: (map['pitch'] as num?)?.toDouble() ?? 1.0,
      interWordPauseMs: (map['interWordPauseMs'] as num?)?.toInt() ?? 200,
      phonicSyllableColoring: map['phonicSyllableColoring'] as bool? ?? false,
      showReadingRuler: map['showReadingRuler'] as bool? ?? true,
    );
  }
}
