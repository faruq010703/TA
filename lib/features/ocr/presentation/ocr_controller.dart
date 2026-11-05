import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ocr_service.dart';

/// Provider instans OcrService dengan siklus hidup terkelola otomatis.
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

