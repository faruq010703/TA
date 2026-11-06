import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Modal Tipografi Adaptif:
/// Pengaturan ukuran font, pilihan font ramah disleksia (Lexend, OpenDyslexic, Sans-Serif),
/// 4 palet warna latar (Krem, Peach, Pastel Blue, Dark), jarak baris, jarak huruf,
/// jarak kata, line-shading per paragraf, dan pewarnaan suku kata fonik.
class TypographySheet extends ConsumerWidget {
  const TypographySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TypographySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = settings.colorTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXL),
        ),
        border: Border(
          top: BorderSide(color: theme.borderColor, width: 2),
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
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Header Tipografi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.textColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: Icon(
                          Icons.text_format_rounded,
                          color: theme.textColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space10),
                      Text(
                        'Setelan Tipografi & Kontras',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 17,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => controller.resetToDefaults(),
                    child: Text(
                      'Reset Default',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space8),

            // Konten Scrollable
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space20,
                  vertical: AppDimens.space8,
                ),
                children: [
                  // 1. TEMA WARNA LATAR BELAKANG (Krem, Peach, Pastel Blue, Dark)
                  _buildSectionHeader('WARNA LATAR RAMAH MATA (ANTI-IRLEN)', theme),
                  const SizedBox(height: AppDimens.space8),
                  Row(
                    children: [
                      _buildThemeCard(
                        theme: ReaderColorTheme.cream,
                        current: settings.colorTheme,
                        onTap: () =>
                            controller.updateColorTheme(ReaderColorTheme.cream),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeCard(
                        theme: ReaderColorTheme.peach,
                        current: settings.colorTheme,
                        onTap: () =>
                            controller.updateColorTheme(ReaderColorTheme.peach),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeCard(
                        theme: ReaderColorTheme.pastelBlue,
                        current: settings.colorTheme,
                        onTap: () => controller
                            .updateColorTheme(ReaderColorTheme.pastelBlue),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeCard(
                        theme: ReaderColorTheme.lowContrastDark,
                        current: settings.colorTheme,
                        onTap: () => controller
                            .updateColorTheme(ReaderColorTheme.lowContrastDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space18),

                  // 2. PILIHAN JENIS FONT RAMAH DISLEKSIA
                  _buildSectionHeader('KARAKTERISTIK HURUF', theme),
                  const SizedBox(height: AppDimens.space8),
                  Column(
                    children: ReaderFontFamily.values.map((font) {
                      final isSelected = settings.fontFamily == font;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () => controller.updateFontFamily(font),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.textColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                              border: Border.all(
                                color: isSelected
                                    ? theme.textColor
                                    : theme.borderColor,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: theme.textColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        font.displayName,
                                        style: font.getTextStyle(
                                          fontSize: 15,
                                          height: 1.2,
                                          letterSpacing: 0.2,
                                          color: theme.textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        font.description,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color:
                                              theme.textColor.withValues(alpha: 0.7),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // 3. SLIDER UKURAN FONT (14pt - 28pt)
                  _buildSlider(
                    label: 'Ukuran Font',
                    valueText: '${settings.fontSize.toStringAsFixed(0)} pt',
                    value: settings.fontSize,
                    min: 14.0,
                    max: 28.0,
                    divisions: 14,
                    theme: theme,
                    onChanged: (val) => controller.updateFontSize(val),
                  ),

                  // 4. SLIDER SPASI BARIS (LINE HEIGHT: 1.4x - 2.6x)
                  _buildSlider(
                    label: 'Spasi Antar Baris (Line Height)',
                    valueText: '${settings.lineSpacing.toStringAsFixed(1)}x',
                    value: settings.lineSpacing,
                    min: 1.4,
                    max: 2.6,
                    divisions: 12,
                    theme: theme,
                    onChanged: (val) => controller.updateLineSpacing(val),
                  ),

                  // 5. SLIDER JARAK HURUF (LETTER SPACING: 0.0 - 2.5)
                  _buildSlider(
                    label: 'Jarak Antar Huruf (Letter Spacing)',
                    valueText: '${settings.letterSpacing.toStringAsFixed(1)} px',
                    value: settings.letterSpacing,
                    min: 0.0,
                    max: 2.5,
                    divisions: 10,
                    theme: theme,
                    onChanged: (val) => controller.updateLetterSpacing(val),
                  ),

                  // 6. SLIDER JARAK KATA (WORD SPACING: 1.0 - 3.5)
                  _buildSlider(
                    label: 'Jarak Antar Kata (Word Spacing)',
                    valueText: '${settings.wordSpacing.toStringAsFixed(1)} px',
                    value: settings.wordSpacing,
                    min: 1.0,
                    max: 3.5,
                    divisions: 10,
                    theme: theme,
                    onChanged: (val) => controller.updateWordSpacing(val),
                  ),

                  const Divider(height: 24),

                  // 7. TOGGLE PEMENGGALAN SUKU KATA BERWARNA
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Pewarnaan Suku Kata Fonik',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Suku kata ditampilkan berselang warna (me-to-do-lo-gi) agar tidak tertukar',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    value: settings.phonicSyllableColoring,
                    onChanged: (val) =>
                        controller.togglePhonicSyllableColoring(val),
                  ),

                  // 8. TOGGLE LINE SHADING PER PARAGRAF
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Latar Paragraf Selang-Seling (Line-Shading)',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Memberi arsiran lembut agar pandangan mata tidak melompat antar baris',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    value: settings.enableLineShading,
                    onChanged: (val) => controller.toggleLineShading(val),
                  ),

                  // 9. TOGGLE READING RULER
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Penggaris Fokus Baca (Reading Ruler)',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Garis pemandu horizontal yang dapat digeser bebas dengan sentuhan',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    value: settings.showReadingRuler,
                    onChanged: (val) => controller.toggleReadingRuler(val),
                  ),

                  const SizedBox(height: AppDimens.space16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ReaderColorTheme theme) {
    return Text(
      title,
      style: AppTextStyles.badge.copyWith(
        color: theme.textColor.withValues(alpha: 0.6),
        fontSize: 11,
      ),
    );
  }

  Widget _buildThemeCard({
    required ReaderColorTheme theme,
    required ReaderColorTheme current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == theme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.primary : theme.borderColor,
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : theme.textColor,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                theme.displayName.split(' ').first,
                style: AppTextStyles.badge.copyWith(
                  fontSize: 10,
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ReaderColorTheme theme,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.titleSmall.copyWith(
                  fontSize: 13,
                  color: theme.textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.textColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Text(
                  valueText,
                  style: AppTextStyles.badge.copyWith(color: theme.textColor),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.textColor,
              inactiveTrackColor: theme.textColor.withValues(alpha: 0.2),
              thumbColor: theme.textColor,
              trackHeight: 3.5,
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
      ),
    );
  }
}

