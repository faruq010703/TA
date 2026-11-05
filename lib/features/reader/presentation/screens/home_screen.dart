import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../domain/models/reading_document.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_card.dart';
import '../widgets/reading_history_card.dart';
import 'manual_text_dialog.dart';
import 'reader_screen.dart';

/// Layar Beranda (Home Screen) LexiRead:
/// Didesain dengan prinsip aksesibilitas disleksia dewasa:
/// Latar belakang krem lembut, font Lexend, 3 tombol aksi kartu besar yang mudah dijangkau,
/// dan daftar riwayat bacaan dengan visual progress bar.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openReader(BuildContext context, ReadingDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final greeting = AccessibilityUtils.getGreetingByTime();

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
                // Header Sapaan yang Tenang & Ramah
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.space20,
                      right: AppDimens.space20,
                      top: AppDimens.space20,
                      bottom: AppDimens.space12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Nama Aplikasi
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

                      // 2. Unggah Berkas / Galeri (File Picker: PDF & Gambar)
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
                          final doc = await controller.pickFromFileOrGallery();
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

                // SECTION TITLE: RIWAYAT BACAAN TERAKHIR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.space20,
                      right: AppDimens.space20,
                      top: 28.0,
                      bottom: AppDimens.space12,
                    ),
                    child: Row(
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
                          Text(
                            '${state.history.length} dokumen',
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),

                // DAFTAR RIWAYAT BACAAN DENGAN PROGRES
                if (state.history.isEmpty)
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
                              AppStrings.historyEmptyTitle,
                              style: AppTextStyles.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              AppStrings.historyEmptySubtitle,
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
                          final doc = state.history[index];
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
                        childCount: state.history.length,
                      ),
                    ),
                  ),

                // Ruang santai di bawah
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
}
