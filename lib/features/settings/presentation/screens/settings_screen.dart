import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/reader_settings.dart';
import '../controllers/settings_controller.dart';

/// Layar pengaturan preferensi membaca disleksia dewasa
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = settings.colorTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        title: Text(
          'Preferensi Membaca',
          style: AppTextStyles.headlineSmall.copyWith(
            color: theme.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.resetToDefaults(),
            child: Text(
              'Reset',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space20),
        children: [
          // 1. TEMA WARNA
          Text(
            'Tema Warna Latar & Kontras',
            style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
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
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : itemTheme.borderColor,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: itemTheme.textColor,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 14, color: itemTheme.backgroundColor)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          itemTheme.displayName,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.badge.copyWith(
                            color: itemTheme.textColor,
                            fontSize: 10,
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

          // 2. PILIHAN FONT
          Text(
            'Jenis Huruf (Font)',
            style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
          ),
          const SizedBox(height: AppDimens.space8),
          ...ReaderFontFamily.values.map((font) {
            final isSelected = settings.fontFamily == font;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.shadingColor : theme.surfaceColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: Border.all(
                  color: isSelected ? AppColors.primary : theme.borderColor,
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
                    fontSize: 15,
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
          }),
          const SizedBox(height: AppDimens.space16),

          // 3. UKURAN TEKS (14pt - 26pt)
          Text(
            'Ukuran Huruf (${settings.fontSize.round()} pt)',
            style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
          ),
          Slider(
            value: settings.fontSize,
            min: 14.0,
            max: 26.0,
            divisions: 12,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.updateFontSize(val),
          ),
          const SizedBox(height: AppDimens.space16),

          // 4. SPASI BARIS (1.5x - 2.5x)
          Text(
            'Kerapatan Baris (${settings.lineSpacing.toStringAsFixed(1)}x)',
            style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
          ),
          Slider(
            value: settings.lineSpacing,
            min: 1.5,
            max: 2.5,
            divisions: 10,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.updateLineSpacing(val),
          ),
          const SizedBox(height: AppDimens.space16),

          // 5. JARAK HURUF (0.0 - 2.0)
          Text(
            'Jarak Antar Huruf (${settings.letterSpacing.toStringAsFixed(1)})',
            style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
          ),
          Slider(
            value: settings.letterSpacing,
            min: 0.0,
            max: 2.0,
            divisions: 10,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.updateLetterSpacing(val),
          ),
          const SizedBox(height: AppDimens.space16),

          // 6. FITUR LINE-SHADING
          SwitchListTile(
            title: Text(
              'Latar Selang-Seling (Line-Shading)',
              style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
            ),
            subtitle: Text(
              'Memberikan latar belakang tipis selang-seling tiap paragraf agar fokus mata tidak melompat baris',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.textColor.withValues(alpha: 0.75),
              ),
            ),
            value: settings.enableLineShading,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.toggleLineShading(val),
          ),
          const SizedBox(height: AppDimens.space12),

          // 7. PENGGARIS BACA
          SwitchListTile(
            title: Text(
              'Gunakan Penggaris Bantu Baca',
              style: AppTextStyles.titleMedium.copyWith(color: theme.textColor),
            ),
            subtitle: Text(
              'Menyorot baris aktif dengan garis bantu yang dapat digeser',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.textColor.withValues(alpha: 0.75),
              ),
            ),
            value: settings.showReadingRuler,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.toggleReadingRuler(val),
          ),
        ],
      ),
    );
  }
}
