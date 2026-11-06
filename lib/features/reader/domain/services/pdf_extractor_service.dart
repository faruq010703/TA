import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../ocr/data/ocr_service.dart';
import '../../../ocr/presentation/ocr_controller.dart';

/// Service untuk mengekstrak seluruh halaman dokumen PDF secara menyeluruh
/// menggunakan Syncfusion PdfDocument dan PdfTextExtractor murni tanpa native wrapper usang.
class PdfExtractorService {
  final OcrService _ocrService;

  PdfExtractorService({OcrService? ocrService})
      : _ocrService = ocrService ?? OcrService();

  /// Ekstraksi teks lengkap dari seluruh halaman berkas PDF di [filePath].
  /// Tidak ada batasan jumlah karakter agar teks lengkap dapat dibaca di ReaderScreen.
  Future<String> extractText(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return '';
    }

    try {
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      // Mengekstrak teks dari seluruh halaman tanpa terpotong
      final String rawText = extractor.extractText();
      document.dispose();

      final cleanedText = _ocrService.cleanOcrText(rawText);
      return cleanedText.isNotEmpty ? cleanedText : rawText.trim();
    } catch (e) {
      debugPrint('Gagal mengekstrak teks PDF dengan Syncfusion: $e');
      return '';
    }
  }
}

/// Provider Riverpod untuk PdfExtractorService
final pdfExtractorServiceProvider = Provider<PdfExtractorService>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return PdfExtractorService(ocrService: ocrService);
});
