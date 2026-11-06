import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../ocr/presentation/ocr_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/repositories/reading_history_repository.dart';
import '../../domain/models/reading_document.dart';
import '../../domain/services/pdf_extractor_service.dart';
import '../../domain/services/tts_service.dart';

/// Provider repositori riwayat bacaan
final readingHistoryRepositoryProvider =
    Provider<IReadingHistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReadingHistoryRepository(prefs);
});

/// Provider layanan Text to Speech
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  service.initialize();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// State untuk Layar Beranda
class HomeState {
  final List<ReadingDocument> history;
  final bool isLoading;
  final String loadingTitle;
  final String loadingSubtitle;
  final String? errorMessage;

  const HomeState({
    this.history = const [],
    this.isLoading = false,
    this.loadingTitle = '',
    this.loadingSubtitle = '',
    this.errorMessage,
  });

  HomeState copyWith({
    List<ReadingDocument>? history,
    bool? isLoading,
    String? loadingTitle,
    String? loadingSubtitle,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      loadingTitle: loadingTitle ?? this.loadingTitle,
      loadingSubtitle: loadingSubtitle ?? this.loadingSubtitle,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier pengontrol alur bisnis Beranda dan Masukan Dokumen
class HomeNotifier extends Notifier<HomeState> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  HomeState build() {
    Future.microtask(() => loadHistory());
    return const HomeState();
  }

  Future<void> loadHistory() async {
    final repo = ref.read(readingHistoryRepositoryProvider);
    final docs = await repo.getDocuments();
    state = state.copyWith(history: docs);
  }

  void cancelLoading() {
    state = state.copyWith(isLoading: false);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Memilih citra dari kamera atau galeri untuk diarahkan ke layar pra-pemrosesan OCR
  Future<String?> pickImagePath({required ImageSource source}) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      return photo?.path;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Gagal mengambil gambar: $e',
      );
      return null;
    }
  }

