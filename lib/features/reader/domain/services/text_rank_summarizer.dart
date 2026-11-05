import 'dart:math';

/// Representasi kalimat hasil seleksi TextRank
class SummarySentence {
  final int originalIndex;
  final String text;
  final double score;

  const SummarySentence({
    required this.originalIndex,
    required this.text,
    required this.score,
  });
}

/// Hasil ringkasan teks TextRank
class TextRankSummary {
  final List<SummarySentence> sentences;
  final String combinedSummary;
  final int originalSentenceCount;
  final int summarySentenceCount;

  const TextRankSummary({
    required this.sentences,
    required this.combinedSummary,
    required this.originalSentenceCount,
    required this.summarySentenceCount,
  });

  double get compressionPercent {
    if (originalSentenceCount <= 0) return 0.0;
    return ((1 - (summarySentenceCount / originalSentenceCount)) * 100)
        .clamp(0.0, 100.0);
  }
}

/// Algoritma Peringkas Teks Mandiri (Extractive TextRank)
/// Berjalan 100% lokal on-device tanpa API eksternal berbasis frekuensi kata,
/// pembobotan kemiripan kosinus antar-kalimat, dan iterasi grafik TextRank.
class TextRankSummarizer {
  // Daftar kata henti (stopwords) umum Bahasa Indonesia
  static const Set<String> _stopWords = {
    'yang', 'di', 'dan', 'itu', 'dengan', 'untuk', 'tidak', 'ini', 'dari',
    'dalam', 'akan', 'pada', 'juga', 'ke', 'karena', 'para', 'namun', 'atau',
    'dapat', 'mereka', 'ada', 'adalah', 'oleh', 'saat', 'telah', 'seperti',
    'lebih', 'sudah', 'suatu', 'hanya', 'sedang', 'bisa', 'harus', 'sangat',
    'serta', 'hingga', 'jika', 'bahwa', 'tentang', 'hal', 'bagi', 'tersebut',
    'ia', 'dia', 'kami', 'kita', 'anda', 'kamu', 'aku', 'saya', 'lalu',
    'kemudian', 'setelah', 'sebelum', 'antara', 'begitu', 'maka', 'bila',
  };

  /// Mengekstraksi 3 hingga 5 kalimat inti dari teks dokumen
  static TextRankSummary summarize(String fullText, {int maxSentences = 5}) {
    final rawSentences = _splitIntoSentences(fullText);

    if (rawSentences.length <= 3) {
      final summarySentences = rawSentences
          .asMap()
          .entries
          .map((e) => SummarySentence(
                originalIndex: e.key,
                text: e.value,
                score: 1.0,
              ))
          .toList();
      return TextRankSummary(
        sentences: summarySentences,
        combinedSummary: rawSentences.join(' '),
        originalSentenceCount: rawSentences.length,
        summarySentenceCount: rawSentences.length,
      );
    }

    // 1. Tokenisasi kata untuk setiap kalimat & eliminasi stopwords
    final sentenceTokens = <List<String>>[];
    for (final s in rawSentences) {
      sentenceTokens.add(_tokenizeSentence(s));
    }

    // 2. Hitung matriks kemiripan kosinus antar-kalimat
    final n = rawSentences.length;
    final similarityMatrix = List.generate(n, (_) => List.filled(n, 0.0));

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final sim = _cosineSimilarity(sentenceTokens[i], sentenceTokens[j]);
        similarityMatrix[i][j] = sim;
        similarityMatrix[j][i] = sim;
      }
    }

    // 3. Iterasi TextRank (Power Iteration dengan Damping Factor 0.85)
    const damping = 0.85;
    const maxIterations = 25;
    var scores = List.filled(n, 1.0);

    // Hitung total bobot keluar per simpul
    final outWeights = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      outWeights[i] = similarityMatrix[i].reduce((a, b) => a + b);
    }

    for (int iter = 0; iter < maxIterations; iter++) {
      final newScores = List.filled(n, 1.0 - damping);
      for (int i = 0; i < n; i++) {
        double sum = 0.0;
        for (int j = 0; j < n; j++) {
          if (i != j && outWeights[j] > 0) {
            sum += (similarityMatrix[j][i] / outWeights[j]) * scores[j];
          }
        }
        newScores[i] += damping * sum;
      }
      scores = newScores;
    }

    // 4. Pilih 3 - 5 kalimat dengan skor tertinggi
    final targetCount = min(max(3, (n * 0.4).round()), maxSentences);

    final scoredList = List.generate(
      n,
      (i) => SummarySentence(
        originalIndex: i,
        text: rawSentences[i],
        score: scores[i],
      ),
    );

    // Urutkan berdasarkan skor tertinggi
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    // Ambil sejumlah targetCount
    final selected = scoredList.take(targetCount).toList();

    // Urutkan kembali berdasarkan urutan kemunculan aslinya agar alur paragraf tetap logis
    selected.sort((a, b) => a.originalIndex.compareTo(b.originalIndex));

    final combined = selected.map((s) => s.text).join(' ');

    return TextRankSummary(
      sentences: selected,
      combinedSummary: combined,
      originalSentenceCount: n,
      summarySentenceCount: selected.length,
    );
  }

  /// Memisahkan teks menjadi kalimat berdasarkan tanda baca . ! ?
  static List<String> _splitIntoSentences(String text) {
    final cleaned = text.replaceAll('\r\n', ' ').replaceAll('\n', ' ');
    final rawList = cleaned.split(RegExp(r'(?<=[.!?])\s+'));

    return rawList
        .map((s) => s.trim())
        .where((s) => s.length > 15) // Abaikan pecahan singkat
        .toList();
  }

  /// Tokenisasi kalimat menjadi kata bermakna (tanpa tanda baca dan tanpa stopwords)
  static List<String> _tokenizeSentence(String sentence) {
    final words = sentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'));

    return words.where((w) => w.length > 2 && !_stopWords.contains(w)).toList();
  }

  /// Menghitung kemiripan kosinus antar dua himpunan kata
  static double _cosineSimilarity(List<String> wordsA, List<String> wordsB) {
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final freqA = <String, int>{};
    for (final w in wordsA) {
      freqA[w] = (freqA[w] ?? 0) + 1;
    }

    final freqB = <String, int>{};
    for (final w in wordsB) {
      freqB[w] = (freqB[w] ?? 0) + 1;
    }

    double dotProduct = 0.0;
    for (final entry in freqA.entries) {
      final countB = freqB[entry.key];
      if (countB != null) {
        dotProduct += entry.value * countB;
      }
    }

    if (dotProduct == 0.0) return 0.0;

    double normA = 0.0;
    for (final v in freqA.values) {
      normA += v * v;
    }

    double normB = 0.0;
    for (final v in freqB.values) {
      normB += v * v;
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0.0) return 0.0;

    return dotProduct / denominator;
  }
}
