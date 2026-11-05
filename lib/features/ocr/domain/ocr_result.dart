/// Model representasi hasil pembacaan teks OCR dari dokumen/gambar.
class OcrResult {
  final String text;
  final bool isSuccess;
  final String? errorMessage;
  final int blocksCount;

  const OcrResult({
    required this.text,
    required this.isSuccess,
    this.errorMessage,
    this.blocksCount = 0,
  });

  factory OcrResult.success(String text, {int blocksCount = 0}) {
    return OcrResult(
      text: text,
      isSuccess: true,
      blocksCount: blocksCount,
    );
  }

  factory OcrResult.failure(String message) {
    return OcrResult(
      text: '',
      isSuccess: false,
      errorMessage: message,
    );
  }
}

