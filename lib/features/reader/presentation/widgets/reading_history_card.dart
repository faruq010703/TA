import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../../domain/models/reading_document.dart';
import 'reading_progress_bar.dart';

/// Kartu dokumen dalam daftar "Riwayat Bacaan Terakhir"
class ReadingHistoryCard extends StatelessWidget {
  final ReadingDocument document;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ReadingHistoryCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onDelete,
  });

  IconData _getSourceIcon(DocumentSourceType type) {
    switch (type) {
      case DocumentSourceType.camera:
        return Icons.camera_alt_outlined;
      case DocumentSourceType.file:
        return Icons.insert_drive_file_outlined;
      case DocumentSourceType.manual:
        return Icons.edit_note_rounded;
    }
  }

  Color _getSourceColor(DocumentSourceType type) {
    switch (type) {
      case DocumentSourceType.camera:
        return AppColors.actionCameraIcon;
      case DocumentSourceType.file:
        return AppColors.actionUploadIcon;
      case DocumentSourceType.manual:
        return AppColors.actionPasteIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceColor = _getSourceColor(document.sourceType);

    return AccessibleCard(
      onTap: onTap,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      borderRadius: AppDimens.radiusL,
      padding: const EdgeInsets.all(AppDimens.space16),
      semanticLabel:
          'Dokumen ${document.title}. ${document.progressPercent}% selesai. Ketuk untuk membaca.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris: Tipe Sumber + Tanggal + Aksi Opsi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: AppDimens.space4,
                ),
                decoration: BoxDecoration(
                  color: sourceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSourceIcon(document.sourceType),
                      size: 14,
                      color: sourceColor,
                    ),
                    const SizedBox(width: AppDimens.space4),
                    Text(
                      document.sourceType.displayName,
                      style: AppTextStyles.badge.copyWith(
                        color: sourceColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                '•  ${AccessibilityUtils.formatFriendlyDate(document.lastReadAt)}',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textMuted,
                  tooltip: 'Hapus dari riwayat',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),

          // Judul Dokumen
          Text(
            document.title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6.0),

          // Cuplikan Teks
          Text(
            document.snippet,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.space16),

          // Indikator Progres Baca
          ReadingProgressBar(
            ratio: document.progressRatio,
            currentWords: document.currentWordIndex,
            totalWords: document.totalWords,
            showLabel: true,
          ),
        ],
      ),
    );
  }
}
