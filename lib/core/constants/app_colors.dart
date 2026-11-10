import 'package:flutter/material.dart';

/// Palet warna yang dirancang khusus untuk kenyamanan membaca disleksia dewasa.
/// Menghindari kontras hitam-putih murni yang menyilaukan (visual stress / scotopic sensitivity).
class AppColors {
  // Latar belakang utama: Krem lembut ramah mata (#F4EEDD mencegah visual stress / scotopic sensitivity)
  static const Color background = Color(0xFFF4EEDD);
  static const Color surface = Color(0xFFFAF7EF);
  static const Color surfaceWarm = Color(0xFFECE5D2);
  static const Color surfaceTinted = Color(0xFFE5DDD0);

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

  // Penyorotan Kata Real-Time (Read-Along TTS)
  static const Color highlightWord = Color(0xFFFFF59D); // Kuning pastel lembut ramah disleksia (#FFF59D)
  static const Color highlightWordBorder = Color(0xFFFFE082); // Border kuning pastel (#FFE082)
  static const Color highlightWordText = Color(0xFF1B1F24);

  // Status & Elemen UI
  static const Color border = Color(0xFFDFD7C4);
  static const Color borderStrong = Color(0xFFC5BDB2);
  static const Color shadow = Color(0x14000000);
  static const Color error = Color(0xFFC53030);
  static const Color errorLight = Color(0xFFFED7D7);
  static const Color success = Color(0xFF276749);

  // Tema Warna Aksesibilitas Khusus (Disleksia / Irlen Syndrome)
  static const Color themeCreamBg = Color(0xFFF4EEDD); // Krem lembut ramah visual crowding
  static const Color themeCreamSurface = Color(0xFFFAF7EF);
  static const Color themeCreamShading = Color(0xFFECE5D2);
  static const Color themeCreamBorder = Color(0xFFDFD7C4);

  static const Color themePeachBg = Color(0xFFFEEFE3); // Peach hangat
  static const Color themePeachSurface = Color(0xFFFFF6F0);
  static const Color themePeachShading = Color(0xFFF7DFD0);
  static const Color themePeachBorder = Color(0xFFE8D0BF);
  static const Color themePeachText = Color(0xFF2E2620);

  static const Color themePastelBlueBg = Color(0xFFE8F1F5); // Pastel Blue teduh
  static const Color themePastelBlueSurface = Color(0xFFF2F7FA);
  static const Color themePastelBlueShading = Color(0xFFD6E4EB);
  static const Color themePastelBlueBorder = Color(0xFFCADAE3);
  static const Color themePastelBlueText = Color(0xFF1E252B);

  static const Color themeDarkBg = Color(0xFF1E1E1E); // Dark mode kontras lembut (bukan #000000)
  static const Color themeDarkSurface = Color(0xFF252525);
  static const Color themeDarkShading = Color(0xFF2C2C2C);
  static const Color themeDarkBorder = Color(0xFF383838);
  static const Color themeDarkText = Color(0xFFD4D4D4);

  // Pemenggalan Suku Kata Fonik Berwarna Alternatif
  static const Color phonicPrimary = Color(0xFF2563EB); // Biru fonik
  static const Color phonicSecondary = Color(0xFF7C3AED); // Ungu fonik
  static const Color phonicTertiary = Color(0xFF059669); // Hijau fonik
}

