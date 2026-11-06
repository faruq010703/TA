import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/screens/appearance_settings_screen.dart';
import '../../domain/models/reading_document.dart';
import '../../domain/services/tts_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/syllable_dialog.dart';
import 'summary_screen.dart';

/// Struktur blok paragraf untuk pemetaan penyorotan kata dan auto-scrolling
class _ParagraphBlock {
  final int index;
  final String text;
  final int globalCharStart;
  final int globalCharEnd;

  const _ParagraphBlock({
    required this.index,
    required this.text,
    required this.globalCharStart,
    required this.globalCharEnd,
  });
}

/// Layar Baca Adaptif (ReaderScreen - Sesuai screen.png):
/// Fitur:
/// - Header: "← Kembali", Judul dokumen, ikon buku, ikon tipografi "TT"
/// - Sub-header: Chip halaman ("Halaman 1 dari 4") & chip estimasi waktu baca
/// - Tombol Pill: "💡 Buka Ringkasan Cepat (AI)"
/// - Teks Bacaan: Font Lexend/OpenDyslexic, jarak baris 1.8x, penanda garis biru di kiri paragraf aktif
/// - Fitur Read-Along: Highlight kata berwarna kuning pastel sinkron dengan kata TTS secara real-time
/// - Interaksi Kata Sulit: Kata bergaris bawah putus-putus bisa diklik untuk memunculkan tooltip pemenggalan suku kata
/// - Floating Audio Bar: Slider durasi (01:42 / 04:20), tombol -5s, Play/Pause bundar biru, +5s, dan tombol pengatur kecepatan (0.75x, 1.0x, 1.25x)
/// - Kartu "Catatan Pendukung (Dual-Coding)" di bawah teks
class ReaderScreen extends ConsumerStatefulWidget {
  final ReadingDocument document;

  const ReaderScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late ReadingDocument _currentDoc;
  late final ScrollController _scrollController;
  late final TtsService _ttsService;

  TtsPlaybackState _ttsState = TtsPlaybackState.stopped;
  StreamSubscription<TtsPlaybackState>? _ttsSubscription;
  StreamSubscription<TtsWordHighlight>? _highlightSubscription;

  TtsWordHighlight _currentHighlight = TtsWordHighlight.empty;
  final Map<int, GlobalKey> _paragraphKeys = {};
  List<_ParagraphBlock> _paragraphs = [];
  int _lastAutoScrolledParagraph = -1;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.document;
    _scrollController = ScrollController();
    _ttsService = ref.read(ttsServiceProvider);

