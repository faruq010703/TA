import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../controllers/settings_controller.dart';

/// Layar pengaturan preferensi membaca disleksia dewasa
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Preferensi Membaca',
          style: AppTextStyles.headlineSmall,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.space20),
        children: [
          // Ukuran Font
          Text('Ukuran Huruf (${settings.fontSize.round()} pt)',
              style: AppTextStyles.titleMedium),
          Slider(
            value: settings.fontSize,
            min: 14.0,
            max: 32.0,
            divisions: 9,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.updateFontSize(val),
          ),
          const SizedBox(height: AppDimens.space16),

          // Jarak Antar Baris (Line Spacing)
          Text(
            'Kerapatan Baris (${settings.lineSpacing.toStringAsFixed(1)}x)',
            style: AppTextStyles.titleMedium,
          ),
          Slider(
            value: settings.lineSpacing,
            min: 1.3,
            max: 2.2,
            divisions: 9,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.updateLineSpacing(val),
          ),
          const SizedBox(height: AppDimens.space16),

          // Kecepatan Suara TTS
          Text(
            'Kecepatan Membaca Suara (${(settings.speechRate * 2).toStringAsFixed(1)}x)',
            style: AppTextStyles.titleMedium,
          ),
          Slider(
            value: settings.speechRate,
            min: 0.3,
            max: 0.7,
            divisions: 8,
            activeColor: AppColors.primary,
            onChanged: (val) => controller.updateSpeechRate(val),
          ),
          const SizedBox(height: AppDimens.space16),

          // Penggaris Baca
          SwitchListTile(
            title: Text(
              'Gunakan Penggaris Bantu Baca',
              style: AppTextStyles.titleMedium,
            ),
            subtitle: Text(
              'Menyorot baris aktif agar mata tetap fokus saat membaca',
              style: AppTextStyles.bodySmall,
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

