import 'dart:math';

/// Kumpulan fungsi pembantu (utilities) untuk meningkatkan aksesibilitas pembaca.
class AccessibilityUtils {
  /// Menghitung perkiraan waktu baca dokumen (berdasarkan rerata baca nyaman 130-160 kata/menit).
  static String calculateReadingTime(int wordCount) {
    if (wordCount <= 0) return '< 1 menit';
    final minutes = (wordCount / 140).ceil();
    if (minutes < 1) return '< 1 menit';
    return '$minutes menit baca';
  }

  /// Menghitung jumlah kata dalam teks secara akurat.
  static int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return RegExp(r'\S+').allMatches(trimmed).length;
  }

  /// Menghasilkan sapaan berdasarkan waktu lokal saat ini.
  static String getGreetingByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  /// Memotong cuplikan teks dengan rapi pada batas kata agar tidak terpotong canggung.
  static String createSnippet(String text, {int maxLength = 90}) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;

    final sub = cleaned.substring(0, min(cleaned.length, maxLength));
    final lastSpace = sub.lastIndexOf(' ');
    if (lastSpace > 20) {
      return '${sub.substring(0, lastSpace)}...';
    }
    return '$sub...';
  }

  /// Format tanggal ramah pengguna (contoh: "Hari ini, 14:30" atau "2 Nov 2026")
  static String formatFriendlyDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && now.day == date.day) {
      final hourStr = date.hour.toString().padLeft(2, '0');
      final minuteStr = date.minute.toString().padLeft(2, '0');
      return 'Hari ini, $hourStr:$minuteStr';
    } else if (difference.inDays <= 1 && now.day - date.day == 1) {
      return 'Kemarin';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}

