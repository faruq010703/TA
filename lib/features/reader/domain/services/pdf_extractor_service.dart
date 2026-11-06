import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:pdf_render/pdf_render.dart' as pdf_render;

import '../../../../core/utils/accessibility_utils.dart';
import '../../../ocr/data/ocr_service.dart';
import '../../../ocr/presentation/ocr_controller.dart';

/// Service untuk mengekstrak seluruh halaman dokumen PDF secara menyeluruh.
/// Mendukung dua mode:
/// A. PDF Digital Teks Langsung (Direct Text): Loop dari halaman pertama hingga akhir.
/// B. Fallback PDF Scan/Citra (Image-based PDF): Jika teks digital < 30 kata, render
///    halaman PDF menjadi gambar lalu proses dengan Google ML Kit OCR.
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

    // 1. Ekstraksi Langsung PDF Digital (Direct Text)
    String directText = '';
    try {
      final fileBytes = await file.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: fileBytes);
      final extractor = syncfusion.PdfTextExtractor(document);
      final pageCount = document.pages.count;
      final buffer = StringBuffer();

      for (int i = 0; i < pageCount; i++) {
        final pageText = extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        final cleanedPage = _ocrService.cleanOcrText(pageText);
        if (cleanedPage.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln('\n');
          }
          buffer.write(cleanedPage);
        }
      }
      document.dispose();
      directText = buffer.toString().trim();
    } catch (e) {
      debugPrint('Gagal mengekstrak teks langsung PDF: $e');
    }

    final wordCount = AccessibilityUtils.countWords(directText);

    // Jika teks digital sudah memadai (>= 30 kata), gunakan langsung tanpa OCR gambar
    if (wordCount >= 30) {
      return directText;
    }

    // 2. Fallback: PDF Hasil Scan / Berbasis Gambar
    // Jika teks digital kosong atau < 30 kata, render setiap halaman PDF menjadi gambar lalu OCR
    try {
      final ocrText = await _extractViaOcr(filePath);
      final ocrWordCount = AccessibilityUtils.countWords(ocrText);
      if (ocrWordCount > wordCount) {
        return ocrText;
      }
    } catch (e) {
      debugPrint('Fallback OCR PDF gagal: $e');
    }

    return directText;
  }

  /// Merender setiap halaman PDF menjadi citra bitmap dan mengekstrak teksnya via Google ML Kit OCR.
  Future<String> _extractViaOcr(String filePath) async {
    pdf_render.PdfDocument? doc;
    try {
      doc = await pdf_render.PdfDocument.openFile(filePath);
      final buffer = StringBuffer();
      final tempDir = Directory.systemTemp;

      for (int pageNum = 1; pageNum <= doc.pageCount; pageNum++) {
        final page = await doc.getPage(pageNum);
        // Skala 2.0x untuk meningkatkan resolusi citra bitmap agar akurasi OCR optimal
        const double scale = 2.0;
        final renderWidth = (page.width * scale).round();
        final renderHeight = (page.height * scale).round();

        final pageImage = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
          width: renderWidth,
          height: renderHeight,
        );

        final uiImage = await pageImage.createImageIfNotAvailable();
        final byteData =
            await uiImage.toByteData(format: ui.ImageByteFormat.png);
        pageImage.dispose();

        if (byteData != null) {
          final tempFile = File(
            '${tempDir.path}/pdf_ocr_p${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await tempFile.writeAsBytes(byteData.buffer.asUint8List());

          try {
            final ocrResult =
                await _ocrService.processImageFromPath(tempFile.path);
            if (ocrResult.isSuccess && ocrResult.text.trim().isNotEmpty) {
              if (buffer.isNotEmpty) {
                buffer.writeln('\n');
              }
              buffer.write(ocrResult.text.trim());
            }
          } finally {
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          }
        }
      }

      return buffer.toString().trim();
    } finally {
      await doc?.dispose();
    }
  }
}

/// Provider Riverpod untuk PdfExtractorService
final pdfExtractorServiceProvider = Provider<PdfExtractorService>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  return PdfExtractorService(ocrService: ocrService);
});
