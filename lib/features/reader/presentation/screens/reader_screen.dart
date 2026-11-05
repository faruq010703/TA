import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/reading_document.dart';
import '../../domain/services/tts_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/reading_progress_bar.dart';
import '../widgets/summary_sheet.dart';
import '../widgets/syllable_dialog.dart';

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
/// Menampilkan teks hasil ekstraksi OCR / berkas / manual dengan format yang dapat
/// disesuaikan secara dinamis, fitur Read-Along TTS (penyorotan kata real-time & auto-scroll),
/// analisis pemenggal suku kata interaktif, dan peringkas teks mandiri TextRank.
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
      } else {
        currentOffset += line.length + 1;
      }
    }

    _paragraphs = blocks;
  }

  void _initTtsListeners() {
    final settings = ref.read(settingsControllerProvider);
    _ttsService.setSpeechRate(settings.speechRate);

    _ttsSubscription = _ttsService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _ttsState = state;
          if (state == TtsPlaybackState.stopped) {
            _currentHighlight = TtsWordHighlight.empty;
          }
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
        }
      }
    });

    _scrollController.addListener(_onManualScroll);
  }

  void _onManualScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll > 0) {
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

  void _openSettingsSheet() {
    ReaderSettingsSheet.show(context);
  }

  void _openSummarySheet() {
    SummarySheet.show(
      context,
      fullText: _currentDoc.content,
      ttsService: _ttsService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = settings.colorTheme;

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
        title: Text(
          _currentDoc.title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Tombol Ringkas Dokumen (TextRank Ekstraktif Lokal)
          TextButton.icon(
            onPressed: _openSummarySheet,
            icon: const Icon(
              Icons.auto_awesome_rounded,
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
          const SizedBox(width: 6.0),

          // Toggle Penggaris Baca (Reading Ruler)
          IconButton(
            icon: Icon(
              _isRulerEnabled
                  ? Icons.view_headline_rounded
                  : Icons.view_headline_outlined,
              color: _isRulerEnabled
                  ? AppColors.primary
                  : theme.textColor.withValues(alpha: 0.6),
            ),
            tooltip: _isRulerEnabled
                ? 'Sembunyikan Penggaris Baca'
                : 'Tampilkan Penggaris Baca',
            onPressed: () {
              setState(() {
                _isRulerEnabled = !_isRulerEnabled;
              });
            },
          ),

          // Tombol Panel Pengaturan Tampilan Baca
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.shadingColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            tooltip: 'Pengaturan Tampilan Teks & Warna',
            onPressed: _openSettingsSheet,
          ),
          const SizedBox(width: AppDimens.space8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18.0),
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
          // KONTEN TEKS HASIL EKSTRAKSI ADAPTIF DENGAN INTERAKSI SUKU KATA & READ-ALONG
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppDimens.space16,
              right: AppDimens.space16,
              top: AppDimens.space20,
              bottom: 140.0,
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
          if (_isRulerEnabled)
            Positioned(
              top: _rulerOffsetY,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _rulerOffsetY = (_rulerOffsetY + details.delta.dy)
                        .clamp(60.0, MediaQuery.of(context).size.height - 200.0);
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

      // BILAH NAVIGASI AUDIO BAWAH (Play, Pause, Stop, Kecepatan, Format Teks)
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
          child: Row(
            children: [
              // 1. Tombol Buka Panel Format Teks
              IconButton(
                onPressed: _openSettingsSheet,
                icon: const Icon(Icons.format_size_rounded, size: 22),
                tooltip: 'Format Teks & Font',
                style: IconButton.styleFrom(
                  foregroundColor: theme.textColor,
                  backgroundColor: theme.shadingColor,
                  minimumSize: const Size(42, 42),
                ),
              ),
              const SizedBox(width: AppDimens.space8),

              // 2. Chip Pengaturan Kecepatan Suara Cepat (0.3x - 1.0x)
              GestureDetector(
                onTap: () {
                  double nextRate = 0.5;
                  if (settings.speechRate < 0.45) {
                    nextRate = 0.5;
                  } else if (settings.speechRate < 0.65) {
                    nextRate = 0.7;
                  } else if (settings.speechRate < 0.9) {
                    nextRate = 1.0;
                  } else {
                    nextRate = 0.35;
                  }
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateSpeechRate(nextRate);
                  _ttsService.setSpeechRate(nextRate);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.shadingColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${settings.speechRate.toStringAsFixed(2)}x',
                        style: AppTextStyles.badge.copyWith(
                          color: theme.textColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // 3. Tombol STOP Navigasi Audio
              IconButton(
                onPressed: _ttsState != TtsPlaybackState.stopped ? _stopTts : null,
                icon: const Icon(Icons.stop_rounded, size: 26),
                tooltip: 'Berhenti & Hapus Sorotan',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.error,
                  disabledForegroundColor:
                      theme.textColor.withValues(alpha: 0.3),
                  backgroundColor: theme.shadingColor,
                  minimumSize: const Size(44, 44),
                ),
              ),
              const SizedBox(width: AppDimens.space8),

              // 4. Tombol PAUSE Navigasi Audio
              IconButton(
                onPressed: _ttsState == TtsPlaybackState.playing ? _pauseTts : null,
                icon: const Icon(Icons.pause_rounded, size: 26),
                tooltip: 'Jeda Suara',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  disabledForegroundColor:
                      theme.textColor.withValues(alpha: 0.3),
                  backgroundColor: theme.shadingColor,
                  minimumSize: const Size(44, 44),
                ),
              ),
              const SizedBox(width: AppDimens.space8),

              // 5. Tombol PLAY Navigasi Audio
              ElevatedButton.icon(
                onPressed:
                    _ttsState != TtsPlaybackState.playing ? _playTts : _pauseTts,
                icon: Icon(
                  _ttsState == TtsPlaybackState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 24,
                ),
                label: Text(
                  _ttsState == TtsPlaybackState.playing
                      ? 'Jeda'
                      : (_ttsState == TtsPlaybackState.paused
                          ? 'Lanjut'
                          : 'Bacakan'),
                  style: AppTextStyles.button,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(116.0, AppDimens.minTouchTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun teks paragraf dengan kata-kata interaktif (ketuk untuk pemenggalan suku kata)
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
      color: theme.textColor,
      fontWeight: FontWeight.w400,
    );

    // Tokenisasi kata-kata dalam paragraf
    final words = block.text.split(RegExp(r'\s+'));

    int runningCharOffset = block.globalCharStart;

    return Wrap(
      spacing: 5.0,
      runSpacing: 4.0,
      children: words.map((rawWord) {
        final cleanWord = rawWord.replaceAll(RegExp(r'[^\w]'), '');
        final wordStart = block.text.indexOf(rawWord, runningCharOffset - block.globalCharStart) + block.globalCharStart;
        final wordEnd = wordStart + rawWord.length;
        runningCharOffset = wordEnd;

        // Periksa apakah kata ini sedang dibacakan secara real-time
        final isHighlighted = _currentHighlight.isActive &&
            ((_currentHighlight.charStart >= wordStart &&
                    _currentHighlight.charStart < wordEnd) ||
                (_currentHighlight.word.toLowerCase() == cleanWord.toLowerCase() &&
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
              horizontal: isHighlighted ? 4.0 : 1.0,
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
            child: Text(
              rawWord,
              style: baseStyle.copyWith(
                color: isHighlighted
                    ? AppColors.highlightWordText
                    : theme.textColor,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
