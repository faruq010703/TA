import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/reading_document.dart';
import '../../domain/services/tts_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/reading_progress_bar.dart';

/// Layar pembaca teks adaptif ramah disleksia dewasa:
/// Menampilkan teks hasil ekstraksi OCR / berkas / manual dengan format yang dapat
/// disesuaikan secara dinamis (Font, Ukuran, Spasi Baris, Jarak Huruf, Line-Shading, dan Tema Warna).
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
  double _rulerOffsetY = 240.0;
  bool _isRulerEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.document;
    _scrollController = ScrollController();
    _ttsService = ref.read(ttsServiceProvider);

    _initTtsListener();
  }

  void _initTtsListener() {
    _ttsSubscription = _ttsService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _ttsState = state;
        });
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
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

  @override
  void dispose() {
    _ttsSubscription?.cancel();
    _ttsService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleTts() async {
    if (_ttsState == TtsPlaybackState.playing) {
      await _ttsService.pause();
    } else {
      await _ttsService.speak(_currentDoc.content);
    }
  }

  void _openSettingsSheet() {
    ReaderSettingsSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = settings.colorTheme;

    // Pisahkan teks menjadi paragraf untuk fitur Line-Shading
    final paragraphs = _currentDoc.content
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

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
          // Toggle Penggaris Baca (Reading Ruler)
          IconButton(
            icon: Icon(
              _isRulerEnabled
                  ? Icons.view_headline_rounded
                  : Icons.view_headline_outlined,
              color: _isRulerEnabled ? AppColors.primary : theme.textColor.withValues(alpha: 0.6),
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
          // KONTEN TEKS HASIL EKSTRAKSI ADAPTIF
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: AppDimens.space16,
              right: AppDimens.space16,
              top: AppDimens.space20,
              bottom: 130.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Render teks paragraf per paragraf dengan fitur Line-Shading
                ...paragraphs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  final isEven = index.isEven;
                  final isShaded = settings.enableLineShading && !isEven;

                  return Container(
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
                    child: SelectableText(
                      text,
                      style: settings.fontFamily.getTextStyle(
                        fontSize: settings.fontSize,
                        height: settings.lineSpacing,
                        letterSpacing: settings.letterSpacing,
                        color: theme.textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
                        .clamp(60.0, MediaQuery.of(context).size.height - 180.0);
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

      // BILAH KONTROL BAWAH (TTS & Panel Tampilan)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
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
              // Tombol Buka Panel Pengaturan
              OutlinedButton.icon(
                onPressed: _openSettingsSheet,
                icon: const Icon(Icons.format_size_rounded, size: 20),
                label: const Text('Format Teks'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textColor,
                  side: BorderSide(color: theme.borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space16,
                  ),
                ),
              ),
              const Spacer(),

              // Tombol Utama Suara (Text-to-Speech)
              ElevatedButton.icon(
                onPressed: _toggleTts,
                icon: Icon(
                  _ttsState == TtsPlaybackState.playing
                      ? Icons.pause_rounded
                      : Icons.volume_up_rounded,
                  size: 24,
                ),
                label: Text(
                  _ttsState == TtsPlaybackState.playing
                      ? 'Jeda Suara'
                      : 'Bacakan',
                  style: AppTextStyles.button,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(130.0, AppDimens.minTouchTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
