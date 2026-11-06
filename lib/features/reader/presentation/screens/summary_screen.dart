import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/services/text_rank_summarizer.dart';
import '../../domain/services/tts_service.dart';
import '../controllers/home_controller.dart';

/// Layar Tampilan Lengkap Ringkasan Dokumen (TextRank Summary Screen):
/// Menyajikan ekstraksi poin-poin penting dokumen, lencana persentase peringkasan,
/// mode audio player Read-Along khusus ringkasan, dan modal berbagi ke WhatsApp/grup belajar.
class SummaryScreen extends ConsumerStatefulWidget {
  final String fullText;
  final String documentTitle;

  const SummaryScreen({
    super.key,
    required this.fullText,
    this.documentTitle = 'Ringkasan Dokumen',
  });

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late final TextRankSummary _summary;
  late final TtsService _ttsService;
  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  StreamSubscription<TtsPlaybackState>? _stateSubscription;
  int _activeSentenceIndex = -1;

  @override
  void initState() {
    super.initState();
    _summary = TextRankSummarizer.summarize(widget.fullText);
    _ttsService = ref.read(ttsServiceProvider);

    _stateSubscription = _ttsService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playbackState = state;
          if (state == TtsPlaybackState.stopped) {
            _activeSentenceIndex = -1;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _ttsService.stop();
    super.dispose();
  }

  void _togglePlaySummary() {
    if (_playbackState == TtsPlaybackState.playing) {
      _ttsService.pause();
    } else if (_playbackState == TtsPlaybackState.paused) {
      _ttsService.speak(_summary.combinedSummary);
    } else {
      _activeSentenceIndex = 0;
      _ttsService.speak(_summary.combinedSummary);
    }
  }

  void _showShareOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                'Kirim Catatan Ringkasan',
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                'Pilih tujuan pengiriman poin-poin inti bacaan ini:',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppDimens.space16),

              // Opsi 1: WhatsApp
              _buildShareOptionItem(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'Kirim ke WhatsApp',
                subtitle: 'Bagikan langsung ke kontak atau status belajar',
                onTap: () {
                  Navigator.pop(ctx);
                  _copyAndNotify('Ringkasan disiapkan untuk WhatsApp!');
                },
              ),

              // Opsi 2: Grup Belajar / Forum
              _buildShareOptionItem(
                icon: Icons.group_rounded,
                iconColor: AppColors.primary,
                title: 'Grup Belajar & Komunitas',
                subtitle: 'Kirim ke forum diskusi atau teman kelompok',
                onTap: () {
                  Navigator.pop(ctx);
                  _copyAndNotify('Teks disalin untuk grup diskusi!');
                },
              ),

              // Opsi 3: Salin Markdown
              _buildShareOptionItem(
                icon: Icons.copy_rounded,
                iconColor: AppColors.actionPasteIcon,
                title: 'Salin Teks (Format Poin)',
                subtitle: 'Salin rapi dengan nomor urut ke clipboard',
                onTap: () {
                  Navigator.pop(ctx);
                  _copyAndNotify('Ringkasan poin tersalin ke clipboard!');
                },
              ),
              const SizedBox(height: AppDimens.space12),
            ],
          ),
        ),
      ),
    );
  }

  void _copyAndNotify(String message) {
    final buffer = StringBuffer();
    buffer.writeln('📌 *${widget.documentTitle}* (Ringkasan LexiRead)\n');
    for (int i = 0; i < _summary.sentences.length; i++) {
      buffer.writeln('${i + 1}. ${_summary.sentences[i].text}\n');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildShareOptionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: AppTextStyles.titleSmall),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reductionPct = _summary.originalSentenceCount > 0
        ? (((_summary.originalSentenceCount - _summary.summarySentenceCount) /
                    _summary.originalSentenceCount) *
                100)
            .round()
            .clamp(15, 85)
        : 65;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ringkasan Dokumen',
          style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Bagikan Catatan',
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            onPressed: _showShareOptionsModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Info & Lencana Persentase Peringkasan
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space20,
                vertical: AppDimens.space8,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.actionUploadBg,
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusS),
                                  border: Border.all(
                                    color: AppColors.actionUploadBorder,
                                  ),
                                ),
                                child: Text(
                                  'Teringkas $reductionPct%',
                                  style: AppTextStyles.badge.copyWith(
                                    color: AppColors.actionUploadIcon,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TextRank Ekstraktif',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_summary.summarySentenceCount} kalimat inti dari total ${_summary.originalSentenceCount} kalimat',
                            style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MODE AUDIO PLAYER INTEGRATED READ-ALONG KHUSUS RINGKASAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: _togglePlaySummary,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _playbackState == TtsPlaybackState.playing
                                ? AppColors.error
                                : AppColors.primary,
                      ),
                      icon: Icon(
                        _playbackState == TtsPlaybackState.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _playbackState == TtsPlaybackState.playing
                                ? 'Sedang Membacakan Ringkasan...'
                                : 'Dengarkan Ringkasan Audio',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Kecepatan ${_ttsService.speechRate.toStringAsFixed(1)}x • Bahasa Indonesia',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_playbackState != TtsPlaybackState.stopped)
                      IconButton(
                        tooltip: 'Hentikan',
                        icon: const Icon(Icons.stop_rounded, color: AppColors.error),
                        onPressed: () => _ttsService.stop(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // DAFTAR KARTU POIN-POIN UTAMA DOKUMEN
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space20,
                  vertical: AppDimens.space6,
                ),
                itemCount: _summary.sentences.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sentence = _summary.sentences[index];
                  final isReadingThis =
                      _playbackState == TtsPlaybackState.playing &&
                          _activeSentenceIndex == index;

                  return Container(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    decoration: BoxDecoration(
                      color: isReadingThis
                          ? AppColors.highlightWord
                          : const Color(0xFFF4EEDD), // Latar krem lembut
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      border: Border.all(
                        color: isReadingThis
                            ? AppColors.highlightWordBorder
                            : const Color(0xFFDFD7C4),
                        width: isReadingThis ? 2.0 : 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isReadingThis
                                ? AppColors.primary
                                : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: AppTextStyles.badge.copyWith(
                              color: isReadingThis
                                  ? Colors.white
                                  : AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        Expanded(
                          child: SelectableText(
                            sentence.text,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontSize: 16,
                              height: 1.7,
                              letterSpacing: 0.5,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // FOOTER ACTION BUTTONS: Bagikan & WhatsApp
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        _copyAndNotify('Ringkasan disalin ke clipboard!'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin Catatan'),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showShareOptionsModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusL),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        'Kirim ke WhatsApp / Grup',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

