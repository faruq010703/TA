/// Layanan pemenggal suku kata Bahasa Indonesia berbasis aturan fonotaktik PUEBI/EYD.
/// Membantu pembaca disleksia dewasa mendekode kata-kata panjang atau asing menjadi
/// suku kata yang mudah dilafalkan (pola V, VK, KV, KVK).
class SyllableService {
  static const Set<String> _vowels = {'a', 'e', 'i', 'o', 'u'};

  // Digraf konsonan yang dianggap sebagai satu konsonan fonetik tunggal
  static const List<String> _digraphs = ['ng', 'ny', 'sy', 'kh'];

  /// Memenggal satu kata Bahasa Indonesia menjadi daftar suku kata.
  /// Contoh: "mempertahankan" -> ["mem", "per", "tah", "an", "kan"]
  static List<String> syllabify(String word) {
    final cleaned = word.trim().toLowerCase();
    if (cleaned.isEmpty) return [];
    if (cleaned.length <= 2) return [word];

    // Simpan tanda baca awal/akhir jika ada
    final match = RegExp(r'^([^a-zA-Z]*)([a-zA-Z\-]+)([^a-zA-Z]*)$').firstMatch(word);
    if (match == null) return [word];

    final coreWord = match.group(2)!.toLowerCase();
    if (coreWord.length <= 2) return [word];

    // Jika kata majemuk dengan tanda hubung (misal: "buku-buku")
    if (coreWord.contains('-')) {
      final parts = coreWord.split('-');
      final result = <String>[];
      for (int i = 0; i < parts.length; i++) {
        result.addAll(_syllabifySingleWord(parts[i]));
      }
      return result.isNotEmpty ? result : [word];
    }

    final syllables = _syllabifySingleWord(coreWord);

    // Kembalikan casing asli jika huruf pertama kapital
    if (syllables.isNotEmpty && word.isNotEmpty && word[0].toUpperCase() == word[0]) {
      syllables[0] = syllables[0][0].toUpperCase() + syllables[0].substring(1);
    }

    return syllables;
  }

  /// Memenggal satu kata dan menyatukannya dengan tanda hubung strip ("-").
  /// Contoh: "mempertahankan" -> "mem-per-tah-an-kan"
  static String formatWithHyphen(String word) {
    final syllables = syllabify(word);
    return syllables.join('-');
  }

  static List<String> _syllabifySingleWord(String text) {
    if (text.length <= 2) return [text];

    // 1. Ekstrak awalan produktif Bahasa Indonesia terlebih dahulu
    final prefixResult = _extractPrefix(text);
    final prefixList = prefixResult.prefixes;
    var remainder = prefixResult.remainder;

    // 2. Ekstrak akhiran produktif Bahasa Indonesia
    final suffixResult = _extractSuffix(remainder);
    final suffixList = suffixResult.suffixes;
    remainder = suffixResult.remainder;

    // 3. Penggal bagian tengah (kata dasar / inti) menggunakan aturan fonotaktik PUEBI
    final middleSyllables = _phonotacticSplit(remainder);

    return [...prefixList, ...middleSyllables, ...suffixList];
  }

  /// Ekstraksi imbuhan awalan (prefiks)
  static ({List<String> prefixes, String remainder}) _extractPrefix(String word) {
    final prefixes = <String>[];
    var current = word;

    // Daftar prefiks terurut dari yang terpanjang
    const knownPrefixes = [
      'memper', 'meng', 'meny', 'men', 'mem', 'me',
      'ber', 'ter', 'per', 'peng', 'peny', 'pen', 'pem', 'pe',
      'dis', 'di', 'ke', 'se'
    ];

    for (final pref in knownPrefixes) {
      if (current.startsWith(pref) && current.length - pref.length >= 2) {
        // Cek apakah sisa kata memiliki vokal
        final rest = current.substring(pref.length);
        if (pref == 'di' && rest.length >= 2 && !_isVowel(rest[0]) && !_isVowel(rest[1])) {
          continue; // Bukan awalan 'di-' jika diikuti dua konsonan (misal: "drama", "praktik")
        }
        if (_hasVowel(rest)) {
          if (pref == 'memper') {
            prefixes.add('mem');
            prefixes.add('per');
          } else {
            prefixes.add(pref);
          }
          current = rest;
          break;
        }
      }
    }

    return (prefixes: prefixes, remainder: current);
  }