    _parseParagraphs();
    _initTtsListeners();
  }

  void _parseParagraphs() {
    _paragraphKeys.clear();
    final blocks = <_ParagraphBlock>[];
    final fullText = _currentDoc.content;
    final lines = fullText.split('\n');

    int currentOffset = 0;
    int paragraphIdx = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        final startIndex = fullText.indexOf(trimmed, currentOffset);
        final endIndex = startIndex >= 0
            ? startIndex + trimmed.length
            : currentOffset + trimmed.length;

        final actualStart = startIndex >= 0 ? startIndex : currentOffset;
        final actualEnd = endIndex;

        final block = _ParagraphBlock(
          index: paragraphIdx,
          text: trimmed,
          globalCharStart: actualStart,
          globalCharEnd: actualEnd,
        );

        blocks.add(block);
        _paragraphKeys[paragraphIdx] = GlobalKey();
        paragraphIdx++;

        currentOffset = actualEnd;
      }
    }

    if (blocks.isEmpty) {
      blocks.add(_ParagraphBlock(
        index: 0,
        text: fullText,
        globalCharStart: 0,
        globalCharEnd: fullText.length,
      ));
      _paragraphKeys[0] = GlobalKey();
    }

    _paragraphs = blocks;
  }

  void _initTtsListeners() {
    _ttsState = _ttsService.playbackState;

    _ttsSubscription = _ttsService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _ttsState = state;
        });
      }
    });

    _highlightSubscription = _ttsService.highlightStream.listen((highlight) {
      if (mounted) {
        setState(() {
          _currentHighlight = highlight;
        });

        if (highlight.isActive) {
          _checkAutoScroll(highlight);
          _updateReadingProgress(highlight);
        }
      }
    });

    _scrollController.addListener(_onManualScroll);
  }

  void _updateReadingProgress(TtsWordHighlight highlight) {
    if (highlight.wordIndex >= 0 && _currentDoc.totalWords > 0) {
      final newIndex = highlight.wordIndex.clamp(0, _currentDoc.totalWords);
      if ((newIndex - _currentDoc.currentWordIndex).abs() >= 2) {
        setState(() {
          _currentDoc = _currentDoc.copyWith(currentWordIndex: newIndex);
        });
        ref
            .read(homeControllerProvider.notifier)
            .updateDocumentProgress(_currentDoc.id, newIndex);
      }
    }
  }

  void _onManualScroll() {
    if (_scrollController.hasClients && _currentDoc.totalWords > 0) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll <= 0) return;

      final ratio = (currentScroll / maxScroll).clamp(0.0, 1.0);
      final wordEstimate = (ratio * _currentDoc.totalWords).round();

      if ((wordEstimate - _currentDoc.currentWordIndex).abs() > 4) {
        setState(() {
          _currentDoc = _currentDoc.copyWith(currentWordIndex: wordEstimate);
        });
        ref
            .read(homeControllerProvider.notifier)
            .updateDocumentProgress(_currentDoc.id, wordEstimate);
      }
    }
  }

  void _checkAutoScroll(TtsWordHighlight highlight) {
    for (final block in _paragraphs) {
      if (highlight.charStart >= block.globalCharStart &&
          highlight.charStart < block.globalCharEnd) {
        if (_lastAutoScrolledParagraph != block.index) {
          _lastAutoScrolledParagraph = block.index;
          final key = _paragraphKeys[block.index];
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              alignment: 0.28,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
            );
          }
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _ttsSubscription?.cancel();
    _highlightSubscription?.cancel();
    _ttsService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playTts() async {
    final settings = ref.read(settingsControllerProvider);
    await _ttsService.setSpeechRate(settings.speechRate);
    await _ttsService.setPitch(settings.pitch);

    if (_ttsState == TtsPlaybackState.paused && _currentHighlight.charStart > 0) {
      await _ttsService.speak(
        _currentDoc.content,
        fromCharIndex: _currentHighlight.charStart,
      );
    } else {
      await _ttsService.speak(_currentDoc.content);
    }
  }

  Future<void> _pauseTts() async {
    await _ttsService.pause();
  }

  Future<void> _stopTts() async {
    await _ttsService.stop();
    setState(() {
      _currentHighlight = TtsWordHighlight.empty;
      _lastAutoScrolledParagraph = -1;
    });
  }

  void _openAppearanceSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppearanceSettingsScreen(),
      ),
    );
  }

  void _openSummaryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(
          fullText: _currentDoc.content,
          documentTitle: _currentDoc.title,
        ),
      ),
    );
  }

  bool _isDifficultWord(String word) {
    final clean = word.toLowerCase();
    if (clean.length >= 7) return true;
    const difficultWords = {
      'metakognitif',
      'metakognisi',
      'pembelajaran',
      'mempertahankan',
      'perkembangan',
      'karakteristik',
      'konvensional',
      'penelitian',
      'keterampilan',
      'kesadaran',
      'pendekatan',
      'signifikan',
      'ekstraksi',
      'aksesibilitas',
      'disleksia',
      'pemahaman',
    };
    return difficultWords.contains(clean);
  }

  String _formatReadingTime(int wordCount) {
    final minutes = (wordCount / 120).ceil().clamp(1, 60);
    return '⏱ $minutes Menit Baca';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = settings.colorTheme;

    // Hitung posisi durasi saat ini
    final currentWords = _currentHighlight.wordIndex >= 0
        ? _currentHighlight.wordIndex
        : _currentDoc.currentWordIndex;
    final totalWords = _currentDoc.totalWords > 0 ? _currentDoc.totalWords : 100;
    final totalSeconds = (totalWords * 0.5).round();
    final elapsedSeconds = (currentWords * 0.5).round().clamp(0, totalSeconds);

    final elapsedMinStr = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final elapsedSecStr = (elapsedSeconds % 60).toString().padLeft(2, '0');
    final totalMinStr = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final totalSecStr = (totalSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 26),
          tooltip: 'Kembali ke Beranda',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentDoc.title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.textColor,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Ikon Tipografi "TT"
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: theme.shadingColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(color: theme.borderColor),
              ),
              child: Text(
                'TT',
                style: AppTextStyles.badge.copyWith(
                  color: theme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            tooltip: 'Pengaturan Tampilan Baca (TT)',
            onPressed: _openAppearanceSettings,
          ),
          const SizedBox(width: AppDimens.space8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppDimens.space16,
              right: AppDimens.space16,
              top: AppDimens.space12,
              bottom: 180.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SUB-HEADER: Chip Halaman & Chip Estimasi Waktu Baca
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surfaceColor,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusS),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Text(
                            'Halaman 1 dari 4',
                            style: AppTextStyles.badge.copyWith(
                              color: theme.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surfaceColor,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusS),
                            border: Border.all(color: theme.borderColor),
                          ),
                          child: Text(
                            _formatReadingTime(_currentDoc.totalWords),
                            style: AppTextStyles.badge.copyWith(
                              color: theme.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // TOMBOL PILL: "💡 Buka Ringkasan Cepat (AI)"
                    TextButton.icon(
                      onPressed: _openSummaryScreen,
                      icon: const Icon(
                        Icons.lightbulb_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      label: Text(
                        'Ringkasan Cepat (AI)',
                        style: AppTextStyles.badge.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF9E8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusL),
                          side: const BorderSide(color: Color(0xFFE8DCC2)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.space16),

                // DAFTAR PARAGRAF BACAAN ADAPTIF
                ..._paragraphs.map((block) {
                  final isEven = block.index.isEven;
                  final isShaded = settings.enableLineShading && !isEven;

                  // Penanda garis biru di kiri paragraf aktif yang sedang dibacakan
                  final isParagraphActive = _currentHighlight.isActive &&
                      _currentHighlight.charStart >= block.globalCharStart &&
                      _currentHighlight.charStart < block.globalCharEnd;

                  return Container(
                    key: _paragraphKeys[block.index],
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: isShaded ? theme.shadingColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border(
                        left: BorderSide(
                          color: isParagraphActive
                              ? const Color(0xFF2563EB) // Garis biru penanda aktif
                              : (isShaded
                                  ? theme.borderColor.withValues(alpha: 0.6)
                                  : Colors.transparent),
                          width: isParagraphActive ? 3.5 : 1.0,
                        ),
                        top: BorderSide(
                          color: isShaded ? theme.borderColor.withValues(alpha: 0.6) : Colors.transparent,
                        ),
                        right: BorderSide(
                          color: isShaded ? theme.borderColor.withValues(alpha: 0.6) : Colors.transparent,
                        ),
                        bottom: BorderSide(
                          color: isShaded ? theme.borderColor.withValues(alpha: 0.6) : Colors.transparent,
                        ),
                      ),
                    ),
                    child: _buildParagraphText(
                      block: block,
                      settings: settings,
                      theme: theme,
                    ),
                  );
                }),

                const SizedBox(height: AppDimens.space20),

                // KARTU "CATATAN PENDUKUNG (DUAL-CODING)" DI BAWAH TEKS
                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFFAF7EF),
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(color: theme.borderColor, width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF5FB),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan Pendukung (Dual-Coding)',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.textColor,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dual-Coding mengaktifkan jalur visual dan auditori otak secara serentak untuk memudahkan pemahaman makna kalimat yang kompleks tanpa kelelahan kognitif.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.textColor.withValues(alpha: 0.8),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FLOATING AUDIO BAR DI BAGIAN BAWAH (Sesuai screen.png)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space10,
              ),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.radiusXL),
                ),
                border: Border.all(color: theme.borderColor, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slider Durasi (01:42 / 04:20)
                    Row(
                      children: [
                        Text(
                          '$elapsedMinStr:$elapsedSecStr',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF2563EB),
                              inactiveTrackColor:
                                  theme.textColor.withValues(alpha: 0.15),
                              thumbColor: const Color(0xFF2563EB),
                              trackHeight: 3.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: elapsedSeconds
                                  .toDouble()
                                  .clamp(0.0, totalSeconds.toDouble()),
                              min: 0.0,
                              max: totalSeconds > 0
                                  ? totalSeconds.toDouble()
                                  : 100.0,
                              onChanged: (val) {
                                final charRatio = val / totalSeconds;
                                final charTarget = (charRatio *
                                        _currentDoc.content.length)
                                    .round();
                                _ttsService.speak(
                                  _currentDoc.content,
                                  fromCharIndex: charTarget,
                                );
                              },
                            ),
                          ),
                        ),
                        Text(
                          '$totalMinStr:$totalSecStr',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),

                    // Baris Tombol Kontrol: -5s, Play/Pause Bulat Biru, +5s, dan Kecepatan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Pengatur Kecepatan (0.75x, 1.0x, 1.25x)
                        PopupMenuButton<double>(
                          initialValue: settings.speechRate,
                          onSelected: (val) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateSpeechRate(val);
                            _ttsService.setSpeechRate(val);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.shadingColor,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              border: Border.all(color: theme.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${settings.speechRate.toStringAsFixed(2)}x',
                                  style: AppTextStyles.badge.copyWith(
                                    color: theme.textColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 18,
                                  color: theme.textColor,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 0.75,
                              child: Text('0.75x (Santai)'),
                            ),
                            const PopupMenuItem(
                              value: 1.0,
                              child: Text('1.00x (Normal)'),
                            ),
                            const PopupMenuItem(
                              value: 1.25,
                              child: Text('1.25x (Tangkas)'),
                            ),
                          ],
                        ),

                        // Tombol Kontrol Tengah: -5s, Play/Pause Bulat Biru, +5s
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol -5 detik
                            IconButton(
                              onPressed: () => _ttsService.jumpOffset(-30),
                              icon: const Icon(Icons.replay_5_rounded, size: 28),
                              color: theme.textColor,
                              tooltip: 'Mundur 5 Detik',
                            ),
                            const SizedBox(width: 10),

                            // Tombol Play / Pause Bundar Biru
                            GestureDetector(
                              onTap: _ttsState != TtsPlaybackState.playing
                                  ? _playTts
                                  : _pauseTts,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x332563EB),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _ttsState == TtsPlaybackState.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tombol +5 detik
                            IconButton(
                              onPressed: () => _ttsService.jumpOffset(30),
                              icon: const Icon(Icons.forward_5_rounded, size: 28),
                              color: theme.textColor,
                              tooltip: 'Maju 5 Detik',
                            ),
                          ],
                        ),

                        // Tombol Hentikan Audio
                        IconButton(
                          onPressed: _ttsState != TtsPlaybackState.stopped
                              ? _stopTts
                              : null,
                          icon: const Icon(Icons.stop_circle_outlined, size: 28),
                          color: AppColors.error,
                          tooltip: 'Hentikan',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun teks paragraf dengan penyorotan kata Read-Along real-time
  /// dan interaksi garis putus-putus pada kata majemuk / sulit
  Widget _buildParagraphText({
    required _ParagraphBlock block,
    required ReaderSettings settings,
    required ReaderColorTheme theme,
  }) {
    final baseStyle = settings.fontFamily.getTextStyle(
      fontSize: settings.fontSize,
      height: settings.lineSpacing,
      letterSpacing: settings.letterSpacing,
      wordSpacing: settings.wordSpacing,
      color: theme.textColor,
      fontWeight: FontWeight.w400,
    );

    final words = block.text.split(RegExp(r'\s+'));
    int runningCharOffset = block.globalCharStart;

    return Wrap(
      spacing: 6.0,
      runSpacing: 5.0,
      children: words.map((rawWord) {
        final cleanWord = rawWord.replaceAll(RegExp(r'[^\w]'), '');
        final wordStart = block.text.indexOf(
                rawWord, runningCharOffset - block.globalCharStart) +
            block.globalCharStart;
        final wordEnd = wordStart + rawWord.length;
        runningCharOffset = wordEnd;

        // Cek penyorotan kata aktif TTS (Read-Along)
        final isHighlighted = settings.syncWordHighlight &&
            _currentHighlight.isActive &&
            ((_currentHighlight.charStart >= wordStart &&
                    _currentHighlight.charStart < wordEnd) ||
                (_currentHighlight.word.toLowerCase() ==
                        cleanWord.toLowerCase() &&
                    cleanWord.isNotEmpty &&
                    _currentHighlight.charStart >= block.globalCharStart &&
                    _currentHighlight.charStart < block.globalCharEnd));

        final isDifficult =
            settings.autoSyllableSplit && _isDifficultWord(cleanWord);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (cleanWord.isNotEmpty) {
              SyllableDialog.show(
                context,
                word: cleanWord,
                ttsService: _ttsService,
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isHighlighted ? 5.0 : 1.0,
              vertical: isHighlighted ? 2.0 : 0.0,
            ),
            decoration: isHighlighted
                ? BoxDecoration(
                    color: AppColors.highlightWord, // Kuning pastel #FFF3A8
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.highlightWordBorder,
                      width: 1.2,
                    ),
                  )
                : null,
            child: Text(
              rawWord,
              style: isHighlighted
                  ? baseStyle.copyWith(
                      color: AppColors.highlightWordText,
                      fontWeight: FontWeight.w800,
                    )
                  : (isDifficult
                      ? baseStyle.copyWith(
                          color: theme.textColor,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dashed,
                          decorationColor: const Color(0xFF2563EB),
                          decorationThickness: 1.8,
                        )
                      : baseStyle.copyWith(color: theme.textColor)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
