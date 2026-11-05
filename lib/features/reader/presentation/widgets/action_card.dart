import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/accessible_card.dart';

/// Kartu aksi utama berukuran besar, berjarak renggang, dan mudah disentuh
/// oleh pengguna disleksia dewasa.
class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: AppDimens.borderWidthThick,
      borderRadius: AppDimens.radiusXL,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space20,
        vertical: AppDimens.space16,
      ),
      semanticLabel: '$title. $subtitle. Tombol aksi.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimens.actionCardMinHeight,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Kontainer Ikon Berwarna Kontras Tinggi
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: AppDimens.actionCardIconSize,
              ),
            ),
            const SizedBox(width: AppDimens.space16),

            // Teks Judul & Deskripsi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge Kategori Kecil
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space8,
                      vertical: AppDimens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    ),
                    child: Text(
                      badgeText.toUpperCase(),
                      style: AppTextStyles.badge.copyWith(
                        color: iconColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),

                  // Judul Aksi Besar
                  Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),

                  // Deskripsi Ramah
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13.0,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.space8),

            // Tombol Panah Bantuan Navigasi
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

