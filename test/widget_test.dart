import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiread/core/constants/app_strings.dart';
import 'package:lexiread/features/ocr/data/ocr_service.dart';
import 'package:lexiread/features/reader/domain/models/reading_document.dart';
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

  testWidgets('ReaderScreen renders text, audio navigation controls (Play, Pause, Stop), and settings sheet',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testDoc = ReadingDocument(
      id: 'test_doc',
      title: 'Dokumen Uji',
      content:
          'Paragraf pertama untuk pembaca disleksia.\n\nParagraf kedua teks adaptif.',
      snippet: 'Paragraf pertama...',
      sourceType: DocumentSourceType.camera,
      createdAt: DateTime.now(),
      lastReadAt: DateTime.now(),
      totalWords: 10,
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
    expect(find.textContaining('Paragraf pertama'), findsOneWidget);
    expect(find.textContaining('Paragraf kedua'), findsOneWidget);

    // Verifikasi tombol navigasi audio Play, Pause, dan Stop tersedia
    expect(find.text('Bacakan'), findsOneWidget);
    expect(find.byTooltip('Jeda Suara'), findsOneWidget);
    expect(find.byTooltip('Berhenti & Hapus Sorotan'), findsOneWidget);

    // Buka bottom sheet format teks
    await tester.tap(find.byTooltip('Format Teks & Font'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Baca'), findsOneWidget);
    expect(find.text('Warna Latar & Kontras'), findsOneWidget);
  });
}
