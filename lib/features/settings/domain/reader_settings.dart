/// Preferensi tampilan dan suara pembaca untuk disleksia dewasa.
class ReaderSettings {
  final double fontSize;
  final double lineSpacing;
  final double letterSpacing;
  final double speechRate;
  final bool showReadingRuler;

  const ReaderSettings({
    this.fontSize = 18.0,
    this.lineSpacing = 1.7,
    this.letterSpacing = 0.5,
    this.speechRate = 0.48,
    this.showReadingRuler = true,
  });

  ReaderSettings copyWith({
    double? fontSize,
    double? lineSpacing,
    double? letterSpacing,
    double? speechRate,
    bool? showReadingRuler,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      speechRate: speechRate ?? this.speechRate,
      showReadingRuler: showReadingRuler ?? this.showReadingRuler,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'letterSpacing': letterSpacing,
      'speechRate': speechRate,
      'showReadingRuler': showReadingRuler,
    };
  }

  factory ReaderSettings.fromMap(Map<String, dynamic> map) {
    return ReaderSettings(
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.7,
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.5,
      speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.48,
      showReadingRuler: map['showReadingRuler'] as bool? ?? true,
    );
  }
}

