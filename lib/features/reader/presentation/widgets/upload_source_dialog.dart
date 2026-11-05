import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/accessible_card.dart';

enum UploadSourceChoice { gallery, file }

/// Modal pilihan sumber dokumen (Galeri Foto vs Berkas Dokumen PDF/Teks)
/// dengan kartu berukuran besar dan mudah ditekan oleh pengguna disleksia dewasa.
class UploadSourceDialog extends StatelessWidget {
  const UploadSourceDialog({super.key});

  static Future<UploadSourceChoice?> show(BuildContext context) {
    return showModalBottomSheet<UploadSourceChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const UploadSourceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space20,
            vertical: AppDimens.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle drag bar
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // Judul Pilihan
              Text(
                'Pilih Sumber Dokumen',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                'Pilih cara membuka dokumen yang paling nyaman untuk Anda:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.space20),

              // Opsi 1: Galeri Foto (Image Picker)
              AccessibleCard(
                onTap: () => Navigator.pop(context, UploadSourceChoice.gallery),
                backgroundColor: AppColors.actionUploadBg,
                borderColor: AppColors.actionUploadBorder,
                borderWidth: AppDimens.borderWidthThick,
                padding: const EdgeInsets.all(AppDimens.space16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.actionUploadIconBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.actionUploadIcon,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galeri Foto',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppDimens.space2),
                          Text(
                            'Pilih foto dokumen atau tangkapan layar dari galeri',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.actionUploadIcon,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // Opsi 2: Berkas PDF / Dokumen (File Picker)
              AccessibleCard(
                onTap: () => Navigator.pop(context, UploadSourceChoice.file),
                backgroundColor: AppColors.actionPasteBg,
                borderColor: AppColors.actionPasteBorder,
                borderWidth: AppDimens.borderWidthThick,
                padding: const EdgeInsets.all(AppDimens.space16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.actionPasteIconBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.actionPasteIcon,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Berkas PDF / Dokumen',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppDimens.space2),
                          Text(
                            'Buka berkas PDF atau dokumen teks dari memori perangkat',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.actionPasteIcon,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // Tombol Batal
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
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

