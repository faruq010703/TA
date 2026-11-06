import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../reader/presentation/screens/home_screen.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Layar Onboarding & Kalibrasi Aksesibilitas Disleksia Dewasa (LexiRead)
///
/// Fitur Utama:
/// 1. Tombol 'Lewati' responsif langsung mengarahkan pengguna ke HomeScreen.
/// 2. Body Scaffold visual lengkap:
///    - Header judul & subtitle panduan "Kalibrasi Kenyamanan Membaca"
///    - Kartu Pratinjau Teks (Preview Card) dengan latar krem lembut dinamis (#F4EEDD) & border
///    - Slider pengatur ukuran font (14 - 28 sp) dengan pembaruan instan
///    - Pemilih 4 palet warna latar (Krem, Peach, Biru Pastel, Abu Lembut)
///    - Pemilih jenis huruf (Lexend, OpenDyslexic, Sans-Serif)
///    - Tombol utama "Mulai Membaca" di bagian bawah menuju HomeScreen
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Nilai pengaturan kalibrasi teks
  double _fontSize = 18.0;
  final double _lineHeight = 1.8;
  final double _letterSpacing = 1.2;
  ReaderFontFamily _selectedFont = ReaderFontFamily.lexend;
  ReaderColorTheme _selectedTheme = ReaderColorTheme.cream;

  // 4 Palet warna latar ramah disleksia
  final List<ReaderColorTheme> _palettes = [
    ReaderColorTheme.cream,
    ReaderColorTheme.peach,
    ReaderColorTheme.pastelBlue,
    ReaderColorTheme.lightGrey,
  ];

  String _getColorName(ReaderColorTheme theme) {
    switch (theme) {
      case ReaderColorTheme.cream:
        return 'Krem';
      case ReaderColorTheme.peach:
        return 'Peach';
      case ReaderColorTheme.pastelBlue:
        return 'Biru Pastel';
      case ReaderColorTheme.lightGrey:
        return 'Abu Lembut';
      default:
        return theme.displayName;
    }
  }

  /// Navigasi langsung ketika tombol 'Lewati' ditekan
  void _skipToHome() {
    try {
      ref
          .read(sharedPreferencesProvider)
          .setBool('has_completed_onboarding', true);
    } catch (_) {}

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  /// Simpan pengaturan kalibrasi terpilih lalu arahkan ke HomeScreen
  Future<void> _startReading() async {
    try {
      final settingsNotifier = ref.read(settingsControllerProvider.notifier);
      await settingsNotifier.updateFontSize(_fontSize);
      await settingsNotifier.updateColorTheme(_selectedTheme);
      await settingsNotifier.updateFontFamily(_selectedFont);
      await settingsNotifier.updateLineSpacing(_lineHeight);
      await settingsNotifier.updateLetterSpacing(_letterSpacing);

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('has_completed_onboarding', true);
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewTextStyle = _selectedFont.getTextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      letterSpacing: _letterSpacing,
      wordSpacing: 2.0,
      color: _selectedTheme.textColor,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Identitas LexiRead & Tombol 'Lewati'
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space8,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7EF),
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                border: Border.all(color: const Color(0xFFDFD7C4), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDimens.radiusS),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEXIREAD',
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Aksesibilitas Disleksia Dewasa',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Tombol Lewati Responsif
                  TextButton.icon(
                    key: const Key('skip_onboarding_button'),
                    onPressed: _skipToHome,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E242B),
                      backgroundColor: const Color(0xFFECE5D2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        side: const BorderSide(
                          color: Color(0xFFDFD7C4),
                          width: 1.2,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      size: 19,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Lewati',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E242B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Konten Utama Kalibrasi Kenyamanan Membaca (Scrollable & Penuh Visual)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Indikator Kalibrasi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'PANDUAN ADAPTIF DISLEKSIA',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space8),

                    // Judul & Subtitle
                    Text(
                      'Kalibrasi Kenyamanan Membaca',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E242B),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      'Atur ukuran teks dan palet latar belakang yang paling menenangkan untuk mata Anda guna mencegah kelelahan membaca dan efek visual crowding.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF4A5568),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // KARTU PRATINJAU TEKS (PREVIEW CARD)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.space18),
                      decoration: BoxDecoration(
                        color: _selectedTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                        border: Border.all(
                          color: _selectedTheme.borderColor,
                          width: 1.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
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
                                  Icon(
                                    Icons.visibility_rounded,
                                    size: 18,
                                    color: _selectedTheme.textColor,
                                  ),
                                  const SizedBox(width: AppDimens.space6),
                                  Text(
                                    'KARTU PRATINJAU TEKS',
                                    style: AppTextStyles.badge.copyWith(
                                      color: _selectedTheme.textColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.space10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTheme.surfaceColor,
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusS),
                                  border: Border.all(
                                    color: _selectedTheme.borderColor,
                                  ),
                                ),
                                child: Text(
                                  '${_fontSize.toStringAsFixed(0)} sp • ${_getColorName(_selectedTheme)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: _selectedTheme.textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space10),
                          Divider(height: 1, color: _selectedTheme.borderColor),
                          const SizedBox(height: AppDimens.space12),
                          Text(
                            'LexiRead dirancang khusus untuk kenyamanan membaca penderita disleksia dewasa. Tata letak dengan spasi lega, huruf berbobot bawah, dan kontras warna yang menenangkan membantu fokus membaca tanpa bayangan huruf yang saling bertumpuk.',
                            style: previewTextStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // KONTROL 1: SLIDER PENGATUR UKURAN FONT (14 - 28 sp)
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7EF),
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                        border: Border.all(
                          color: const Color(0xFFDFD7C4),
                          width: 1.2,
                        ),
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
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusS,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.format_size_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.space10),
                                  Text(
                                    'Ukuran Font',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E242B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusM,
                                  ),
                                ),
                                child: Text(
                                  '${_fontSize.toStringAsFixed(0)} sp',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: const Color(0xFFDFD7C4),
                              thumbColor: AppColors.primary,
                              overlayColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              trackHeight: 4.0,
                            ),
                            child: Slider(
                              value: _fontSize,
                              min: 14.0,
                              max: 28.0,
                              divisions: 14,
                              onChanged: (val) {
                                setState(() {
                                  _fontSize = val;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '14 sp (Kecil)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '28 sp (Besar)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space14),

                    // KONTROL 2: PILIHAN PALET WARNA LATAR (Krem, Peach, Biru Pastel, Abu Lembut)
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7EF),
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                        border: Border.all(
                          color: const Color(0xFFDFD7C4),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusS,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.palette_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppDimens.space10),
                              Text(
                                'Palet Warna Latar Ramah Mata',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E242B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space6),
                          Text(
                            'Pilih palet yang paling meredam silau dan pantulan kontras tajam:',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppDimens.space12),
                          Row(
                            children: _palettes.map((theme) {
                              final isSelected = _selectedTheme == theme;
                              final colorName = _getColorName(theme);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTheme = theme;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.backgroundColor,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusM,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : theme.borderColor,
                                        width: isSelected ? 2.2 : 1.2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: theme.backgroundColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : const Color(0xFFC5BDB2),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          colorName,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: const Color(0xFF1E242B),
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
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space14),

                    // KONTROL 3: PILIHAN JENIS HURUF (FONT FAMILY)
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7EF),
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                        border: Border.all(
                          color: const Color(0xFFDFD7C4),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.radiusS,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.font_download_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppDimens.space10),
                              Text(
                                'Pilihan Jenis Huruf (Font)',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E242B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFontChip(
                                  font: ReaderFontFamily.lexend,
                                  label: 'Lexend',
                                  subtitle: 'Anti-crowding',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFontChip(
                                  font: ReaderFontFamily.openDyslexic,
                                  label: 'OpenDyslexic',
                                  subtitle: 'Bobot Bawah',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFontChip(
                                  font: ReaderFontFamily.sansSerif,
                                  label: 'Sans-Serif',
                                  subtitle: 'Standar Netral',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space16),
                  ],
                ),
              ),
            ),

            // BILAH NAVIGASI BAWAH: TOMBOL "MULAI MEMBACA" MENUJU BERANDA
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7EF),
                border: Border(
                  top: BorderSide(color: Color(0xFFDFD7C4), width: 1.5),
                ),
              ),
              child: ElevatedButton.icon(
                key: const Key('start_reading_button'),
                onPressed: _startReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  'Mulai Membaca',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontChip({
    required ReaderFontFamily font,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedFont == font;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFont = font;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFFAF7EF),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFDFD7C4),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.button.copyWith(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primary : const Color(0xFF1E242B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
