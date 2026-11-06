import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/services/tts_service.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/home_controller.dart';

/// Modal Audio Lanjutan (Advanced Audio Sheet):
/// Mengatur parameter Text-to-Speech secara detail:
/// - Slider Pitch Suara (0.5 - 1.5)
/// - Slider Speech Rate (0.5x - 1.5x)
/// - Slider Durasi Jeda Antar-Kata / Inter-word Pause (100ms - 800ms)
/// - Fitur preview sampel suara
class AdvancedAudioSheet extends ConsumerWidget {
  final TtsService? ttsService;

  const AdvancedAudioSheet({super.key, this.ttsService});

  static Future<void> show(BuildContext context, {TtsService? ttsService}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedAudioSheet(ttsService: ttsService),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = settings.colorTheme;
    final TtsService activeTts = ttsService ?? ref.read(ttsServiceProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              const SizedBox(height: AppDimens.space12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.actionPasteBg,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: const Icon(
                          Icons.equalizer_rounded,
                          color: AppColors.actionPasteIcon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space10),
                      Text(
                        'Setelan Audio Lanjutan',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 17,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space8),

              // Status Engine TTS & Bahasa Default
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.textColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Engine: FlutterTTS Bahasa Indonesia (id-ID)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // 1. SLIDER KECEPATAN BICARA (SPEECH RATE: 0.5x - 1.5x)
              _buildSliderRow(
                label: 'Kecepatan Bicara (Speech Rate)',
                valueText: '${settings.speechRate.toStringAsFixed(1)}x',
                value: settings.speechRate,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                theme: theme,
                onChanged: (val) {
                  controller.updateSpeechRate(val);
                  activeTts.setSpeechRate(val);
                },
              ),

              // 2. SLIDER PITCH SUARA (0.5 - 1.5)
              _buildSliderRow(
                label: 'Nada Suara (Pitch)',
                valueText: settings.pitch.toStringAsFixed(1),
                value: settings.pitch,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                theme: theme,
                onChanged: (val) {
                  controller.updatePitch(val);
                  activeTts.setPitch(val);
                },
              ),

              // 3. SLIDER DURASI JEDA ANTAR-KATA (INTER-WORD PAUSE: 100ms - 800ms)
              _buildSliderRow(
                label: 'Jeda Antar-Kata (Inter-word Pause)',
                valueText: '${settings.interWordPauseMs} ms',
                value: settings.interWordPauseMs.toDouble(),
                min: 100.0,
                max: 800.0,
                divisions: 14,
                theme: theme,
                onChanged: (val) {
                  controller.updateInterWordPause(val.round());
                },
              ),

              const SizedBox(height: AppDimens.space12),

              // Tombol Uji Suara Preview
              ElevatedButton.icon(
                onPressed: () {
                  activeTts.speak(
                    'Halo. Ini adalah uji coba nada dan kecepatan suara membaca Anda.',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  ),
                ),
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                label: Text(
                  'Uji Coba Suara Sekarang',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
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

