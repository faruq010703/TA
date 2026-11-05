import 'dart:convert';
import '../../../../core/utils/accessibility_utils.dart';

/// Jenis sumber dokumen input.
enum DocumentSourceType {
  camera,
  file,
  manual;

  String get displayName {
    switch (this) {
      case DocumentSourceType.camera:
        return 'Kamera';
      case DocumentSourceType.file:
        return 'Berkas';
      case DocumentSourceType.manual:
        return 'Teks Manual';
    }
  }
}

/// Model entitas dokumen bacaan pengguna.
class ReadingDocument {
  final String id;
  final String title;
  final String content;
  final String snippet;
  final DocumentSourceType sourceType;
  final DateTime createdAt;
  final DateTime lastReadAt;
  final int currentWordIndex;
  final int totalWords;

  const ReadingDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.snippet,
    required this.sourceType,
    required this.createdAt,
    required this.lastReadAt,
    this.currentWordIndex = 0,
    required this.totalWords,
  });

  /// Rasio progres baca dari 0.0 hingga 1.0 (0% - 100%)
  double get progressRatio {
    if (totalWords <= 0) return 0.0;
    return (currentWordIndex / totalWords).clamp(0.0, 1.0);
  }

  /// Persentase progres dalam bilangan bulat 0 - 100
  int get progressPercent => (progressRatio * 100).round();

  /// Apakah dokumen sudah selesai dibaca seluruhnya
  bool get isCompleted => progressRatio >= 0.98;

  /// Perkiraan estimasi waktu baca
  String get estimatedReadingTime =>
      AccessibilityUtils.calculateReadingTime(totalWords);

  ReadingDocument copyWith({
    String? id,
    String? title,
    String? content,
    String? snippet,
    DocumentSourceType? sourceType,
    DateTime? createdAt,
    DateTime? lastReadAt,
    int? currentWordIndex,
    int? totalWords,
  }) {
    return ReadingDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      snippet: snippet ?? this.snippet,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      totalWords: totalWords ?? this.totalWords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'snippet': snippet,
      'sourceType': sourceType.name,
      'createdAt': createdAt.toIso8601String(),
      'lastReadAt': lastReadAt.toIso8601String(),
      'currentWordIndex': currentWordIndex,
      'totalWords': totalWords,
    };
  }

  factory ReadingDocument.fromMap(Map<String, dynamic> map) {
    return ReadingDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      snippet: map['snippet'] as String? ??
          AccessibilityUtils.createSnippet(map['content'] as String),
      sourceType: DocumentSourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => DocumentSourceType.manual,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastReadAt: DateTime.parse(map['lastReadAt'] as String),
      currentWordIndex: map['currentWordIndex'] as int? ?? 0,
      totalWords: map['totalWords'] as int? ??
          AccessibilityUtils.countWords(map['content'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReadingDocument.fromJson(String source) =>
      ReadingDocument.fromMap(json.decode(source) as Map<String, dynamic>);
}

