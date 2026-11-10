import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../reader/presentation/controllers/home_controller.dart';
import '../../domain/reader_settings.dart';
import '../controllers/settings_controller.dart';

/// Layar Pengaturan Tampilan Baca (Sesuai screen_4.png)
/// Mengatur tipografi BDA, palet warna anti-silau, dan multi-voice natural TTS
class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  // Nilai lokal sementara untuk live preview
  late ReaderFontFamily _fontFamily;
  late double _fontSize;
  late double _lineSpacing;
  late double _letterSpacing;
  late ReaderColorTheme _colorTheme;
  late bool _enableLineShading;
  late String _voiceProfile;
  late double _speechRate;
  late bool _syncWordHighlight;
  late bool _autoSyllableSplit;

  bool _initialized = false;

  final List<ReaderColorTheme> _palettes = [
    ReaderColorTheme.cream,
    ReaderColorTheme.lightGrey,
    ReaderColorTheme.mint,
    ReaderColorTheme.peach,
    ReaderColorTheme.lowContrastDark,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final settings = ref.read(settingsControllerProvider);
      _fontFamily = settings.fontFamily;
      _fontSize = settings.fontSize.clamp(14.0, 24.0);
      _lineSpacing = settings.lineSpacing;
      _letterSpacing = settings.letterSpacing;
      _colorTheme = settings.colorTheme;
      _enableLineShading = settings.enableLineShading;
      _voiceProfile = settings.voiceProfile;
      _speechRate = settings.speechRate;
      _syncWordHighlight = settings.syncWordHighlight;
      _autoSyllableSplit = settings.autoSyllableSplit;
      _initialized = true;
    }
  }

  Future<void> _savePreferences() async {
    final notifier = ref.read(settingsControllerProvider.notifier);
    await notifier.updateFontFamily(_fontFamily);
    await notifier.updateFontSize(_fontSize);
    await notifier.updateLineSpacing(_lineSpacing);
    await notifier.updateLetterSpacing(_letterSpacing);
    await notifier.updateColorTheme(_colorTheme);
    await notifier.toggleLineShading(_enableLineShading);
    await notifier.updateVoiceProfile(_voiceProfile);
    await notifier.updateSpeechRate(_speechRate);
    await notifier.toggleSyncWordHighlight(_syncWordHighlight);
    await notifier.toggleAutoSyllableSplit(_autoSyllableSplit);

    final tts = ref.read(ttsServiceProvider);
    await tts.applyVoiceProfile(_voiceProfile);
    await tts.setSpeechRate(_speechRate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Preferensi baca berhasil disimpan!'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _resetToBda() async {
    setState(() {
      _fontFamily = ReaderFontFamily.lexend;
      _fontSize = 18.0;
      _lineSpacing = 1.8;
      _letterSpacing = 1.2;
      _colorTheme = ReaderColorTheme.cream;
      _enableLineShading = true;
      _voiceProfile = 'Bima (Pria Tenang)';
      _speechRate = 0.9;
      _syncWordHighlight = true;
      _autoSyllableSplit = true;
    });

    final notifier = ref.read(settingsControllerProvider.notifier);
    await notifier.resetToBdaDefaults();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preferensi dikembalikan ke rekomendasi BDA!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _testVoice(String profileName) async {
    final tts = ref.read(ttsServiceProvider);
    await tts.testVoice(profileName);
  }

  @override
  Widget build(BuildContext context) {
    final previewTextStyle = _fontFamily.getTextStyle(
      fontSize: _fontSize,
      height: _lineSpacing,
      letterSpacing: _letterSpacing,
      wordSpacing: 2.0,
      color: _colorTheme.textColor,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8EE), // Latar anti-silau BacaTenang
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E242B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'BacaTenang',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E242B),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Text(
              'Preferensi Aksesibilitas',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _savePreferences,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Simpan',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU PRATINJAU LANGSUNG (LIVE PREVIEW) BERDASARKAN BDA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space18),
              decoration: BoxDecoration(
                color: _colorTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                border: Border.all(
                  color: _colorTheme.borderColor,
                  width: 1.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
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
                            size: 16,
                            color: _colorTheme.textColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PRATINJAU LANGSUNG',
                            style: AppTextStyles.badge.copyWith(
                              color: _colorTheme.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
                          color: const Color(0xFFEBF5FB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDDF0)),
                        ),
                        child: Text(
                          'Berdasarkan BDA',
                          style: AppTextStyles.badge.copyWith(
                            color: const Color(0xFF1D4ED8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Divider(height: 1, color: _colorTheme.borderColor),
                  const SizedBox(height: AppDimens.space12),
                  if (_enableLineShading) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _colorTheme.shadingColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Membaca dengan tenang membuka pemahaman yang lebih dalam tanpa kelelahan mata.',
                        style: previewTextStyle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Spasi yang lega dan kontras warna lembut mencegah distorsi visual huruf berkerumun.',
                      style: previewTextStyle,
                    ),
                  ] else ...[
                    Text(
                      'Membaca dengan tenang membuka pemahaman yang lebih dalam tanpa kelelahan mata. Spasi yang lega dan kontras warna lembut mencegah distorsi visual huruf berkerumun.',
                      style: previewTextStyle,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space20),

            // 2. BAGIAN PILIHAN TIPOGRAFI
            _buildSectionCard(
              title: 'Pilihan Tipografi',
              icon: Icons.text_fields_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilihan Font (Lexend, OpenDyslexic, Verdana)
                  Text(
                    'Jenis Huruf',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        label: 'Lexend (Rekomendasi)',
                        isSelected: _fontFamily == ReaderFontFamily.lexend,
                        onTap: () => setState(
                          () => _fontFamily = ReaderFontFamily.lexend,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'OpenDyslexic',
                        isSelected: _fontFamily == ReaderFontFamily.openDyslexic,
                        onTap: () => setState(
                          () => _fontFamily = ReaderFontFamily.openDyslexic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildChip(
                        label: 'Verdana / Sans-Serif',
                        isSelected: _fontFamily == ReaderFontFamily.sansSerif,
                        onTap: () => setState(
                          () => _fontFamily = ReaderFontFamily.sansSerif,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Slider Ukuran Font (14 - 24 pt)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ukuran Font',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_fontSize.toStringAsFixed(0)} pt',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 24.0,
                    divisions: 10,
                    activeColor: AppColors.primary,
                    inactiveColor: const Color(0xFFDFD7C4),
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),

                  const SizedBox(height: AppDimens.space12),

                  // Jarak Baris (1.5x, 1.8x, 2.0x)
                  Text(
                    'Jarak Baris (Line Spacing)',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        label: '1.5x',
                        isSelected: (_lineSpacing - 1.5).abs() < 0.05,
                        onTap: () => setState(() => _lineSpacing = 1.5),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: '1.8x (Standar BDA)',
                        isSelected: (_lineSpacing - 1.8).abs() < 0.05,
                        onTap: () => setState(() => _lineSpacing = 1.8),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: '2.0x',
                        isSelected: (_lineSpacing - 2.0).abs() < 0.05,
                        onTap: () => setState(() => _lineSpacing = 2.0),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.space16),

                  // Jarak Antar Huruf (Standar, Renggang, Sangat Renggang)
                  Text(
                    'Jarak Antar Huruf (Letter Spacing)',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        label: 'Standar (0.8)',
                        isSelected: (_letterSpacing - 0.8).abs() < 0.1,
                        onTap: () => setState(() => _letterSpacing = 0.8),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'Renggang (1.2)',
                        isSelected: (_letterSpacing - 1.2).abs() < 0.1,
                        onTap: () => setState(() => _letterSpacing = 1.2),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'Sangat Renggang (1.8)',
                        isSelected: (_letterSpacing - 1.8).abs() < 0.1,
                        onTap: () => setState(() => _letterSpacing = 1.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space16),

            // 3. PALET WARNA ANTI-SILAU & LINE SHADING
            _buildSectionCard(
              title: 'Palet Warna Anti-Silau',
              icon: Icons.palette_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilihan Latar Belakang Ramah Irlen Syndrome:',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palettes.map((theme) {
                      final isSelected = _colorTheme == theme;
                      return GestureDetector(
                        onTap: () => setState(() => _colorTheme = theme),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.backgroundColor,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusM),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : theme.borderColor,
                              width: isSelected ? 2.2 : 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
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
                                        size: 10,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                theme.displayName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: theme.textColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Divider(height: 1, color: const Color(0xFFE2DDD1)),
                  const SizedBox(height: AppDimens.space12),

                  // Sakelar Arsir Baris Bergantian (Line Shading)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Arsir Baris Bergantian (Line Shading)',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Memberikan latar lembut selang-seling per baris agar fokus mata tidak tersesat.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
                    ),
                    value: _enableLineShading,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _enableLineShading = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space16),

            // 4. PEMBACAAN SUARA (NATURAL MULTI-VOICE)
            _buildSectionCard(
              title: 'Pembacaan Suara (Natural Multi-Voice)',
              icon: Icons.record_voice_over_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilihan Profil Suara Bahasa Indonesia:',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3 Profil Alami: Bima, Dian, Laras
                  _buildVoiceTile(
                    profileKey: 'bima',
                    name: 'Bima (Pria Tenang)',
                    desc: 'Pria Tenang & Berbobot',
                    icon: Icons.face_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildVoiceTile(
                    profileKey: 'dian',
                    name: 'Dian (Wanita Tenang)',
                    desc: 'Wanita Alami, Lembut & Tenang',
                    icon: Icons.face_3_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildVoiceTile(
                    profileKey: 'laras',
                    name: 'Laras (Wanita Cepat/Jelas)',
                    desc: 'Wanita Artikulasi Cepat & Tegas',
                    icon: Icons.face_4_rounded,
                  ),

                  const SizedBox(height: AppDimens.space16),

                  // Pilihan Kecepatan Baca: 0.75x, 1.0x, 1.25x
                  Text(
                    'Kecepatan Baca (Speech Rate)',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        label: '0.75x (Santai)',
                        isSelected: (_speechRate - 0.75).abs() < 0.05,
                        onTap: () => setState(() => _speechRate = 0.75),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: '1.0x (Normal)',
                        isSelected: (_speechRate - 1.0).abs() < 0.05,
                        onTap: () => setState(() => _speechRate = 1.0),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: '1.25x (Tangkas)',
                        isSelected: (_speechRate - 1.25).abs() < 0.05,
                        onTap: () => setState(() => _speechRate = 1.25),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimens.space16),
                  Divider(height: 1, color: const Color(0xFFE2DDD1)),
                  const SizedBox(height: AppDimens.space12),

                  // Sakelar Sorot Kata Sinkron
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Sorot Kata Sinkron (Read-Along)',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Menyorot kata aktif berwarna kuning pastel real-time mengikuti audio TTS.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
                    ),
                    value: _syncWordHighlight,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _syncWordHighlight = val),
                  ),

                  // Sakelar Pemecah Suku Kata Otomatis
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Pemecah Suku Kata Otomatis',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      'Garis bawah putus-putus pada kata majemuk untuk memudahkan pemenggalan fonik.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
                    ),
                    value: _autoSyllableSplit,
                    activeColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => _autoSyllableSplit = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space24),

            // 5. TOMBOL AKSI BAWAH
            ElevatedButton.icon(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                'Simpan Preferensi Baca',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _resetToBda,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                ),
              ),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(
                'Kembalikan ke Rekomendasi BDA',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: const Color(0xFFDFD7C4), width: 1.2),
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
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: const Color(0xFF1E242B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space14),
          child,
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFECE5D2),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFDFD7C4),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF1E242B),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceTile({
    required String name,
    required String desc,
    required IconData icon,
    String? profileKey,
  }) {
    final pKey = profileKey ?? name.split(' ').first.toLowerCase();
    final current = _voiceProfile.toLowerCase();
    final isSelected = current == name.toLowerCase() ||
        current == pKey ||
        current.contains(pKey);

    return InkWell(
      onTap: () {
        setState(() => _voiceProfile = name);
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFFAF7EF),
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFDFD7C4),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: name,
              groupValue: isSelected ? name : '',
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _voiceProfile = val);
              },
            ),
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF1E242B),
                    ),
                  ),
                  Text(
                    desc,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _testVoice(name),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(80, 32),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
              icon: const Icon(Icons.volume_up_rounded, size: 14),
              label: const Text('Uji Dengar', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