  /// 1. Aksi Ambil Foto Dokumen melalui Kamera
  Future<ReadingDocument?> pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );

      if (photo == null) return null;

      state = state.copyWith(
        isLoading: true,
        loadingTitle: AppStrings.loadingOcrTitle,
        loadingSubtitle: AppStrings.loadingOcrSubtitle,
        clearError: true,
      );

      final ocrService = ref.read(ocrServiceProvider);
      final ocrResult = await ocrService.processImageFromPath(photo.path);

      state = state.copyWith(isLoading: false);

      if (!ocrResult.isSuccess || ocrResult.text.isEmpty) {
        state = state.copyWith(
          errorMessage: ocrResult.errorMessage ?? AppStrings.errorNoTextFound,
        );
        return null;
      }

      final now = DateTime.now();
      final snippet = AccessibilityUtils.createSnippet(ocrResult.text);
      final title = 'Foto Dokumen ${AccessibilityUtils.formatFriendlyDate(now)}';
      final totalWords = AccessibilityUtils.countWords(ocrResult.text);

      final newDoc = ReadingDocument(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: title,
        content: ocrResult.text,
        snippet: snippet,
        sourceType: DocumentSourceType.camera,
        createdAt: now,
        lastReadAt: now,
        currentWordIndex: 0,
        totalWords: totalWords,
      );

      final repo = ref.read(readingHistoryRepositoryProvider);
      await repo.saveDocument(newDoc);
      await loadHistory();
      return newDoc;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengambil foto: ${e.toString()}',
      );
      return null;
    }
  }

  /// Aksi Ambil Gambar dari Galeri Foto (dengan OCR Google ML Kit)
  Future<ReadingDocument?> pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (photo == null) return null;

      state = state.copyWith(
        isLoading: true,
        loadingTitle: AppStrings.loadingOcrTitle,
        loadingSubtitle: AppStrings.loadingOcrSubtitle,
        clearError: true,
      );

      final ocrService = ref.read(ocrServiceProvider);
      final ocrResult = await ocrService.processImageFromPath(photo.path);

      state = state.copyWith(isLoading: false);

      if (!ocrResult.isSuccess || ocrResult.text.isEmpty) {
        state = state.copyWith(
          errorMessage: ocrResult.errorMessage ?? AppStrings.errorNoTextFound,
        );
        return null;
      }

      final now = DateTime.now();
      final snippet = AccessibilityUtils.createSnippet(ocrResult.text);
      final title = 'Foto Galeri ${AccessibilityUtils.formatFriendlyDate(now)}';
      final totalWords = AccessibilityUtils.countWords(ocrResult.text);

      final newDoc = ReadingDocument(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: title,
        content: ocrResult.text,
        snippet: snippet,
        sourceType: DocumentSourceType.file,
        createdAt: now,
        lastReadAt: now,
        currentWordIndex: 0,
        totalWords: totalWords,
      );

      final repo = ref.read(readingHistoryRepositoryProvider);
      await repo.saveDocument(newDoc);
      await loadHistory();
      return newDoc;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memilih gambar dari galeri: ${e.toString()}',
      );
      return null;
    }
  }

  /// 2. Aksi Unggah Berkas / Dokumen (PDF atau Gambar)
  Future<ReadingDocument?> pickFromFileOrGallery() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'txt'],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      state = state.copyWith(
        isLoading: true,
        loadingTitle: AppStrings.loadingFileTitle,
        loadingSubtitle: AppStrings.loadingFileSubtitle,
        clearError: true,
      );

      String extractedText = '';

      if (FileUtils.isImageFile(filePath)) {
        state = state.copyWith(
          loadingTitle: AppStrings.loadingOcrTitle,
          loadingSubtitle: AppStrings.loadingOcrSubtitle,
        );
        final ocrService = ref.read(ocrServiceProvider);
        final ocrResult = await ocrService.processImageFromPath(filePath);

        if (!ocrResult.isSuccess || ocrResult.text.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: ocrResult.errorMessage ?? AppStrings.errorNoTextFound,
          );
          return null;
        }
        extractedText = ocrResult.text;
      } else if (FileUtils.isTextFile(filePath)) {
        final file = File(filePath);
        extractedText = await file.readAsString();
      } else if (FileUtils.isPdfFile(filePath)) {
        state = state.copyWith(
          loadingTitle: 'Mengekstrak Dokumen PDF...',
          loadingSubtitle:
              'Membaca seluruh halaman dokumen secara menyeluruh...',
        );
        final pdfExtractor = ref.read(pdfExtractorServiceProvider);
        extractedText = await pdfExtractor.extractText(filePath);
      } else {
        extractedText = 'Isi berkas dari: $fileName';
      }

      state = state.copyWith(isLoading: false);

      if (extractedText.trim().isEmpty) {
        state = state.copyWith(errorMessage: AppStrings.errorNoTextFound);
        return null;
      }

      final now = DateTime.now();
      final snippet = AccessibilityUtils.createSnippet(extractedText);
      final totalWords = AccessibilityUtils.countWords(extractedText);

      final newDoc = ReadingDocument(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: fileName,
        content: extractedText,
        snippet: snippet,
        sourceType: DocumentSourceType.file,
        createdAt: now,
        lastReadAt: now,
        currentWordIndex: 0,
        totalWords: totalWords,
      );

      final repo = ref.read(readingHistoryRepositoryProvider);
      await repo.saveDocument(newDoc);
      await loadHistory();
      return newDoc;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuka berkas: ${e.toString()}',
      );
      return null;
    }
  }

  /// 3. Aksi Masukan Teks Manual
  Future<ReadingDocument> addManualText(String title, String content) async {
    final now = DateTime.now();
    final snippet = AccessibilityUtils.createSnippet(content);
    final totalWords = AccessibilityUtils.countWords(content);

    final newDoc = ReadingDocument(
      id: 'doc_${now.millisecondsSinceEpoch}',
      title: title.isEmpty ? 'Teks Catatan' : title,
      content: content,
      snippet: snippet,
      sourceType: DocumentSourceType.manual,
      createdAt: now,
      lastReadAt: now,
      currentWordIndex: 0,
      totalWords: totalWords,
    );

    final repo = ref.read(readingHistoryRepositoryProvider);
    await repo.saveDocument(newDoc);
    await loadHistory();
    return newDoc;
  }

  /// Hapus dokumen dari riwayat
  Future<void> deleteDocument(String id) async {
    final repo = ref.read(readingHistoryRepositoryProvider);
    await repo.deleteDocument(id);
    await loadHistory();
  }

  /// Memperbarui progres baca
  Future<void> updateDocumentProgress(String id, int currentWordIndex) async {
    final repo = ref.read(readingHistoryRepositoryProvider);
    await repo.updateProgress(id, currentWordIndex);
    await loadHistory();
  }
}

final homeControllerProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
