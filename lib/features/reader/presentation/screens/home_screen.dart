import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../ocr/presentation/screens/ocr_preprocessing_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/reading_document.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_card.dart';
import '../widgets/advanced_audio_sheet.dart';
import '../widgets/reading_history_card.dart';
import '../widgets/typography_sheet.dart';
import '../widgets/upload_source_dialog.dart';
import 'manual_text_dialog.dart';
import 'reader_screen.dart';

/// Layar Beranda (Home Screen) LexiRead:
/// Didesain dengan prinsip aksesibilitas disleksia dewasa:
/// Latar belakang krem lembut (#FDFBF7), font Lexend, statistik waktu baca,
/// 3 tombol aksi kartu besar, riwayat bacaan, dan FAB pemindaian kamera.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0: Semua, 1: Sedang Dibaca, 2: Selesai
  int _selectedFilter = 0;

  void _openReader(BuildContext context, ReadingDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(document: document),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openOnboarding(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      ),
    );
  }

  void _openTypographySheet(BuildContext context) {
    TypographySheet.show(context);
  }

  void _openAudioSheet(BuildContext context) {
    AdvancedAudioSheet.show(context);
  }

  void _showAccessibilityMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXL),
          ),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space16,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              Text(
                'Menu & Pengaturan Aksesibilitas',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // 1. Modal Tipografi
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: const Icon(Icons.text_fields_rounded, color: AppColors.primary),
                ),
                title: Text(
                  'Modal Tipografi & Teks',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Atur ukuran font, spasi baris, jarak huruf, dan tema warna.',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openTypographySheet(context);
                },
              ),
              const Divider(color: AppColors.border, height: 16),

              // 2. Setelan Audio TTS
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.actionCameraBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: AppColors.actionCameraIcon),
                ),
                title: Text(
                  'Setelan Audio TTS',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Atur kecepatan suara, pitch vokal, dan durasi jeda kata.',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAudioSheet(context);
                },
              ),
              const Divider(color: AppColors.border, height: 16),

              // 3. Kalibrasi Ulang (Onboarding)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.actionUploadBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.actionUploadIcon),
                ),
                title: Text(
                  'Kalibrasi Kenyamanan Membaca',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Buka kembali panduan kalibrasi teks dan warna latar adaptif.',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openOnboarding(context);
                },
              ),
              const Divider(color: AppColors.border, height: 16),

              // 4. Pengaturan Sistem Lengkap
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.actionPasteBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: const Icon(Icons.settings_rounded, color: AppColors.actionPasteIcon),
                ),
                title: Text(
                  'Semua Pengaturan Aplikasi',
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Lihat dan kelola seluruh preferensi membaca LexiRead.',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSettings(context);
                },
              ),
              const SizedBox(height: AppDimens.space8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanWithCamera(BuildContext context) async {
    final controller = ref.read(homeControllerProvider.notifier);
    final imagePath =
        await controller.pickImagePath(source: ImageSource.camera);
    if (imagePath != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrPreprocessingScreen(
            imagePath: imagePath,
            documentTitle:
                'Foto Dokumen ${AccessibilityUtils.formatFriendlyDate(DateTime.now())}',
          ),
        ),
      );
    }
  }

  List<ReadingDocument> _filterDocuments(List<ReadingDocument> docs) {
    if (_selectedFilter == 1) {
      return docs.where((doc) => !doc.isCompleted).toList();
    } else if (_selectedFilter == 2) {
      return docs.where((doc) => doc.isCompleted).toList();
    }
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final greeting = AccessibilityUtils.getGreetingByTime();
    final filteredHistory = _filterDocuments(state.history);

    // Hitung statistik membaca
    final completedDocs = state.history.where((d) => d.isCompleted).length;
    final totalWordsRead = state.history.fold<int>(
      0,
      (sum, d) => sum + d.currentWordIndex,
    );
    final totalReadingMinutes = (totalWordsRead / 120).ceil();

    // Tampilkan snackbar jika ada pesan error
    ref.listen<HomeState>(homeControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            action: SnackBarAction(
              label: AppStrings.btnClose,
              textColor: Colors.white,
              onPressed: () {
                controller.clearError();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanWithCamera(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.camera_alt_rounded, size: 22),
        label: Text(
          'Pindai Dokumen Baru',
          style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.5),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Sapaan yang Tenang & Ramah + Tombol Kalibrasi & Pengaturan
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.space20,
                      right: AppDimens.space20,
                      top: AppDimens.space16,
                      bottom: AppDimens.space12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Nama Aplikasi & Aksi Cepat Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.progressFill,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppDimens.space8),
                                Text(
                                  AppStrings.appName.toUpperCase(),
                                  style: AppTextStyles.badge.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                // 1. Tombol Buka Modal Tipografi
                                IconButton(
                                  icon: const Icon(
                                    Icons.text_fields_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Modal Tipografi Adaptif',
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    padding: const EdgeInsets.all(7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusM,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => _openTypographySheet(context),
                                ),
                                const SizedBox(width: 6),

                                // 2. Tombol Buka Setelan Audio TTS
                                IconButton(
                                  icon: const Icon(
                                    Icons.volume_up_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Setelan Audio TTS',
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    padding: const EdgeInsets.all(7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusM,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => _openAudioSheet(context),
                                ),
                                const SizedBox(width: 6),

                                // 3. Tombol Menu Aksesibilitas & Pengaturan
                                IconButton(
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Menu & Pengaturan Aksesibilitas',
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    padding: const EdgeInsets.all(7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusM,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => _showAccessibilityMenu(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.space8),

                        // Sapaan Utama
                        Text(
                          '$greeting, Pembaca',
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppDimens.space4),

                        // Subtitle Penuntun
                        Text(
                          AppStrings.headerSubtitle,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // KARTU STATISTIK WAKTU BACA & DOKUMEN TUNTAS 100%
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space20,
                      vertical: AppDimens.space6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.actionUploadBg,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusM,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.timer_outlined,
                                    color: AppColors.actionUploadIcon,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Waktu Membaca',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '$totalReadingMinutes Menit',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.actionCameraBg,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusM,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: AppColors.actionCameraIcon,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tuntas 100%',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '$completedDocs Dokumen',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 3 KARTU AKSI UTAMA (Ukuran Besar & Mudah Ditekan)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: AppDimens.space8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Ambil Foto Dokumen (Kamera) -> Pra-Pemrosesan OCR
                      ActionCard(
                        title: AppStrings.actionCameraTitle,
                        subtitle: AppStrings.actionCameraSubtitle,
                        badgeText: AppStrings.actionCameraBadge,
                        icon: Icons.camera_alt_rounded,
                        backgroundColor: AppColors.actionCameraBg,
                        borderColor: AppColors.actionCameraBorder,
                        iconColor: AppColors.actionCameraIcon,
                        iconBgColor: AppColors.actionCameraIconBg,
                        onTap: () => _scanWithCamera(context),
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // 2. Unggah Berkas / Galeri (File Picker: PDF & Gambar / Galeri Foto)
                      ActionCard(
                        title: AppStrings.actionUploadTitle,
                        subtitle: AppStrings.actionUploadSubtitle,
                        badgeText: AppStrings.actionUploadBadge,
                        icon: Icons.folder_open_rounded,
                        backgroundColor: AppColors.actionUploadBg,
                        borderColor: AppColors.actionUploadBorder,
                        iconColor: AppColors.actionUploadIcon,
                        iconBgColor: AppColors.actionUploadIconBg,
                        onTap: () async {
                          final choice = await UploadSourceDialog.show(context);
                          if (choice == null) return;

                          if (choice == UploadSourceChoice.gallery) {
                            final imagePath = await controller.pickImagePath(
                              source: ImageSource.gallery,
                            );
                            if (imagePath != null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OcrPreprocessingScreen(
                                    imagePath: imagePath,
                                    documentTitle:
                                        'Dokumen Galeri ${AccessibilityUtils.formatFriendlyDate(DateTime.now())}',
                                  ),
                                ),
                              );
                              return;
                            }
                          } else {
                            final doc =
                                await controller.pickFromFileOrGallery();
                            if (doc != null && context.mounted) {
                              _openReader(context, doc);
                            }
                          }
                        },
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // 3. Tempel Teks Manual
                      ActionCard(
                        title: AppStrings.actionPasteTitle,
                        subtitle: AppStrings.actionPasteSubtitle,
                        badgeText: AppStrings.actionPasteBadge,
                        icon: Icons.content_paste_go_rounded,
                        backgroundColor: AppColors.actionPasteBg,
                        borderColor: AppColors.actionPasteBorder,
                        iconColor: AppColors.actionPasteIcon,
                        iconBgColor: AppColors.actionPasteIconBg,
                        onTap: () {
                          ManualTextInputSheet.show(
                            context,
                            onSubmit: (title, content) async {
                              final doc = await controller.addManualText(
                                title,
                                content,
                              );
                              if (context.mounted) {
                                _openReader(context, doc);
                              }
                            },
                          );
                        },
                      ),
                    ]),
                  ),
                ),

                // SECTION TITLE & FILTER: RIWAYAT BACAAN TERAKHIR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.space20,
                      right: AppDimens.space20,
                      top: 24.0,
                      bottom: AppDimens.space12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.historySectionTitle,
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (state.history.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.space8,
                                  vertical: AppDimens.space2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceTinted,
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusS),
                                ),
                                child: Text(
                                  '${state.history.length} dokumen',
                                  style: AppTextStyles.badge.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.space12),

                        // Tombol Filter Status Bacaan (Semua, Sedang Dibaca, Selesai)
                        if (state.history.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(0, 'Semua'),
                                const SizedBox(width: AppDimens.space8),
                                _buildFilterChip(1, 'Sedang Dibaca'),
                                const SizedBox(width: AppDimens.space8),
                                _buildFilterChip(2, 'Selesai'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // DAFTAR RIWAYAT BACAAN DENGAN PROGRES
                if (filteredHistory.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space20,
                        vertical: AppDimens.space24,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.space24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWarm,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusL),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 44,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppDimens.space12),
                            Text(
                              _selectedFilter == 0
                                  ? AppStrings.historyEmptyTitle
                                  : 'Tidak Ada Dokumen pada Kategori Ini',
                              style: AppTextStyles.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              _selectedFilter == 0
                                  ? AppStrings.historyEmptySubtitle
                                  : 'Ubah filter atau tambahkan dokumen baru untuk melihat daftar bacaan.',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimens.space16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final doc = await controller.addManualText(
                                  'Mengenal Tipografi Nyaman Membaca',
                                  'Membaca adalah jendela dunia yang terbuka lebar untuk siapa saja. '
                                  'Bagi pembaca disleksia dewasa, kenyamanan visual seperti jarak baris yang cukup, '
                                  'huruf yang tidak rapat, dan latar belakang krem lembut sangat membantu mata '
                                  'fokus pada satu kata tanpa melompat-lompat antar baris. '
                                  'LexiRead hadir mendampingi perjalanan baca Anda setiap saat.',
                                );
                                if (context.mounted) {
                                  _openReader(context, doc);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusM),
                                ),
                              ),
                              icon: const Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                              ),
                              label: const Text('Buka Bacaan Contoh Sekarang'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space20,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = filteredHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppDimens.space16,
                            ),
                            child: ReadingHistoryCard(
                              document: doc,
                              onTap: () => _openReader(context, doc),
                              onDelete: () =>
                                  controller.deleteDocument(doc.id),
                            ),
                          );
                        },
                        childCount: filteredHistory.length,
                      ),
                    ),
                  ),

                // Ruang ekstra di bawah agar tidak tertutup FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 90.0),
                ),
              ],
            ),
          ),

          // TRANSISI LOADING YANG MENENANGKAN (Accessibility-First)
          if (state.isLoading)
            LoadingOverlay(
              title: state.loadingTitle,
              subtitle: state.loadingSubtitle,
              onCancel: () {
                controller.cancelLoading();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            fontSize: 13,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
