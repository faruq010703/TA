import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/reading_document.dart';
import '../../domain/services/syllable_service.dart';
import '../../domain/services/tts_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/advanced_audio_sheet.dart';
import '../widgets/reading_progress_bar.dart';
import '../widgets/syllable_dialog.dart';
import '../widgets/typography_sheet.dart';
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

/// Layar pembaca teks adaptif ramah disleksia dewasa:
/// Menampilkan teks dengan tipografi adaptif, fitur penyorotan kata Read-Along real-time,
/// pemenggalan fonik suku kata berwarna bergantian, floating control bar audio,
/// dan penggaris fokus baca interaktif (reading ruler).
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

  double _rulerOffsetY = 240.0;
  bool _isRulerEnabled = false;
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
              alignment: 0.32,
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

  void _openTypographySheet() {
    TypographySheet.show(context);
  }

  void _openAdvancedAudioSheet() {
    AdvancedAudioSheet.show(context, ttsService: _ttsService);
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = settings.colorTheme;
    final isRulerVisible = settings.showReadingRuler && _isRulerEnabled;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: 'Kembali ke Beranda',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentDoc.title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${(_currentDoc.progressRatio * 100).toStringAsFixed(0)}% telah dibaca',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: theme.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Tombol Ringkas Dokumen (TextRank)
          TextButton.icon(
            onPressed: _openSummaryScreen,
            icon: const Icon(
              Icons.auto_stories_rounded,
              size: 17,
              color: AppColors.actionUploadIcon,
            ),
            label: Text(
              'Ringkas',
              style: AppTextStyles.badge.copyWith(
                fontSize: 12,
                color: AppColors.actionUploadIcon,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.actionUploadIconBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                side: const BorderSide(color: AppColors.actionUploadBorder),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Tombol Setelan Tipografi (Aa)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: theme.shadingColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(color: theme.borderColor),
              ),
              child: Text(
                'Aa',
                style: AppTextStyles.badge.copyWith(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            tooltip: 'Pengaturan Tipografi (Aa)',
            onPressed: _openTypographySheet,
          ),

          // Tombol Audio Lanjutan (Equalizer)
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              size: 22,
              color: theme.textColor,
            ),
            tooltip: 'Setelan Audio Lanjutan',
            onPressed: _openAdvancedAudioSheet,
          ),
          const SizedBox(width: AppDimens.space8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
            child: ReadingProgressBar(
              ratio: _currentDoc.progressRatio,
              currentWords: _currentDoc.currentWordIndex,
              totalWords: _currentDoc.totalWords,
              showLabel: false,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // KONTEN TEKS HASIL EKSTRAKSI ADAPTIF
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppDimens.space16,
              right: AppDimens.space16,
              top: AppDimens.space20,
              bottom: 160.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._paragraphs.map((block) {
                  final isEven = block.index.isEven;
                  final isShaded = settings.enableLineShading && !isEven;

                  return Container(
                    key: _paragraphKeys[block.index],
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: EdgeInsets.symmetric(
                      horizontal: settings.enableLineShading ? 14.0 : 4.0,
                      vertical: settings.enableLineShading ? 10.0 : 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: isShaded ? theme.shadingColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: isShaded
                          ? Border.all(
                              color: theme.borderColor.withValues(alpha: 0.7),
                              width: 1.0,
                            )
                          : null,
                    ),
                    child: _buildParagraphText(block, settings, theme),
                  );
                }),
              ],
            ),
          ),

          // PENGGARIS BACA INTERAKTIF YANG DAPAT DIGESER (Interactive Reading Ruler)
          if (isRulerVisible)
            Positioned(
              top: _rulerOffsetY,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _rulerOffsetY = (_rulerOffsetY + details.delta.dy)
                        .clamp(60.0, MediaQuery.of(context).size.height - 220.0);
                  });
                },
                child: Container(
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: AppColors.actionCameraIconBg.withValues(alpha: 0.38),
                    border: const Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.actionCameraBorder,
                        width: 2.0,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.actionCameraBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.drag_indicator_rounded,
                            size: 14,
                            color: AppColors.actionCameraIcon,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Penggaris Baca',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.actionCameraIcon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // FLOATING CONTROL BAR AUDIO DI BAGIAN BAWAH
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: theme.borderColor,
              width: AppDimens.borderWidthStandard,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider Kecepatan Membaca (0.5x - 1.5x) & Ruler Toggle
              Row(
                children: [
                  // Toggle Ruler Icon
                  IconButton(
                    icon: Icon(
                      _isRulerEnabled
                          ? Icons.view_headline_rounded
                          : Icons.view_headline_outlined,
                      color: _isRulerEnabled
                          ? AppColors.primary
                          : theme.textColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    tooltip: 'Toggle Penggaris Baca',
                    onPressed: () {
                      setState(() {
                        _isRulerEnabled = !_isRulerEnabled;
                      });
                    },
                  ),
                  Text(
                    '${settings.speechRate.toStringAsFixed(1)}x',
                    style: AppTextStyles.badge.copyWith(
                      color: theme.textColor,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: theme.textColor.withValues(alpha: 0.15),
                        thumbColor: AppColors.primary,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: settings.speechRate,
                        min: 0.5,
                        max: 1.5,
                        divisions: 10,
                        onChanged: (val) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateSpeechRate(val);
                          _ttsService.setSpeechRate(val);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_rounded, size: 24),
                    color: AppColors.error,
                    tooltip: 'Hentikan Audio',
                    onPressed: _ttsState != TtsPlaybackState.stopped ? _stopTts : null,
                  ),
                ],
              ),

              // Baris Kontrol Audio: Lompat -10s, Play/Pause, Lompat +10s
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lompat Mundur -10s / 60 Karakter
                  IconButton(
                    onPressed: () => _ttsService.jumpOffset(-60),
                    icon: const Icon(Icons.replay_10_rounded, size: 28),
                    color: theme.textColor,
                    tooltip: 'Mundur 10 Detik / Kalimat Sebelumnya',
                  ),
                  const SizedBox(width: AppDimens.space16),

                  // Tombol Play / Pause Utama
                  ElevatedButton.icon(
                    onPressed: _ttsState != TtsPlaybackState.playing
                        ? _playTts
                        : _pauseTts,
                    icon: Icon(
                      _ttsState == TtsPlaybackState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 26,
                    ),
                    label: Text(
                      _ttsState == TtsPlaybackState.playing
                          ? 'Jeda'
                          : (_ttsState == TtsPlaybackState.paused
                              ? 'Lanjutkan'
                              : 'Bacakan'),
                      style: AppTextStyles.button.copyWith(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(130.0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space16),

                  // Lompat Maju +10s / 60 Karakter
                  IconButton(
                    onPressed: () => _ttsService.jumpOffset(60),
                    icon: const Icon(Icons.forward_10_rounded, size: 28),
                    color: theme.textColor,
                    tooltip: 'Maju 10 Detik / Kalimat Berikutnya',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun teks paragraf dengan opsi pewarnaan suku kata fonik
  /// dan penyorotan kata aktif real-time (Read-Along TTS)
  Widget _buildParagraphText(
    _ParagraphBlock block,
    ReaderSettings settings,
    ReaderColorTheme theme,
  ) {
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
      runSpacing: 4.0,
      children: words.map((rawWord) {
        final cleanWord = rawWord.replaceAll(RegExp(r'[^\w]'), '');
        final wordStart = block.text.indexOf(
                rawWord, runningCharOffset - block.globalCharStart) +
            block.globalCharStart;
        final wordEnd = wordStart + rawWord.length;
        runningCharOffset = wordEnd;

        // Periksa apakah kata ini sedang dibacakan secara real-time
        final isHighlighted = _currentHighlight.isActive &&
            ((_currentHighlight.charStart >= wordStart &&
                    _currentHighlight.charStart < wordEnd) ||
                (_currentHighlight.word.toLowerCase() ==
                        cleanWord.toLowerCase() &&
                    cleanWord.isNotEmpty &&
                    _currentHighlight.charStart >= block.globalCharStart &&
                    _currentHighlight.charStart < block.globalCharEnd));

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
                    color: AppColors.highlightWord, // Kuning pastel lembut #FFF3A8
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.highlightWordBorder,
                      width: 1.2,
                    ),
                  )
                : null,
            child: _buildWordContent(
              rawWord: rawWord,
              cleanWord: cleanWord,
              baseStyle: baseStyle,
              isHighlighted: isHighlighted,
              settings: settings,
              theme: theme,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Membangun kata dengan pewarnaan suku kata fonik alternatif (contoh: me-to-do-lo-gi)
  Widget _buildWordContent({
    required String rawWord,
    required String cleanWord,
    required TextStyle baseStyle,
    required bool isHighlighted,
    required ReaderSettings settings,
    required ReaderColorTheme theme,
  }) {
    if (isHighlighted) {
      return Text(
        rawWord,
        style: baseStyle.copyWith(
          color: AppColors.highlightWordText,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    // Pewarnaan suku kata berselang warna jika opsi fonik diaktifkan
    if (settings.phonicSyllableColoring && cleanWord.length > 2) {
      final syllables = SyllableService.syllabify(cleanWord);
      if (syllables.length > 1) {
        return RichText(
          text: TextSpan(
            children: List.generate(syllables.length, (idx) {
              final color = idx.isEven
                  ? (theme.isDark
                      ? const Color(0xFF93C5FD)
                      : AppColors.phonicPrimary)
                  : (theme.isDark
                      ? const Color(0xFFC084FC)
                      : AppColors.phonicSecondary);
              return TextSpan(
                text: syllables[idx],
                style: baseStyle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ),
        );
      }
    }

    return Text(
      rawWord,
      style: baseStyle.copyWith(color: theme.textColor),
    );
  }
}
