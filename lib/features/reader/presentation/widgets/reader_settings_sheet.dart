import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/home_controller.dart';

/// Panel Pengaturan Tampilan Baca (Reader Settings Bottom Sheet)
/// Memungkinkan pembaca disleksia dewasa menyesuaikan font, ukuran, spasi baris,
/// jarak huruf, line-shading, dan palet warna latar belakang secara real-time.
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = settings.colorTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXL),
        ),
        border: Border(
          top: BorderSide(
            color: theme.borderColor,
            width: AppDimens.borderWidthThick,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            const SizedBox(height: AppDimens.space12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Header Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: theme.textColor,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimens.space8),
                      Text(
                        'Pengaturan Baca',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => controller.resetToDefaults(),
                    icon: Icon(Icons.refresh_rounded, size: 18, color: theme.textColor),
                    label: Text(
                      'Default',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Isi Pengaturan (Dapat di-scroll jika layar kecil)
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space20,
                  vertical: AppDimens.space16,
                ),
                children: [
                  // 1. PILIHAN TEMA WARNA (Krem, Kuning, Abu-abu, Dark)
                  _buildSectionHeader(
                    title: 'Warna Latar & Kontras',
                    icon: Icons.palette_outlined,
                    theme: theme,
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Row(
                    children: ReaderColorTheme.values.map((itemTheme) {
                      final isSelected = settings.colorTheme == itemTheme;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.updateColorTheme(itemTheme),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: itemTheme.backgroundColor,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : itemTheme.borderColor,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: itemTheme.textColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: itemTheme.backgroundColor,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  itemTheme.displayName,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.badge.copyWith(
                                    color: itemTheme.textColor,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.space20),

                  // 2. PILIHAN JENIS FONT (Lexend, OpenDyslexic, Arial)
                  _buildSectionHeader(
                    title: 'Jenis Huruf (Font)',
                    icon: Icons.font_download_outlined,
                    theme: theme,
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Column(
                    children: ReaderFontFamily.values.map((font) {
                      final isSelected = settings.fontFamily == font;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.shadingColor
                              : theme.surfaceColor,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : theme.borderColor,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: RadioListTile<ReaderFontFamily>(
                          value: font,
                          groupValue: settings.fontFamily,
                          activeColor: AppColors.primary,
                          title: Text(
                            font.displayName,
                            style: font.getTextStyle(
                              fontSize: 16,
                              height: 1.2,
                              letterSpacing: 0.3,
                              color: theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            font.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) controller.updateFontFamily(val);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // 3. SLIDER UKURAN TEKS (14pt - 26pt)
                  _buildSliderControl(
                    title: 'Ukuran Huruf',
                    valueDisplay: '${settings.fontSize.round()} pt',
                    icon: Icons.format_size_rounded,
                    theme: theme,
                    value: settings.fontSize,
                    min: 14.0,
                    max: 26.0,
                    divisions: 12,
                    onChanged: (val) => controller.updateFontSize(val),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // 4. SLIDER SPASI BARIS (1.5x - 2.5x)
                  _buildSliderControl(
                    title: 'Spasi Baris (Line Height)',
                    valueDisplay: '${settings.lineSpacing.toStringAsFixed(1)}x',
                    icon: Icons.format_line_spacing_rounded,
                    theme: theme,
                    value: settings.lineSpacing,
                    min: 1.5,
                    max: 2.5,
                    divisions: 10,
                    onChanged: (val) => controller.updateLineSpacing(val),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // 5. SLIDER JARAK HURUF (0.0 - 2.0)
                  _buildSliderControl(
                    title: 'Jarak Antar Huruf (Letter Spacing)',
                    valueDisplay: settings.letterSpacing.toStringAsFixed(1),
                    icon: Icons.space_bar_rounded,
                    theme: theme,
                    value: settings.letterSpacing,
                    min: 0.0,
                    max: 2.0,
                    divisions: 10,
                    onChanged: (val) => controller.updateLetterSpacing(val),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // 6. SLIDER KECEPATAN SUARA TTS (0.3x - 1.0x)
                  _buildSliderControl(
                    title: 'Kecepatan Baca Suara',
                    valueDisplay: '${settings.speechRate.toStringAsFixed(2)}x',
                    icon: Icons.speed_rounded,
                    theme: theme,
                    value: settings.speechRate,
                    min: 0.3,
                    max: 1.0,
                    divisions: 14,
                    onChanged: (val) {
                      controller.updateSpeechRate(val);
                      ref.read(ttsServiceProvider).setSpeechRate(val);
                    },
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // 7. FITUR LINE-SHADING (Latar Selang-Seling)
                  Container(
                    decoration: BoxDecoration(
                      color: settings.enableLineShading
                          ? theme.shadingColor
                          : theme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      border: Border.all(
                        color: settings.enableLineShading
                            ? AppColors.primary
                            : theme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Latar Selang-Seling (Line-Shading)',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: theme.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Memberikan warna latar belakang selang-seling lembut per paragraf agar mata tidak melompat atau tersesat antar baris.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.textColor.withValues(alpha: 0.75),
                        ),
                      ),
                      value: settings.enableLineShading,
                      activeColor: AppColors.primary,
                      onChanged: (val) => controller.toggleLineShading(val),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required ReaderColorTheme theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.textColor),
        const SizedBox(width: AppDimens.space8),
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: theme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderControl({
    required String title,
    required String valueDisplay,
    required IconData icon,
    required ReaderColorTheme theme,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.textColor),
                const SizedBox(width: AppDimens.space8),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.shadingColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                border: Border.all(color: theme.borderColor),
              ),
              child: Text(
                valueDisplay,
                style: AppTextStyles.badge.copyWith(
                  color: theme.textColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: theme.borderColor,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

