import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiread/core/constants/app_strings.dart';
import 'package:lexiread/features/ocr/data/ocr_service.dart';
import 'package:lexiread/features/reader/domain/models/reading_document.dart';
import 'package:lexiread/features/reader/domain/services/syllable_service.dart';
import 'package:lexiread/features/reader/domain/services/text_rank_summarizer.dart';
import 'package:lexiread/features/reader/domain/services/tts_service.dart';
import 'package:lexiread/features/reader/presentation/screens/reader_screen.dart';
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
      enableLineShading: true,
      colorTheme: ReaderColorTheme.pastelYellow,
      speechRate: 0.52,
      showReadingRuler: false,
    );

    final map = original.toMap();
    final restored = ReaderSettings.fromMap(map);

    expect(restored.fontFamily, ReaderFontFamily.openDyslexic);
    expect(restored.fontSize, 22.0);
    expect(restored.lineSpacing, 2.1);
    expect(restored.letterSpacing, 1.2);
    expect(restored.enableLineShading, isTrue);
    expect(restored.colorTheme, ReaderColorTheme.pastelYellow);
    expect(restored.speechRate, 0.52);
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

  testWidgets('LexiRead smoke test - verify action cards render',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LexiReadApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan 3 kartu aksi utama tampil di layar beranda
    expect(find.text(AppStrings.actionCameraTitle), findsOneWidget);
    expect(find.text(AppStrings.actionUploadTitle), findsOneWidget);
    expect(find.text(AppStrings.actionPasteTitle), findsOneWidget);
  });

  testWidgets('ReaderScreen interaksi pemenggalan suku kata, tombol ringkas, dan panel pengaturan',
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

    // 1. Verifikasi tombol Ringkas dokumen tersedia dan membuka SummarySheet
    expect(find.text('Ringkas'), findsOneWidget);
    await tester.tap(find.text('Ringkas'));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Inti Dokumen'), findsOneWidget);

    // Tutup SummarySheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // 2. Verifikasi ketuk kata "mempertahankan" membuka SyllableDialog
    await tester.tap(find.text('mempertahankan'));
    await tester.pumpAndSettle();

    expect(find.text('Pemisahan Suku Kata'), findsOneWidget);
    expect(find.text('mem-per-tah-an-kan'), findsOneWidget);

    // Tutup SyllableDialog
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    // 3. Verifikasi tombol navigasi audio Play, Pause, dan Stop tersedia
    expect(find.text('Bacakan'), findsOneWidget);
    expect(find.byTooltip('Jeda Suara'), findsOneWidget);
    expect(find.byTooltip('Berhenti & Hapus Sorotan'), findsOneWidget);
  });
}
