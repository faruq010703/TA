import 'package:flutter/material.dart';
import 'typography_sheet.dart';

/// Adapter kompatibilitas untuk ReaderSettingsSheet yang mengarahkan ke TypographySheet.
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return TypographySheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return const TypographySheet();
  }
}
