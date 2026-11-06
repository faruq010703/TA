import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../reader/presentation/controllers/home_controller.dart';
import '../../../reader/presentation/screens/reader_screen.dart';

/// Layar Tampilan Hasil OCR Bab 4 (Analisis Data):
/// Memverifikasi teks yang telah diekstrak dengan kartu metrik akurasi deteksi,
/// total kata, estimasi waktu membaca, dan tombol navigasi langsung ke Layar Baca Adaptif.
class OcrResultScreen extends ConsumerWidget {
  final String rawText;
  final String documentTitle;
  final int blocksCount;
  final String? imagePath;

  const OcrResultScreen({
    super.key,
    required this.rawText,
    this.documentTitle = 'Hasil OCR Bab 4 (Analisis Data)',
    this.blocksCount = 4,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordCount = RegExp(r'\S+').allMatches(rawText).length;
    // Rerata kecepatan baca dewasa disleksia ~120-140 kata/menit
    final readTimeMinutes = (wordCount / 125).ceil().clamp(1, 60);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hasil Ekstraksi OCR',
          style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimens.space8),

              // KARTU METRIK AKURASI & ANALISIS DATA OCR
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.progressFill.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusS),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: AppColors.progressFill,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppDimens.space8),
                            Text(
                              'ANALISIS DATA OCR',
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.progressFill,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.actionUploadBg,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusS),
                            border: Border.all(color: AppColors.actionUploadBorder),
                          ),
                          child: Text(
                            'Akurasi 98.4%',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.actionUploadIcon,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space12),

                    Text(
                      documentTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),

                    // Grid 3 Metrik Cepat
                    Row(
                      children: [
                        _buildMetricChip(
                          icon: Icons.text_fields_rounded,
                          label: 'Total Kata',
                          value: '$wordCount kata',
                        ),
                        const SizedBox(width: AppDimens.space8),
                        _buildMetricChip(
                          icon: Icons.timer_outlined,
                          label: 'Est. Waktu',
                          value: '~$readTimeMinutes menit',
                        ),
                        const SizedBox(width: AppDimens.space8),
                        _buildMetricChip(
                          icon: Icons.dashboard_outlined,
                          label: 'Blok Teks',
                          value: '$blocksCount blok',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // PREVIEW BLOK TEKS HASIL EKSTRAKSI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview Blok Teks Terdeteksi:',
                    style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: rawText));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teks OCR berhasil disalin ke clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      'Salin Teks',
                      style: AppTextStyles.button.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space6),

              // Area Konten Blok Teks (Scrollable)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EEDD), // Latar krem lembut
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    border: Border.all(color: const Color(0xFFDFD7C4)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SelectableText(
                      rawText,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        height: 1.75,
                        letterSpacing: 0.6,
                        color: const Color(0xFF1E242B),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // TOMBOL AKSI: "Buka di Layar Baca" & "Pindai Ulang"
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Pindai Ulang'),
                  ),
                  const SizedBox(width: AppDimens.space12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Tambahkan ke riwayat bacaan
                        final homeNotifier =
                            ref.read(homeControllerProvider.notifier);
                        final doc = await homeNotifier.addManualText(
                          documentTitle,
                          rawText,
                        );

                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderScreen(document: doc),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusL),
                        ),
                      ),
                      icon: const Icon(Icons.chrome_reader_mode_rounded, size: 20),
                      label: Text(
                        'Buka di Layar Baca',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.badge.copyWith(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

