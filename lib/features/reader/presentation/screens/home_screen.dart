import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../ocr/presentation/screens/ocr_processing_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../settings/presentation/screens/appearance_settings_screen.dart';
import '../../domain/models/reading_document.dart';
import '../controllers/home_controller.dart';
import '../widgets/action_card.dart';
import '../widgets/reading_history_card.dart';
import '../widgets/upload_source_dialog.dart';
import 'manual_text_dialog.dart';
import 'reader_screen.dart';

/// Layar Beranda (HomeScreen - Sesuai screen_3.png):
/// Didesain dengan prinsip aksesibilitas disleksia dewasa:
/// Latar belakang lembut anti-silau (#FBF8EE), sapaan "Halo, Cak Faruq 👋",
/// 3 kartu input dokumen besar (Kamera, Unggah, Tempel Teks),
/// kartu "Lanjutkan Membaca" (Jurnal Psikologi Kognitif - Bab 3),
/// riwayat dokumen, dan BottomNavigationBar 4 tab aktif.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentBottomNavIndex = 0;
  final int _selectedFilter = 0; // 0: Semua, 1: Sedang Dibaca, 2: Selesai

  // Dokumen unggulan "Lanjutkan Membaca"
  final ReadingDocument _continueReadingDoc = ReadingDocument(
    id: 'continue_doc_kognitif_3',
    title: 'Jurnal Psikologi Kognitif - Bab 3',
    content:
        'BAB 3: PROSES KOGNITIF DAN METAKOGNISI DALAM MEMBACA\n\n'
        'Membaca pemahaman adalah proses aktif yang melibatkan koordinasi persepsi visual, '
        'kesadaran fonologis, dan regulasi metakognitif. Bagi pembaca dengan disleksia dewasa, '
        'beban kognitif (cognitive load) sering kali meningkat akibat pemrosesan grafem-ke-fonem '
        'yang memerlukan energi mental lebih tinggi.\n\n'
        'Pendekatan dual-coding mengusulkan bahwa representasi informasi verbal dan nonverbal '
        'disimpan dalam sistem memori yang terpisah namun saling berhubungan. Ketika teks tertulis '
        'disertai dengan panduan suara yang selaras, jalur visual dan auditori bekerja sama '
        'memperkuat pemahaman makna kalimat secara signifikan tanpa kelelahan mata.',
    snippet:
        'Proses aktif yang melibatkan koordinasi persepsi visual, kesadaran fonologis, dan regulasi metakognitif...',
    sourceType: DocumentSourceType.file,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    lastReadAt: DateTime.now(),
    currentWordIndex: 65,
    totalWords: 100,
  );

  void _openReader(BuildContext context, ReadingDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(document: document),
      ),
    );
  }

  void _openAppearanceSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppearanceSettingsScreen(),
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

  /// 1. Aksi Pindai Kamera: Membuka ImagePicker kamera lalu masuk ke OcrProcessingScreen
  Future<void> _scanWithCamera(BuildContext context) async {
    final controller = ref.read(homeControllerProvider.notifier);
    final imagePath =
        await controller.pickImagePath(source: ImageSource.camera);

    if (imagePath != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrProcessingScreen(
            imagePath: imagePath,
            documentTitle:
                'Foto Dokumen ${AccessibilityUtils.formatFriendlyDate(DateTime.now())}',
            fileInfo: 'Citra Kamera Gawai • Mode Jernih',
          ),
        ),
      );
    } else if (imagePath == null && context.mounted) {
      // Jika kamera fisik tidak tersedia atau batal, sediakan demo OCR langsung
      final choice = await UploadSourceDialog.show(context);
      if (choice == UploadSourceChoice.gallery && context.mounted) {
        final galleryPath =
            await controller.pickImagePath(source: ImageSource.gallery);
        if (galleryPath != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OcrProcessingScreen(
                imagePath: galleryPath,
                documentTitle:
                    'Dokumen Galeri ${AccessibilityUtils.formatFriendlyDate(DateTime.now())}',
                fileInfo: 'Citra Galeri • Resolusi Optimal',
              ),
            ),
          );
        }
      }
    }
  }

  /// 2. Aksi Unggah Dokumen: PDF / Citra Galeri
  Future<void> _uploadDocument(BuildContext context) async {
    final controller = ref.read(homeControllerProvider.notifier);
    final choice = await UploadSourceDialog.show(context);
    if (choice == null || !context.mounted) return;

    if (choice == UploadSourceChoice.gallery) {
      final imagePath =
          await controller.pickImagePath(source: ImageSource.gallery);
      if (imagePath != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OcrProcessingScreen(
              imagePath: imagePath,
              documentTitle:
                  'Dokumen Unggah ${AccessibilityUtils.formatFriendlyDate(DateTime.now())}',
              fileInfo: 'Format Gambar / Dokumen Galeri',
            ),
          ),
        );
      }
    } else {
      final doc = await controller.pickFromFileOrGallery();
      if (doc != null && context.mounted) {
        _openReader(context, doc);
      }
    }
  }

  /// 3. Aksi Tempel Teks Manual
  void _pasteTextManual(BuildContext context) {
    final controller = ref.read(homeControllerProvider.notifier);
    ManualTextInputSheet.show(
      context,
      onSubmit: (title, content) async {
        final doc = await controller.addManualText(title, content);
        if (context.mounted) {
          _openReader(context, doc);
        }
      },
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
    final filteredHistory = _filterDocuments(state.history);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8EE), // Latar anti-silau BacaTenang
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanWithCamera(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.camera_alt_rounded, size: 22),
        label: Text(
          'Pindai Kamera',
          style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.5),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAF7EF),
          border: Border(
            top: BorderSide(color: Color(0xFFDFD7C4), width: 1.2),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          onTap: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
            if (index == 2 || index == 3) {
              _openAppearanceSettings(context);
            }
          },
          backgroundColor: const Color(0xFFFAF7EF),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF78716C),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_rounded),
              label: 'Koleksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volume_up_rounded),
              label: 'Suara',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // HEADER ATAS: Brand "BacaTenang" & Ikon Pengaturan Tampilan
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.space20,
                      right: AppDimens.space20,
                      top: AppDimens.space14,
                      bottom: AppDimens.space8,
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
                                  'BacaTenang',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: const Color(0xFF1E242B),
                                    letterSpacing: 0.5,
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

                        Row(
                          children: [
                            // Tombol Kalibrasi Aksesibilitas
                            IconButton(
                              icon: const Icon(
                                Icons.auto_fix_high_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Kalibrasi Aksesibilitas',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFECE5D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                  side: const BorderSide(color: Color(0xFFDFD7C4)),
                                ),
                              ),
                              onPressed: () => _openOnboarding(context),
                            ),
                            const SizedBox(width: 8),

                            // Tombol Buka Pengaturan Tampilan Baca (AppearanceSettingsScreen)
                            IconButton(
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 22,
                                color: AppColors.primary,
                              ),
                              tooltip: 'Preferensi Aksesibilitas',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFECE5D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                                  side: const BorderSide(color: Color(0xFFDFD7C4)),
                                ),
                              ),
                              onPressed: () => _openAppearanceSettings(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // SAMBUTAN KHAS: "Halo, Cak Faruq 👋"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space20,
                      vertical: AppDimens.space10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, Cak Faruq 👋',
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: const Color(0xFF1E242B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Siap melanjutkan perjalanan membaca yang tenang dan menyenangkan hari ini?',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF4A5568),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3 KARTU INPUT DOKUMEN BESAR (Fungsi Nyata 100%)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: AppDimens.space8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Pindai Kamera
                      ActionCard(
                        title: 'Pindai Kamera',
                        subtitle: 'Pindai teks fisik langsung menggunakan kamera gawai',
                        badgeText: 'Kamera OCR',
                        icon: Icons.camera_alt_rounded,
                        backgroundColor: AppColors.actionCameraBg,
                        borderColor: AppColors.actionCameraBorder,
                        iconColor: AppColors.actionCameraIcon,
                        iconBgColor: AppColors.actionCameraIconBg,
                        onTap: () => _scanWithCamera(context),
                      ),
                      const SizedBox(height: AppDimens.space12),

                      // 2. Unggah Dokumen (PDF / Galeri)
                      ActionCard(
                        title: 'Unggah Dokumen',
                        subtitle: 'Buka berkas PDF atau gambar dokumen dari penyimpanan gawai',
                        badgeText: 'PDF & Foto',
                        icon: Icons.folder_open_rounded,
                        backgroundColor: AppColors.actionUploadBg,
                        borderColor: AppColors.actionUploadBorder,
                        iconColor: AppColors.actionUploadIcon,
                        iconBgColor: AppColors.actionUploadIconBg,
                        onTap: () => _uploadDocument(context),
                      ),
                      const SizedBox(height: AppDimens.space12),

                      // 3. Tempel Teks Manual
                      ActionCard(
                        title: 'Tempel Teks',
                        subtitle: 'Salin dan tempelkan teks apa pun untuk langsung dibaca',
                        badgeText: 'Teks Bebas',
                        icon: Icons.content_paste_go_rounded,
                        backgroundColor: AppColors.actionPasteBg,
                        borderColor: AppColors.actionPasteBorder,
                        iconColor: AppColors.actionPasteIcon,
                        iconBgColor: AppColors.actionPasteIconBg,
                        onTap: () => _pasteTextManual(context),
                      ),
                    ]),
                  ),
                ),

                // KARTU "LANJUTKAN MEMBACA" (Sesuai screen_3.png)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space20,
                      vertical: AppDimens.space12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.space16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7EF),
                        borderRadius: BorderRadius.circular(AppDimens.radiusL),
                        border: Border.all(
                          color: const Color(0xFFDFD7C4),
                          width: 1.5,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF5FB),
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusS),
                                  border: Border.all(
                                    color: const Color(0xFFBFDDF0),
                                  ),
                                ),
                                child: Text(
                                  'Buku Referensi Akademik',
                                  style: AppTextStyles.badge.copyWith(
                                    color: const Color(0xFF1D4ED8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '65% Selesai',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.space10),
                          Text(
                            _continueReadingDoc.title,
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _continueReadingDoc.snippet,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppDimens.space12),

                          // Progress Bar 65%
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 7,
                              backgroundColor: Color(0xFFE2DDD1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimens.space14),

                          // Tombol Aksi Biru "▶ Lanjut Baca"
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _openReader(context, _continueReadingDoc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusM),
                                ),
                                elevation: 1,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: Text(
                                '▶ Lanjut Baca',
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // SECTION TITLE: RIWAYAT DOKUMEN DENGAN TOMBOL "LIHAT SEMUA >"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.space20,
                      right: AppDimens.space20,
                      top: AppDimens.space14,
                      bottom: AppDimens.space8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat Dokumen',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: const Color(0xFF1E242B),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Row(
                            children: const [
                              Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // DAFTAR RIWAYAT DOKUMEN
                if (filteredHistory.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space20,
                        vertical: AppDimens.space12,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.space20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7EF),
                          borderRadius: BorderRadius.circular(AppDimens.radiusL),
                          border: Border.all(color: const Color(0xFFDFD7C4)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppDimens.space10),
                            Text(
                              'Belum Ada Dokumen Tambahan',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pindai kamera atau tempel teks untuk menambah bacaan baru.',
                              style: AppTextStyles.bodySmall,
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
                              bottom: AppDimens.space12,
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

                const SliverToBoxAdapter(
                  child: SizedBox(height: 90.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
