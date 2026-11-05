import 'dart:io';

/// Fungsi utilitas penanganan berkas dan ekstensi.
class FileUtils {
  /// Mendeteksi apakah berkas merupakan format gambar.
  static bool isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  /// Mendeteksi apakah berkas merupakan dokumen PDF.
  static bool isPdfFile(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  /// Mendeteksi apakah berkas teks biasa.
  static bool isTextFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.txt') ||
        lower.endsWith('.md') ||
        lower.endsWith('.rtf');
  }

  /// Mengambil nama file bersih tanpa path direktori.
  static String getFileName(String path) {
    final file = File(path);
    final segments = file.uri.pathSegments;
    return segments.isNotEmpty ? segments.last : 'Dokumen';
  }
}

