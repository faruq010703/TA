import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/ocr_result.dart';

/// Layanan pengenalan teks pada dokumen foto/gambar berbasis Google ML Kit OCR lokal (On-Device).
/// Dilengkapi dengan normalisasi dan pembersihan whitespace berlebih untuk kenyamanan disleksia.
class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Memproses gambar dari path lokal, mengekstrak teks, dan membersihkan format teks.
  Future<OcrResult> processImageFromPath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _recognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final cleanedText = cleanOcrText(rawText);

      if (cleanedText.isEmpty) {
        return OcrResult.failure(
          'Tidak ada teks yang terbaca. Pastikan dokumen memiliki teks yang tajam dan pencahayaan yang cukup.',
        );
      }

      return OcrResult.success(
        cleanedText,
        blocksCount: recognizedText.blocks.length,
      );
    } catch (e) {
      return OcrResult.failure(
        'Terjadi kendala saat membaca teks: ${e.toString()}',
      );
    }
  }

  /// Membersihkan whitespace berlebih, merapikan spasi ganda, baris kosong bertumpuk,
  /// serta menyambung kata yang terpotong tanda hubung di akhir baris OCR.
  String cleanOcrText(String rawText) {
    if (rawText.trim().isEmpty) return '';

    // 1. Normalisasi line-ending Windows CRLF (\r\n) menjadi LF (\n)
    var text = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 2. Sambung kembali kata yang terpotong tanda hubung di akhir baris (e.g. "membe-\nritahukan" -> "memberitahukan")
    text = text.replaceAllMapped(
      RegExp(r'(\w+)-[ \t]*\n[ \t]*(\w+)'),
      (match) => '${match[1]}${match[2]}',
    );

    // 3. Ubah spasi horizontal berturut-turut (spasi ganda / tab) menjadi satu spasi
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    // 4. Bersihkan spasi di awal dan akhir setiap baris
    final lines = text.split('\n').map((line) => line.trim()).toList();

    // 5. Batasi baris kosong berturut-turut maksimal 1 baris kosong (pemisah antar paragraf)
    final cleanedLines = <String>[];
    bool previousWasEmpty = false;

    for (final line in lines) {
      if (line.isEmpty) {
        if (!previousWasEmpty && cleanedLines.isNotEmpty) {
          cleanedLines.add('');
          previousWasEmpty = true;
        }
      } else {
        cleanedLines.add(line);
        previousWasEmpty = false;
      }
    }

    return cleanedLines.join('\n').trim();
  }

  /// Membersihkan sumber daya TextRecognizer setelah selesai digunakan.
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
