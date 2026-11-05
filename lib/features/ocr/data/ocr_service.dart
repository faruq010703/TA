import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/ocr_result.dart';

/// Layanan pengenalan teks pada dokumen foto/gambar berbasis Google ML Kit OCR lokal (On-Device).
class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Memproses gambar dari path lokal dan mengekstrak teks.
  Future<OcrResult> processImageFromPath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _recognizer.processImage(inputImage);

      final extractedText = recognizedText.text.trim();
      if (extractedText.isEmpty) {
        return OcrResult.failure(
          'Tidak ada teks yang terbaca. Pastikan dokumen memiliki teks yang tajam dan pencahayaan yang cukup.',
        );
      }

      return OcrResult.success(
        extractedText,
        blocksCount: recognizedText.blocks.length,
      );
    } catch (e) {
      return OcrResult.failure(
        'Terjadi kendala saat membaca teks: ${e.toString()}',
      );
    }
  }

  /// Membersihkan sumber daya TextRecognizer setelah selesai digunakan.
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

