import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../domain/models/reading_document.dart';

/// Kontrak abstraksi repositori riwayat bacaan.
abstract class IReadingHistoryRepository {
  Future<List<ReadingDocument>> getDocuments();
  Future<void> saveDocument(ReadingDocument document);
  Future<void> updateProgress(String documentId, int currentWordIndex);
  Future<void> deleteDocument(String documentId);
}

/// Implementasi repositori berbasis SharedPreferences lokal.
class ReadingHistoryRepository implements IReadingHistoryRepository {
  static const String _storageKey = 'lexiread_reading_documents_v1';
  final SharedPreferences _prefs;

  ReadingHistoryRepository(this._prefs);

  @override
  Future<List<ReadingDocument>> getDocuments() async {
    final rawJsonList = _prefs.getStringList(_storageKey);
    if (rawJsonList == null) {
      // Sediakan dokumen contoh awal agar tampilan riwayat langsung teruji
      final defaultDocs = _getInitialSampleDocuments();
      await _saveList(defaultDocs);
      return defaultDocs;
    }

    final docs = rawJsonList.map((item) {
      return ReadingDocument.fromMap(json.decode(item) as Map<String, dynamic>);
    }).toList();

    // Urutkan berdasarkan waktu baca terakhir (terbaru di atas)
    docs.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return docs;
  }

  @override
  Future<void> saveDocument(ReadingDocument document) async {
    final currentList = await getDocuments();
    final index = currentList.indexWhere((doc) => doc.id == document.id);

    if (index >= 0) {
      currentList[index] = document;
    } else {
      currentList.insert(0, document);
    }

    await _saveList(currentList);
  }

  @override
  Future<void> updateProgress(String documentId, int currentWordIndex) async {
    final currentList = await getDocuments();
    final index = currentList.indexWhere((doc) => doc.id == documentId);

    if (index >= 0) {
      final doc = currentList[index];
      currentList[index] = doc.copyWith(
        currentWordIndex: currentWordIndex,
        lastReadAt: DateTime.now(),
      );
      await _saveList(currentList);
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    final currentList = await getDocuments();
    currentList.removeWhere((doc) => doc.id == documentId);
    await _saveList(currentList);
  }

  Future<void> _saveList(List<ReadingDocument> docs) async {
    final stringList = docs.map((doc) => json.encode(doc.toMap())).toList();
    await _prefs.setStringList(_storageKey, stringList);
  }

  List<ReadingDocument> _getInitialSampleDocuments() {
    const text1 =
        'Membaca adalah jendela dunia yang terbuka lebar untuk siapa saja. '
        'Bagi pembaca disleksia dewasa, kenyamanan visual seperti jarak baris yang cukup, '
        'huruf yang tidak rapat, dan latar belakang krem lembut sangat membantu mata '
        'fokus pada satu kata tanpa melompat-lompat antar baris. '
        'LexiRead hadir mendampingi perjalanan baca Anda setiap saat.';

    const text2 =
        'Surat edaran ini memberitahukan tentang jadwal pertemuan komunitas '
        'pada hari Sabtu pukul sembilan pagi di ruang serbaguna lantai dua. '
        'Semua peserta diharapkan membawa catatan ringkas dan daftar pertanyaan.';

    final now = DateTime.now();

    return [
      ReadingDocument(
        id: 'sample_doc_1',
        title: 'Mengenal Tipografi Nyaman Membaca',
        content: text1,
        snippet: AccessibilityUtils.createSnippet(text1),
        sourceType: DocumentSourceType.manual,
        createdAt: now.subtract(const Duration(hours: 3)),
        lastReadAt: now.subtract(const Duration(minutes: 45)),
        currentWordIndex: 32,
        totalWords: AccessibilityUtils.countWords(text1),
      ),
      ReadingDocument(
        id: 'sample_doc_2',
        title: 'Surat Edaran Kegiatan Komunitas',
        content: text2,
        snippet: AccessibilityUtils.createSnippet(text2),
        sourceType: DocumentSourceType.camera,
        createdAt: now.subtract(const Duration(days: 1)),
        lastReadAt: now.subtract(const Duration(hours: 12)),
        currentWordIndex: 12,
        totalWords: AccessibilityUtils.countWords(text2),
      ),
    ];
  }
}