  /// Ekstraksi imbuhan akhiran (sufiks & klitika)
  static ({String remainder, List<String> suffixes}) _extractSuffix(String word) {
    final suffixes = <String>[];
    var current = word;

    const knownSuffixes = [
      'kannya', 'kan', 'lah', 'kah', 'pun',
      'nya', 'ku', 'mu', 'an', 'i'
    ];

    bool found = true;
    while (found) {
      found = false;
      for (final suf in knownSuffixes) {
        if (current.endsWith(suf) && current.length - suf.length >= 2) {
          final front = current.substring(0, current.length - suf.length);
          if (_hasVowel(front)) {
            if (suf == 'kannya') {
              suffixes.insert(0, 'kan');
              suffixes.add('nya');
            } else {
              suffixes.insert(0, suf);
            }
            current = front;
            found = true;
            break;
          }
        }
      }
    }

    return (remainder: current, suffixes: suffixes);
  }

  /// Pemenggalan fonotaktik inti berdasarkan pola V, VK, KV, KVK
  static List<String> _phonotacticSplit(String text) {
    if (text.length <= 2 || !_hasVowel(text)) {
      return text.isNotEmpty ? [text] : [];
    }

    // Ubah teks menjadi token karakter (dengan memperlakukan digraf ng, ny, sy, kh sebagai 1 unit)
    final tokens = _tokenizeConsonants(text);
    final syllables = <String>[];
    var currentSyllable = '';

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      currentSyllable += token;

      final isVowel = _isVowel(token);

      if (isVowel) {
        // Periksa apa yang ada setelah vokal ini
        if (i + 1 < tokens.length) {
          final next1 = tokens[i + 1];
          final next1IsVowel = _isVowel(next1);

          if (next1IsVowel) {
            // Aturan V-V: dua vokal berurutan bukan diftong dipisah (contoh: sa-at, do-a, bu-ah)
            final diphthong = '$token$next1';
            if (diphthong != 'ai' && diphthong != 'au' && diphthong != 'oi') {
              syllables.add(currentSyllable);
              currentSyllable = '';
            }
          } else {
            // Setelah vokal adalah konsonan
            if (i + 2 < tokens.length) {
              final next2 = tokens[i + 2];
              final next2IsVowel = _isVowel(next2);

              if (next2IsVowel) {
                // Aturan V-K-V: pemenggalan sebelum konsonan (contoh: ba-pak, su-ka)
                syllables.add(currentSyllable);
                currentSyllable = '';
              } else {
                // Setelah vokal ada dua konsonan berturut-turut (V-K-K-...)
                if (i + 3 < tokens.length) {
                  final next3 = tokens[i + 3];
                  if (_isVowel(next3)) {
                    // Aturan V-K-K-V: potong di antara dua konsonan (contoh: man-di, som-bong)
                    currentSyllable += next1;
                    syllables.add(currentSyllable);
                    currentSyllable = '';
                    i++; // lewati konsonan pertama
                  }
                }
              }
            }
          }
        }
      }
    }

    if (currentSyllable.isNotEmpty) {
      if (syllables.isEmpty) {
        syllables.add(currentSyllable);
      } else {
        // Jika sisa hanya konsonan (misal: "k"), gabungkan dengan suku kata terakhir
        if (!_hasVowel(currentSyllable)) {
          syllables[syllables.length - 1] += currentSyllable;
        } else {
          syllables.add(currentSyllable);
        }
      }
    }

    return syllables;
  }

  static List<String> _tokenizeConsonants(String word) {
    final tokens = <String>[];
    for (int i = 0; i < word.length; i++) {
      if (i + 1 < word.length) {
        final pair = word.substring(i, i + 2).toLowerCase();
        if (_digraphs.contains(pair)) {
          tokens.add(word.substring(i, i + 2));
          i++; // lewati karakter kedua digraf
          continue;
        }
      }
      tokens.add(word[i]);
    }
    return tokens;
  }

  static bool _isVowel(String char) {
    if (char.length != 1) return false;
    return _vowels.contains(char.toLowerCase());
  }

  static bool _hasVowel(String text) {
    for (int i = 0; i < text.length; i++) {
      if (_vowels.contains(text[i].toLowerCase())) return true;
    }
    return false;
  }
}
