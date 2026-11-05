import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/models/reading_document.dart';
import '../../domain/services/tts_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/reading_progress_bar.dart';

/// Layar pembaca teks khusus disleksia dewasa:
/// Menyediakan font Lexend besar yang dapat diatur ukurannya, jarak baris lapang,
/// penggaris bantu baca (reading ruler), dan integrasi audio Text-to-Speech.
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
  TtsPlaybackState _ttsState = TtsPlaybackState.stopped;
  StreamSubscription<TtsPlaybackState>? _ttsSubscription;
  double _rulerOffsetY = 220.0;
  bool _isRulerEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.document;
    _scrollController = ScrollController();

    _initTtsListener();
  }

  void _initTtsListener() {
    final tts = ref.read(ttsServiceProvider);
    _ttsSubscription = tts.stateStream.listen((state) {
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
    ref.read(ttsServiceProvider).stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleTts() async {
    final tts = ref.read(ttsServiceProvider);
    if (_ttsState == TtsPlaybackState.playing) {
      await tts.pause();
    } else {
      await tts.speak(_currentDoc.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          tooltip: 'Kembali ke Beranda',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentDoc.title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
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
              color: _isRulerEnabled ? AppColors.primary : AppColors.textMuted,
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
          const SizedBox(width: AppDimens.space8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
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
          // Konten Teks Dokumen
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(
              left: AppDimens.space20,
              right: AppDimens.space20,
              top: AppDimens.space24,
              bottom: 120.0,
            ),
            child: SelectableText(
              _currentDoc.content,
              style: GoogleFonts.lexend(
                fontSize: settings.fontSize,
                height: settings.lineSpacing,
                letterSpacing: settings.letterSpacing,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Penggaris Baca Lembut yang Dapat Digeser (Interactive Reading Ruler)
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
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: AppColors.actionCameraIconBg.withValues(alpha: 0.35),
                    border: const Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.actionCameraBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Geser Garis',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.actionCameraIcon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Bilah Kontrol TTS Bawah
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: AppDimens.borderWidthStandard,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Pengaturan Ukuran Huruf Cepat
              IconButton(
                icon: const Icon(Icons.text_decrease_rounded),
                tooltip: 'Kecilkan Font',
                onPressed: () {
                  final newSize = (settings.fontSize - 1.5).clamp(14.0, 32.0);
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateFontSize(newSize);
                },
              ),
              IconButton(
                icon: const Icon(Icons.text_increase_rounded),
                tooltip: 'Besarkan Font',
                onPressed: () {
                  final newSize = (settings.fontSize + 1.5).clamp(14.0, 32.0);
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateFontSize(newSize);
                },
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
                  minimumSize: const Size(140.0, AppDimens.minTouchTarget),
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
