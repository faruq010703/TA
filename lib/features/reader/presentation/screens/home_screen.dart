import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/reading_document.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_card.dart';
import '../widgets/reading_history_card.dart';
import '../widgets/upload_source_dialog.dart';
import 'manual_text_dialog.dart';
import 'reader_screen.dart';

/// Layar Beranda (Home Screen) LexiRead:
/// Didesain dengan prinsip aksesibilitas disleksia dewasa:
/// Latar belakang krem lembut (#FDFBF7), font Lexend, 3 tombol aksi kartu besar yang mudah dijangkau,
/// dan daftar riwayat bacaan dengan visual progress bar.
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
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Sapaan yang Tenang & Ramah + Tombol Pengaturan Aksesibilitas
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
                        // Tag Nama Aplikasi & Tombol Pengaturan
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

                            // Tombol Pengaturan Tampilan Ramah Disleksia
                            IconButton(
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 24,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Pengaturan Aksesibilitas Baca',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusM),
                                ),
                              ),
                              onPressed: () => _openSettings(context),
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

                // 3 KARTU AKSI UTAMA (Ukuran Besar & Mudah Ditekan)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: AppDimens.space8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Ambil Foto Dokumen (Kamera)
                      ActionCard(
                        title: AppStrings.actionCameraTitle,
                        subtitle: AppStrings.actionCameraSubtitle,
                        badgeText: AppStrings.actionCameraBadge,
                        icon: Icons.camera_alt_rounded,
                        backgroundColor: AppColors.actionCameraBg,
                        borderColor: AppColors.actionCameraBorder,
                        iconColor: AppColors.actionCameraIcon,
                        iconBgColor: AppColors.actionCameraIconBg,
                        onTap: () async {
                          final doc = await controller.pickFromCamera();
                          if (doc != null && context.mounted) {
                            _openReader(context, doc);
                          }
                        },
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

                          ReadingDocument? doc;
                          if (choice == UploadSourceChoice.gallery) {
                            doc = await controller.pickFromGallery();
                          } else {
                            doc = await controller.pickFromFileOrGallery();
                          }

                          if (doc != null && context.mounted) {
                            _openReader(context, doc);
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
                      top: 28.0,
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
                              onDelete: () => controller.deleteDocument(doc.id),
                            ),
                          );
                        },
                        childCount: filteredHistory.length,
                      ),
                    ),
                  ),

                // Ruang santai di bawah agar tidak terpotong tepi layar
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimens.space32),
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
