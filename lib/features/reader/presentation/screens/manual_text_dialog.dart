import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';

/// Modal dialog / layar input untuk menempelkan atau mengetik teks manual secara nyaman.
class ManualTextInputSheet extends StatefulWidget {
  final Function(String title, String content) onSubmit;

  const ManualTextInputSheet({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String title, String content) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualTextInputSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<ManualTextInputSheet> createState() => _ManualTextInputSheetState();
}

class _ManualTextInputSheetState extends State<ManualTextInputSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      setState(() {
        _contentController.text = clipboardData.text!;
        _errorMessage = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() {
        _errorMessage = AppStrings.errorEmptyText;
      });
      return;
    }

    String title = _titleController.text.trim();
    if (title.isEmpty) {
      // Ambil baris pertama atau 30 karakter pertama sebagai judul default
      final firstLine = content.split('\n').first.trim();
      title = firstLine.length > 36
          ? '${firstLine.substring(0, 36)}...'
          : firstLine;
    }

    Navigator.pop(context);
    widget.onSubmit(title, content);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimens.space20,
            right: AppDimens.space20,
            top: AppDimens.space20,
            bottom: AppDimens.space20 + bottomInset,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indikator Drag Pegangan
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space16),

                // Judul Sheet
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.actionPasteIconBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.actionPasteIcon,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.manualDialogTitle,
                            style: AppTextStyles.headlineSmall,
                          ),
                          Text(
                            AppStrings.manualDialogSubtitle,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space20),

                // Input Judul Opsional
                TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Judul Dokumen (Opsional)',
                    hintText: AppStrings.manualTitleHint,
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: AppDimens.space16),

                // Tombol Akses Cepat Tempel dari Clipboard
                OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded, size: 20),
                  label: const Text(AppStrings.pasteFromClipboard),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.actionPasteIcon,
                    side: const BorderSide(
                      color: AppColors.actionPasteBorder,
                      width: AppDimens.borderWidthStandard,
                    ),
                    backgroundColor: AppColors.actionPasteBg,
                  ),
                ),
                const SizedBox(height: AppDimens.space12),

                // Input Area Teks Besar
                TextField(
                  controller: _contentController,
                  minLines: 6,
                  maxLines: 12,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.manualTextHint,
                    errorText: _errorMessage,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppDimens.space24),

                // Tombol Aksi Mulai Membaca & Batal
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text(AppStrings.btnStartReading),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppStrings.btnCancel,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
