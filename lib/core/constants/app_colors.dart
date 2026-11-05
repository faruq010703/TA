import 'package:flutter/material.dart';

/// Palet warna yang dirancang khusus untuk kenyamanan membaca disleksia dewasa.
/// Menghindari kontras hitam-putih murni yang menyilaukan (visual stress / scotopic sensitivity).
class AppColors {
  // Latar belakang utama: Off-white / krem lembut ramah mata (menghindari #FFFFFF murni)
  static const Color background = Color(0xFFFDFBF7);
  static const Color surface = Color(0xFFFAF7F0);
  static const Color surfaceWarm = Color(0xFFF7F3EB);
  static const Color surfaceTinted = Color(0xFFF3EFE6);

  // Teks: Abu gelap arang & abu netral (bukan hitam pekat #000000)
  static const Color textPrimary = Color(0xFF1E242B);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);

  // Aksen utama aplikasi (Biru laut teduh)
  static const Color primary = Color(0xFF2C5E8A);
  static const Color primaryLight = Color(0xFFE8F1F8);
  static const Color primaryDark = Color(0xFF1B3D5A);

  // 3 Kartu Aksi Utama - Warna berkarakter pastel & kontras aman
  // 1. Kartu Kamera (Warm Amber/Peach)
  static const Color actionCameraBg = Color(0xFFFFF5E6);
  static const Color actionCameraBorder = Color(0xFFF8CCA1);
  static const Color actionCameraIcon = Color(0xFFB45309);
  static const Color actionCameraIconBg = Color(0xFFFFE0B2);

  // 2. Kartu Unggah Berkas/Galeri (Sage / Mint Green)
  static const Color actionUploadBg = Color(0xFFEBF7F0);
  static const Color actionUploadBorder = Color(0xFFAFE3C6);
  static const Color actionUploadIcon = Color(0xFF1F6B48);
  static const Color actionUploadIconBg = Color(0xFFC7EBD7);

  // 3. Kartu Tempel Teks (Indigo / Sky Blue)
  static const Color actionPasteBg = Color(0xFFF0F4FF);
  static const Color actionPasteBorder = Color(0xFFBDCEFF);
  static const Color actionPasteIcon = Color(0xFF334CB2);
  static const Color actionPasteIconBg = Color(0xFFD6E2FF);

  // Indikator Progres Baca
  static const Color progressTrack = Color(0xFFE3DFD7);
  static const Color progressFill = Color(0xFF2E7D5B);
  static const Color progressComplete = Color(0xFF1F6B48);

  // Status & Elemen UI
  static const Color border = Color(0xFFE2DDD5);
  static const Color borderStrong = Color(0xFFC5BDB2);
  static const Color shadow = Color(0x14000000);
  static const Color error = Color(0xFFC53030);
  static const Color errorLight = Color(0xFFFED7D7);
  static const Color success = Color(0xFF276749);
}

