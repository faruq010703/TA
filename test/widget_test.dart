import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiread/core/constants/app_strings.dart';
import 'package:lexiread/features/ocr/data/ocr_service.dart';
import 'package:lexiread/features/ocr/presentation/screens/ocr_preprocessing_screen.dart';
import 'package:lexiread/features/ocr/presentation/screens/ocr_result_screen.dart';
import 'package:lexiread/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lexiread/features/reader/domain/models/reading_document.dart';
import 'package:lexiread/features/reader/domain/services/syllable_service.dart';
import 'package:lexiread/features/reader/domain/services/text_rank_summarizer.dart';
import 'package:lexiread/features/reader/domain/services/tts_service.dart';
import 'package:lexiread/features/reader/presentation/screens/reader_screen.dart';
import 'package:lexiread/features/reader/presentation/screens/summary_screen.dart';
import 'package:lexiread/features/settings/domain/reader_settings.dart';
import 'package:lexiread/features/settings/presentation/controllers/settings_controller.dart';
import 'package:lexiread/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      return 1;
    });
  });

  test('OcrService.cleanOcrText membersihkan whitespace berlebih & menyambung kata terpotong', () {
    final ocrService = OcrService();
    const rawOcr = '  Ini    adalah contoh   teks   \r\n'
        'yang   membe-\nritahukan tentang   disleksia.\n\n\n\n'
        'Paragraf baru dengan   spasi berlebih.   ';

    final cleaned = ocrService.cleanOcrText(rawOcr);

    // Kata terpotong tanda hubung harus tersambung
    expect(cleaned.contains('memberitahukan'), isTrue);
    // Tidak ada spasi ganda
    expect(cleaned.contains('   '), isFalse);
    // Tidak ada lebih dari satu baris kosong bertumpuk
    expect(cleaned.contains('\n\n\n'), isFalse);
  });

  test('SyllableService memenggal kata Bahasa Indonesia sesuai aturan fonotaktik', () {
    expect(SyllableService.formatWithHyphen('mempertahankan'), 'mem-per-tah-an-kan');
    expect(SyllableService.formatWithHyphen('disleksia'), 'dis-lek-si-a');
    expect(SyllableService.formatWithHyphen('membaca'), 'mem-ba-ca');
    expect(SyllableService.formatWithHyphen('komunitas'), 'ko-mu-ni-tas');
    expect(SyllableService.syllabify('banyak'), ['ba', 'nyak']);
  });

  test('TextRankSummarizer mengekstraksi kalimat inti dokumen secara mandiri', () {
    const docText =
        'Membaca adalah keterampilan penting bagi setiap orang dalam kehidupan sehari-hari. '
        'Bagi pembaca disleksia dewasa, teks padat dan rapat dapat menimbulkan kelelahan mata. '
        'Teknologi bantu baca memberikan kemudahan penyesuaian spasi baris dan ukuran huruf. '
        'Penggunaan Text-to-Speech memungkinkan pengguna mendengarkan pelafalan kata dengan jelas. '
        'Aplikasi LexiRead hadir sebagai solusi lengkap membaca ramah disleksia.';

    final summary = TextRankSummarizer.summarize(docText, maxSentences: 3);

    expect(summary.summarySentenceCount, inInclusiveRange(2, 3));
    expect(summary.combinedSummary.isNotEmpty, isTrue);
    expect(summary.sentences.first.text.isNotEmpty, isTrue);
  });

  test('ReaderSettings serialisasi dan preferensi SharedPreferences round-trip', () {
    const original = ReaderSettings(
      fontFamily: ReaderFontFamily.openDyslexic,
      fontSize: 22.0,
      lineSpacing: 2.1,
      letterSpacing: 1.2,
      wordSpacing: 2.2,
      enableLineShading: true,
      colorTheme: ReaderColorTheme.pastelYellow,
      speechRate: 0.52,
      pitch: 1.1,
      interWordPauseMs: 250,
      phonicSyllableColoring: true,
      showReadingRuler: false,
    );

    final map = original.toMap();
    final restored = ReaderSettings.fromMap(map);

    expect(restored.fontFamily, ReaderFontFamily.openDyslexic);
    expect(restored.fontSize, 22.0);
    expect(restored.lineSpacing, 2.1);
    expect(restored.letterSpacing, 1.2);
    expect(restored.wordSpacing, 2.2);
    expect(restored.enableLineShading, isTrue);
    expect(restored.colorTheme, ReaderColorTheme.pastelYellow);
    expect(restored.speechRate, 0.52);
    expect(restored.pitch, 1.1);
    expect(restored.interWordPauseMs, 250);
    expect(restored.phonicSyllableColoring, isTrue);
    expect(restored.showReadingRuler, isFalse);
  });

  test('TtsService kontrol navigasi dan kecepatan baca', () async {
    final ttsService = TtsService();
    await ttsService.initialize();

    await ttsService.setSpeechRate(0.65);
    expect(ttsService.speechRate, 0.65);

    expect(ttsService.playbackState, TtsPlaybackState.stopped);
    await ttsService.speak('Tes pembacaan audio');
    expect(ttsService.playbackState, TtsPlaybackState.playing);

    await ttsService.pause();
    expect(ttsService.playbackState, TtsPlaybackState.paused);

    await ttsService.stop();
    expect(ttsService.playbackState, TtsPlaybackState.stopped);

    ttsService.dispose();
  });

  testWidgets('LexiRead smoke test - verify action cards render in HomeScreen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_completed_onboarding': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LexiReadApp(hasCompletedOnboarding: true),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan 3 kartu aksi utama tampil di layar beranda
    expect(find.text(AppStrings.actionCameraTitle), findsOneWidget);
    expect(find.text(AppStrings.actionUploadTitle), findsOneWidget);
    expect(find.text(AppStrings.actionPasteTitle), findsOneWidget);

    // Pastikan FAB kamera dan statistik membaca tampil
    expect(find.text('Pindai Dokumen Baru'), findsOneWidget);
    expect(find.text('Waktu Membaca'), findsOneWidget);
    expect(find.text('Tuntas 100%'), findsOneWidget);
  });

  testWidgets('OnboardingScreen calibration controls and navigation flow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi elemen visual kalibrasi kenyamanan membaca
    expect(find.text('Kalibrasi Kenyamanan Membaca'), findsOneWidget);
    expect(find.text('KARTU PRATINJAU TEKS'), findsOneWidget);
    expect(find.text('Ukuran Font'), findsOneWidget);
    expect(find.text('Palet Warna Latar Ramah Mata'), findsOneWidget);
    expect(find.text('Krem'), findsOneWidget);
    expect(find.text('Peach'), findsOneWidget);
    expect(find.text('Biru Pastel'), findsOneWidget);
    expect(find.text('Abu Lembut'), findsOneWidget);

    // Verifikasi tombol 'Lewati' dan 'Mulai Membaca'
    expect(find.byKey(const Key('skip_onboarding_button')), findsOneWidget);
    expect(find.byKey(const Key('start_reading_button')), findsOneWidget);

    // Uji interaksi pemilihan warna tema Peach
    await tester.ensureVisible(find.text('Peach'));
    await tester.tap(find.text('Peach'));
    await tester.pumpAndSettle();

    // Uji klik Mulai Membaca
    await tester.tap(find.byKey(const Key('start_reading_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('OcrPreprocessingScreen UI controls render',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OcrPreprocessingScreen(
            imagePath: 'dummy_sample.jpg',
            documentTitle: 'Bab 4: Analisis Data',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pra-Pemrosesan Dokumen'), findsOneWidget);
    expect(find.text('Grayscale'), findsOneWidget);
    expect(find.text('Biner (Tajam)'), findsOneWidget);
    expect(find.text('Proses Ekstraksi OCR Sekarang'), findsOneWidget);
  });

  testWidgets('OcrResultScreen metrics and actions render',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OcrResultScreen(
            rawText: 'Contoh teks hasil ekstraksi bab 4 analisis data.',
            documentTitle: 'Bab 4: Analisis Data',
            blocksCount: 3,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hasil Ekstraksi OCR'), findsOneWidget);
    expect(find.text('ANALISIS DATA OCR'), findsOneWidget);
    expect(find.text('Akurasi 98.4%'), findsOneWidget);
    expect(find.text('Buka di Layar Baca'), findsOneWidget);
    expect(find.text('Salin Teks'), findsOneWidget);
  });

  testWidgets('SummaryScreen TextRank and Read-Along render',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SummaryScreen(
            fullText:
                'Kalimat pertama dokumen. Kalimat kedua yang penting. Kalimat ketiga penjelas.',
            documentTitle: 'Dokumen Uji',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Dokumen'), findsOneWidget);
    expect(find.text('TextRank Ekstraktif'), findsOneWidget);
    expect(find.text('Dengarkan Ringkasan Audio'), findsOneWidget);
    expect(find.text('Kirim ke WhatsApp / Grup'), findsOneWidget);
  });

  testWidgets('ReaderScreen interaksi pemenggalan suku kata, ringkasan, dan kontrol audio',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testDoc = ReadingDocument(
      id: 'test_doc',
      title: 'Dokumen Uji',
      content:
          'Membaca buku dapat mempertahankan fokus mata pembaca disleksia dewasa. '
          'Pengaturan format teks sangat membantu membaca nyaman.',
      snippet: 'Membaca buku...',
      sourceType: DocumentSourceType.camera,
      createdAt: DateTime.now(),
      lastReadAt: DateTime.now(),
      totalWords: 15,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: ReaderScreen(document: testDoc),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dokumen Uji'), findsOneWidget);

    // 1. Verifikasi tombol Ringkas dokumen tersedia
    expect(find.text('Ringkas'), findsOneWidget);

    // 2. Verifikasi ketuk kata "mempertahankan" membuka SyllableDialog
    await tester.tap(find.text('mempertahankan'));
    await tester.pumpAndSettle();

    expect(find.text('Pemisahan Suku Kata'), findsOneWidget);
    expect(find.text('mem-per-tah-an-kan'), findsOneWidget);

    // Tutup SyllableDialog
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    // 3. Verifikasi tombol navigasi audio Bacakan dan kontrol tersedia
    expect(find.text('Bacakan'), findsOneWidget);
    expect(find.byTooltip('Hentikan Audio'), findsOneWidget);
    expect(find.byTooltip('Mundur 10 Detik / Kalimat Sebelumnya'), findsOneWidget);
    expect(find.byTooltip('Maju 10 Detik / Kalimat Berikutnya'), findsOneWidget);
  });
}
