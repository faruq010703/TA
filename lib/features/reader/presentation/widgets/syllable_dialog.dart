import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/services/syllable_service.dart';
import '../../domain/services/tts_service.dart';

/// Dialog / Tooltip interaktif pemenggal suku kata Bahasa Indonesia.
/// Membantu pembaca disleksia memecah kata kompleks menjadi unit suku kata fonotaktik.
class SyllableDialog extends StatelessWidget {
  final String word;
  final TtsService? ttsService;

  const SyllableDialog({
    super.key,
    required this.word,
    this.ttsService,
  });

  static Future<void> show(
    BuildContext context, {
    required String word,
    TtsService? ttsService,
  }) {
    // Bersihkan tanda baca di sekeliling kata
    final cleanWord = word.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
    if (cleanWord.isEmpty) return Future.value();

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => SyllableDialog(
        word: cleanWord,
        ttsService: ttsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syllables = SyllableService.syllabify(word);
    final hyphenated = SyllableService.formatWithHyphen(word);

    // Palet warna lembut selang-seling untuk suku kata
    final syllableColors = [
      (bg: AppColors.actionCameraIconBg, border: AppColors.actionCameraBorder, text: AppColors.actionCameraIcon),
      (bg: AppColors.actionUploadIconBg, border: AppColors.actionUploadBorder, text: AppColors.actionUploadIcon),
      (bg: AppColors.actionPasteIconBg, border: AppColors.actionPasteBorder, text: AppColors.actionPasteIcon),
      (bg: const Color(0xFFFDE8E8), border: const Color(0xFFF8B4B4), text: const Color(0xFF9B1C1C)),
      (bg: const Color(0xFFEDEBFE), border: const Color(0xFFCABFFD), text: const Color(0xFF5521B5)),
    ];

    return Dialog(
      backgroundColor: AppColors.background,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        side: const BorderSide(
          color: AppColors.borderStrong,
          width: AppDimens.borderWidthThick,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Judul dialog & badge suku kata
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.actionPasteIconBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  ),
                  child: const Icon(
                    Icons.spellcheck_rounded,
                    color: AppColors.actionPasteIcon,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemisahan Suku Kata',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${syllables.length} suku kata fonotaktik',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // Teks Asli Kata
            Center(
              child: Text(
                word,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Pill Suku Kata Berwarna Selang-Seling
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: syllables.asMap().entries.map((entry) {
                final idx = entry.key;
                final syl = entry.value;
                final color = syllableColors[idx % syllableColors.length];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.bg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    border: Border.all(
                      color: color.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    syl,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.space16),

            // Teks pemenggalan bertanda hubung: "mem-per-tah-an-kan"
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                hyphenated,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // Tombol Lafalkan Suara Kata Tunggal
            if (ttsService != null)
              ElevatedButton.icon(
                onPressed: () {
                  ttsService!.speak(word);
                },
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                label: const Text('Lafalkan Kata Ini'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
