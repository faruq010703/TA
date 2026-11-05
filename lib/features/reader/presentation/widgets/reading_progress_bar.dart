import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';

/// Indikator progres baca visual yang mudah dipindai oleh pengguna disleksia.
class ReadingProgressBar extends StatelessWidget {
  final double ratio;
  final int currentWords;
  final int totalWords;
  final bool showLabel;

  const ReadingProgressBar({
    super.key,
    required this.ratio,
    this.currentWords = 0,
    this.totalWords = 0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final percent = (clampedRatio * 100).round();
    final isCompleted = percent >= 98;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? 'Selesai Dibaca' : '$percent% selesai',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppColors.progressComplete
                      : AppColors.textPrimary,
                ),
              ),
              if (totalWords > 0)
                Text(
                  '$currentWords / $totalWords kata',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 6.0),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          child: Container(
            height: AppDimens.progressBarHeight,
            width: double.infinity,
            color: AppColors.progressTrack,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.progressComplete
                      : AppColors.progressFill,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
