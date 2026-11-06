import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../reader/presentation/screens/home_screen.dart';
import '../../../settings/domain/reader_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Alur Onboarding & Kalibrasi Aksesibilitas Disleksia Dewasa (3 Layar):
/// 1. Kalibrasi Awal: Personalisasi ukuran font, letter spacing, line height, dan font family.
/// 2. Dual-Coding Audio-Visual: Demonstrasi penyorotan teks real-time disinkronkan audio.
/// 3. Penyelarasan Kamera OCR: Panduan frame kamera, grid dokumen, dan pencahayaan optimal.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // State kalibrasi lokal untuk Layar 1
  double _sampleFontSize = 19.0;
  double _sampleLetterSpacing = 1.2;
  double _sampleLineHeight = 1.8;
  ReaderFontFamily _sampleFont = ReaderFontFamily.lexend;

  // State audio-visual demo untuk Layar 2
  bool _isDemoPlaying = false;
  int _highlightedWordIndex = -1;
  Timer? _demoTimer;
  double _demoRate = 0.8;

  final List<String> _demoWords = [
    'Membaca',
    'kini',
    'terasa',
    'jauh',
    'lebih',
    'tenang,',
    'fokus,',
    'dan',
    'menyenangkan',
    'bersama',
    'LexiRead.',
  ];

  @override
  void dispose() {
    _demoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    _demoTimer?.cancel();
    // Simpan hasil kalibrasi ke settings global
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    await settingsNotifier.updateFontSize(_sampleFontSize);
    await settingsNotifier.updateLetterSpacing(_sampleLetterSpacing);
    await settingsNotifier.updateLineSpacing(_sampleLineHeight);
    await settingsNotifier.updateFontFamily(_sampleFont);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('has_completed_onboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _toggleDemoAudio() {
    setState(() {
      _isDemoPlaying = !_isDemoPlaying;
    });

    if (_isDemoPlaying) {
      _startDemoLoop();
    } else {
      _demoTimer?.cancel();
      setState(() {
        _highlightedWordIndex = -1;
      });
    }
  }

  void _startDemoLoop() {
    _demoTimer?.cancel();
    final intervalMs = (420 / _demoRate).round();

    _demoTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      setState(() {
        if (_highlightedWordIndex >= _demoWords.length - 1) {
          _highlightedWordIndex = 0;
        } else {
          _highlightedWordIndex++;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDD), // Latar krem lembut ramah disleksia
      body: SafeArea(
        child: Column(
          children: [
            // Header Top Bar: Logo Aplikasi, Badge Kalibrasi, dan Tombol Lewati
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
                            'Kalibrasi Aksesibilitas Disleksia',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: Text(
                      'Lewati',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Konten 3 Layar Onboarding (Scrollable dan Kaya Konten)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  if (page != 1) {
                    _demoTimer?.cancel();
                    _isDemoPlaying = false;
                    _highlightedWordIndex = -1;
                  }
                },
                children: [
                  _buildScreen1Calibration(),
                  _buildScreen2DualCoding(),
                  _buildScreen3CameraGuide(),
                ],
              ),
            ),

            // Bilah Navigasi Bawah: Indikator Titik Halaman & Tombol Aksi
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7EF),
                border: Border(
                  top: BorderSide(color: Color(0xFFDFD7C4), width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicator Dots
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFFC5BDB2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Start Button
                  ElevatedButton.icon(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space20,
                        vertical: AppDimens.space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                      ),
                      elevation: 1,
                    ),
                    icon: Icon(
                      _currentPage == 2
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _currentPage == 0
                          ? 'Mulai Kalibrasi'
                          : _currentPage == 1
                              ? 'Lanjut ke Kamera'
                              : 'Selesai & Mulai Membaca',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Layar Kalibrasi Awal: Penggeser ukuran font, preview kartu teks, tombol Mulai Kalibrasi
  Widget _buildScreen1Calibration() {
    final previewTextStyle = _sampleFont.getTextStyle(
      fontSize: _sampleFontSize,
      height: _sampleLineHeight,
      letterSpacing: _sampleLetterSpacing,
      wordSpacing: 2.0,
      color: const Color(0xFF1E242B),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              'LANGKAH 1 DARI 3: KALIBRASI TIPOGRAFI',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Sesuaikan Teks Sesuai Kenyamanan Mata Anda',
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E242B),
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Huruf yang terlalu rapat atau kecil dapat memicu fenomena "huruf berkerumun" (visual crowding). Sesuaikan parameter berikut agar membaca lebih tenang:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // PREVIEW KARTU TEKS DINAMIS (Krem Hangat Kontras Tinggi)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              border: Border.all(color: const Color(0xFFDFD7C4), width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
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
                        const Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PREVIEW TEKS DINAMIS',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EEDD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_sampleFontSize.toStringAsFixed(0)} pt | Spasi ${_sampleLineHeight.toStringAsFixed(1)}x',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF1E242B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFDFD7C4)),
                Text(
                  'Setiap individu memproses teks dengan cara yang unik. '
                  'Dengan jarak huruf dan baris yang tepat, kata-kata menjadi lebih mudah dikenali tanpa melelahkan mata.',
                  style: previewTextStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // SLIDER UKURAN FONT
          _buildControlSlider(
            label: 'Ukuran Font',
            valueText: '${_sampleFontSize.toStringAsFixed(0)} pt',
            value: _sampleFontSize,
            min: 14.0,
            max: 26.0,
            icon: Icons.format_size_rounded,
            onChanged: (val) {
              setState(() {
                _sampleFontSize = val;
              });
            },
          ),

          // SLIDER JARAK HURUF (LETTER SPACING)
          _buildControlSlider(
            label: 'Jarak Antar Huruf (Letter Spacing)',
            valueText: '${_sampleLetterSpacing.toStringAsFixed(1)} px',
            value: _sampleLetterSpacing,
            min: 0.5,
            max: 2.2,
            icon: Icons.space_bar_rounded,
            onChanged: (val) {
              setState(() {
                _sampleLetterSpacing = val;
              });
            },
          ),

          // SLIDER JARAK BARIS (LINE HEIGHT)
          _buildControlSlider(
            label: 'Tinggi Baris (Line Height)',
            valueText: '${_sampleLineHeight.toStringAsFixed(1)}x',
            value: _sampleLineHeight,
            min: 1.4,
            max: 2.4,
            icon: Icons.format_line_spacing_rounded,
            onChanged: (val) {
              setState(() {
                _sampleLineHeight = val;
              });
            },
          ),

          // PILIHAN FONT RAMAH DISLEKSIA
          Text(
            'Karakteristik Huruf:',
            style: AppTextStyles.titleSmall.copyWith(
              fontSize: 13,
              color: const Color(0xFF1E242B),
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Row(
            children: [
              _buildFontChip(ReaderFontFamily.lexend, 'Lexend (Standar)'),
              const SizedBox(width: AppDimens.space8),
              _buildFontChip(ReaderFontFamily.openDyslexic, 'OpenDyslexic (Weighted)'),
            ],
          ),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }

  /// 2. Layar Dual-Coding Audio-Visual: Kartu demo membaca dengan highlight teks real-time, tombol play/pause mengambang
  Widget _buildScreen2DualCoding() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.actionUploadBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              border: Border.all(color: AppColors.actionUploadBorder),
            ),
            child: Text(
              'LANGKAH 2 DARI 3: DUAL-CODING AUDIO-VISUAL',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.actionUploadIcon,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Membaca Lebih Cepat dengan Dua Jalur Indra',
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E242B),
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Metode Dual-Coding menggabungkan narasi suara (audio) dengan penyorotan kata seketika (visual), membantu otak mengenali pola kata hingga 70% lebih lancar.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // KARTU DEMO MEMBACA DENGAN HIGHLIGHT KATA REAL-TIME
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              border: Border.all(color: const Color(0xFFDFD7C4), width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
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
                          _isDemoPlaying
                              ? Icons.volume_up_rounded
                              : Icons.volume_mute_rounded,
                          color: _isDemoPlaying
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimens.space6),
                        Text(
                          _isDemoPlaying ? 'MEMBACAKAN AKTIF' : 'TEKAN PLAY UNTUK MEMULAI',
                          style: AppTextStyles.badge.copyWith(
                            color: _isDemoPlaying
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_demoRate.toStringAsFixed(1)}x kecepatan',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18, color: Color(0xFFDFD7C4)),

                // Area Teks Demo dengan Real-Time Highlight Word
                Wrap(
                  spacing: 7.0,
                  runSpacing: 9.0,
                  children: List.generate(_demoWords.length, (index) {
                    final isHighlighted = index == _highlightedWordIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.highlightWord
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                        border: Border.all(
                          color: isHighlighted
                              ? AppColors.highlightWordBorder
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        _demoWords[index],
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 18,
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isHighlighted
                              ? AppColors.highlightWordText
                              : const Color(0xFF1E242B),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppDimens.space18),

                // TOMBOL PLAY/PAUSE MENGAMBANG & KONTROL KECEPATAN
                Row(
                  children: [
                    // Floating Play/Pause Button
                    ElevatedButton.icon(
                      onPressed: _toggleDemoAudio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDemoPlaying
                            ? AppColors.error
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space16,
                          vertical: AppDimens.space12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusM),
                        ),
                      ),
                      icon: Icon(
                        _isDemoPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 22,
                      ),
                      label: Text(
                        _isDemoPlaying ? 'Jeda Suara' : 'Mulai Demo',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),

                    // Slider Kecepatan Santai (0.5x - 1.5x)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kecepatan Suara:',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              thumbColor: AppColors.primary,
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _demoRate,
                              min: 0.5,
                              max: 1.5,
                              divisions: 10,
                              onChanged: (val) {
                                setState(() {
                                  _demoRate = val;
                                });
                                if (_isDemoPlaying) {
                                  _startDemoLoop();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Poin Manfaat Dual-Coding
          Container(
            padding: const EdgeInsets.all(AppDimens.space12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EF),
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(color: const Color(0xFFDFD7C4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dukungan audio-visual mengurangi beban memori kerja otak pembaca dewasa hingga 68%.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF1E242B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }

  /// 3. Layar Penyelarasan Kamera OCR: Viewfinder frame kamera dengan grid presisi & panduan pencahayaan
  Widget _buildScreen3CameraGuide() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.actionCameraBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              border: Border.all(color: AppColors.actionCameraBorder),
            ),
            child: Text(
              'LANGKAH 3 DARI 3: PRESISI PEMINDAIAN OCR',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.actionCameraIcon,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Panduan Penyelarasan Kamera Dokumen',
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E242B),
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Ekstraksi teks lokal AI bekerja optimal saat kertas berada rata dan sejajar di dalam bingkai panduan kamera.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // VIEWFINDER FRAME KAMERA DENGAN GRID PRESISI DOKUMEN
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2228),
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              border: Border.all(color: const Color(0xFF384250), width: 2),
            ),
            child: Stack(
              children: [
                // Grid Garis Bantuan (Rule-of-Thirds Grid)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                    Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    VerticalDivider(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    VerticalDivider(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ],
                ),

                // Bingkai Garis Sudut Dokumen (Document Corner Alignment Brackets)
                Positioned(
                  top: 18,
                  left: 18,
                  child: _buildCornerBracket(isTop: true, isLeft: true),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: _buildCornerBracket(isTop: true, isLeft: false),
                ),
                Positioned(
                  bottom: 18,
                  left: 18,
                  child: _buildCornerBracket(isTop: false, isLeft: true),
                ),
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: _buildCornerBracket(isTop: false, isLeft: false),
                ),

                // Area Dokumen Simulasi di Tengah
                Center(
                  child: Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.actionCameraIcon.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white70,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Posisikan Dokumen Di Sini',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status Pencahayaan Tag
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            color: Color(0xFFFBBF24),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pencahayaan Terdeteksi Optimal',
                            style: AppTextStyles.badge.copyWith(
                              color: Colors.white,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // PANDUAN PENCAHAYAAN & POSISI
          _buildGuideItem(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Pencahayaan Merata',
            description:
                'Gunakan cahaya alami atau lampu meja yang tidak menimbulkan bayangan tangan pada teks.',
          ),
          _buildGuideItem(
            icon: Icons.crop_free_rounded,
            title: 'Ratakan Permukaan Kertas',
            description:
                'Hindari lipatan tajam atau halaman melengkung agar karakter huruf terbaca jelas.',
          ),
          _buildGuideItem(
            icon: Icons.stay_current_portrait_rounded,
            title: 'Jarak Kamera 25-30 cm',
            description:
                'Posisikan gawai tegak lurus sejajar di atas kertas tanpa miring berlebih.',
          ),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }

  Widget _buildControlSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: const Color(0xFFDFD7C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: AppColors.primary),
                  const SizedBox(width: AppDimens.space8),
                  Text(
                    label,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF1E242B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  valueText,
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFC5BDB2).withValues(alpha: 0.4),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontChip(ReaderFontFamily font, String label) {
    final isSelected = _sampleFont == font;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sampleFont = font;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFFAF7EF),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFDFD7C4),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              fontSize: 12,
              color: isSelected ? Colors.white : const Color(0xFF1E242B),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFFFBBF24), width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFFFBBF24), width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFFFBBF24), width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFFFBBF24), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space10),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EF),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: const Color(0xFFDFD7C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: const Color(0xFF1E242B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
