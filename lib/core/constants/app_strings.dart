/// Kumpulan teks aplikasi LexiRead dalam bahasa Indonesia yang ringkas, lugas,
/// dan mudah dipahami oleh pembaca disleksia dewasa tanpa istilah teknis membingungkan.
class AppStrings {
  // Nama & Tagline
  static const String appName = 'LexiRead';
  static const String appTagline = 'Pendamping Baca Nyaman untuk Anda';
  static const String greetingMorning = 'Selamat Pagi';
  static const String greetingAfternoon = 'Selamat Siang';
  static const String greetingEvening = 'Selamat Sore';
  static const String greetingNight = 'Selamat Malam';
  static const String headerSubtitle = 'Pilih cara membaca dokumen yang Anda inginkan:';

  // 3 Kartu Aksi Utama
  static const String actionCameraTitle = 'Ambil Foto Dokumen';
  static const String actionCameraSubtitle = 'Pindai buku, surat kabar, atau kertas menggunakan kamera';
  static const String actionCameraBadge = 'Kamera';

  static const String actionUploadTitle = 'Unggah File / Galeri';
  static const String actionUploadSubtitle = 'Buka berkas PDF atau gambar dokumen dari penyimpanan';
  static const String actionUploadBadge = 'PDF & Foto';

  static const String actionPasteTitle = 'Tempel Teks Manual';
  static const String actionPasteSubtitle = 'Salin dan tempelkan teks apa pun untuk langsung dibaca';
  static const String actionPasteBadge = 'Teks Bebas';

  // Bagian Riwayat
  static const String historySectionTitle = 'Riwayat Bacaan Terakhir';
  static const String historyEmptyTitle = 'Belum Ada Bacaan Tersimpan';
  static const String historyEmptySubtitle =
      'Dokumen yang Anda pindai atau tempelkan akan tersimpan di sini secara otomatis.';
  static const String progressLabel = 'Progres Membaca';
  static const String continueReading = 'Lanjutkan Membaca';

  // Dialog & Masukan Manual
  static const String manualDialogTitle = 'Tempelkan Teks';
  static const String manualDialogSubtitle =
      'Ketik atau tempelkan tulisan yang ingin Anda dengar dan baca dengan nyaman.';
  static const String manualTitleHint = 'Judul dokumen (opsional)';
  static const String manualTextHint = 'Ketik atau tempel teks di sini...';
  static const String pasteFromClipboard = 'Tempel dari Clipboard';
  static const String btnStartReading = 'Mulai Membaca';
  static const String btnCancel = 'Batal';

  // Indikator Loading yang Menenangkan
  static const String loadingOcrTitle = 'Sedang Menyiapkan Dokumen';
  static const String loadingOcrSubtitle =
      'Kami sedang membaca teks dari gambar Anda. Mohon tunggu sejenak...';
  static const String loadingFileTitle = 'Membuka Berkas';
  static const String loadingFileSubtitle =
      'Sedang membaca format dokumen Anda...';

  // Pesan Kesalahan / Validasi
  static const String errorEmptyText = 'Harap masukkan teks terlebih dahulu.';
  static const String errorNoTextFound =
      'Tidak ada teks yang terdeteksi pada gambar. Pastikan pencahayaan cukup dan gambar jelas.';
  static const String errorPickFailed =
      'Tidak ada gambar atau berkas yang dipilih.';
  static const String btnClose = 'Tutup';
}

