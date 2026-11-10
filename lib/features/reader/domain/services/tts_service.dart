import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status pemutaran Text-to-Speech
enum TtsPlaybackState { stopped, playing, paused }

/// Model profil suara alami manusia (Human-Like Natural Voice Profile)
class TtsVoiceProfile {
  final String id;
  final String name;
  final String description;
  final double pitch;
  final double speechRate;
  final String gender;
  final Map<String, String>? nativeVoice;

  const TtsVoiceProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.pitch,
    required this.speechRate,
    required this.gender,
    this.nativeVoice,
  });

  TtsVoiceProfile copyWith({
    Map<String, String>? nativeVoice,
  }) {
    return TtsVoiceProfile(
      id: id,
      name: name,
      description: description,
      pitch: pitch,
      speechRate: speechRate,
      gender: gender,
      nativeVoice: nativeVoice ?? this.nativeVoice,
    );
  }
}

/// Model data untuk penyorotan kata yang sedang dibacakan secara real-time (Read-Along)
class TtsWordHighlight {
  final int charStart;
  final int charEnd;
  final String word;
  final int wordIndex;

  const TtsWordHighlight({
    required this.charStart,
    required this.charEnd,
    required this.word,
    required this.wordIndex,
  });

  static const empty = TtsWordHighlight(
    charStart: -1,
    charEnd: -1,
    word: '',
    wordIndex: -1,
  );

  bool get isActive => charStart >= 0 && charEnd > charStart;

  @override
  String toString() =>
      'TtsWordHighlight(word: "$word", range: $charStart-$charEnd, index: $wordIndex)';
}

/// Layanan Text-to-Speech (TTS) Multi-Voice Berkualitas Tinggi (Neural / WaveNet)
/// Dioptimalkan untuk Bahasa Indonesia ('id-ID') dengan profil suara alami:
/// - Bima (Pria Tenang): rate 0.88x, pitch 0.95
/// - Dian (Wanita Natural): rate 0.90x, pitch 1.05
/// - Laras (Wanita Jelas): rate 1.00x, pitch 1.15
/// - Default Sistem: rate 0.95x, pitch 1.00
class TtsService {
  static const String _voicePrefKey = 'lexiread_selected_voice_profile';

  final FlutterTts _flutterTts = FlutterTts();
  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  double _speechRate = 0.88;
  double _pitch = 0.95;
  String _currentText = '';
  int _lastPausedCharIndex = 0;
  String _selectedProfileName = 'Bima - Pria Tenang';

  // Daftar 4 profil suara alami bawaan dengan parameter akustik presisi
  List<TtsVoiceProfile> _voiceProfiles = [
    const TtsVoiceProfile(
      id: 'bima',
      name: 'Bima - Pria Tenang',
      description: 'Suara pria tenang, vokal hangat, artikulasi berbobot',
      pitch: 0.95,
      speechRate: 0.88,
      gender: 'Pria',
    ),
    const TtsVoiceProfile(
      id: 'dian',
      name: 'Dian - Wanita Alami',
      description: 'Suara wanita natural, artikulasi jernih dan ramah',
      pitch: 1.05,
      speechRate: 0.90,
      gender: 'Wanita',
    ),
    const TtsVoiceProfile(
      id: 'laras',
      name: 'Laras - Cepat & Artikulatif',
      description: 'Suara wanita jelas, tempo dinamis, artikulasi fokus',
      pitch: 1.15,
      speechRate: 1.00,
      gender: 'Wanita',
    ),
    const TtsVoiceProfile(
      id: 'system',
      name: 'Default Sistem',
      description: 'Profil netral engine bawaan gawai',
      pitch: 1.0,
      speechRate: 0.95,
      gender: 'Netral',
    ),
  ];

  final _stateController = StreamController<TtsPlaybackState>.broadcast();
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  final _highlightController = StreamController<TtsWordHighlight>.broadcast();
  Stream<TtsWordHighlight> get highlightStream => _highlightController.stream;

  Timer? _fallbackTicker;
  bool _receivedNativeProgress = false;

  TtsPlaybackState get playbackState => _playbackState;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get currentText => _currentText;
  int get lastPausedCharIndex => _lastPausedCharIndex;
  List<TtsVoiceProfile> get voiceProfiles => _voiceProfiles;
  String get selectedProfileName => _selectedProfileName;

  /// Skor kualitas suara untuk memprioritaskan paket suara Neural / WaveNet / High-Quality
  int _scoreVoice(String name, String? networkQuality) {
    int score = 0;
    final lower = name.toLowerCase();
    if (lower.contains('network') ||
        lower.contains('wavenet') ||
        lower.contains('neural') ||
        (networkQuality != null && networkQuality.contains('high'))) {
      score += 50;
    }
    if (lower.contains('dfz') || lower.contains('ide') || lower.contains('sul')) {
      score += 20; // Paket suara Google TTS id-ID standar berkualitas tinggi
    }
    return score;
  }

  Future<void> initialize() async {
    try {
      // 1. Prioritaskan Voice Engine bawaan Google TTS ('com.google.android.tts')
      try {
        final dynamic rawEngines = await _flutterTts.getEngines;
        if (rawEngines is List) {
          final googleEngine = rawEngines.firstWhere(
            (e) => e.toString().toLowerCase().contains('com.google.android.tts'),
            orElse: () => null,
          );
          if (googleEngine != null) {
            await _flutterTts.setEngine(googleEngine.toString());
          }
        }
      } catch (e) {
        debugPrint('Engine setting notice: $e');
      }

      // 2. Tetapkan bahasa Indonesia ('id-ID')
      try {
        await _flutterTts.setLanguage('id-ID');
      } catch (_) {
        try {
          await _flutterTts.setLanguage('id');
        } catch (_) {}
      }

      // 3. Deteksi seluruh variasi suara Bahasa Indonesia & prioritaskan Neural / WaveNet
      try {
        final dynamic rawVoices = await _flutterTts.getVoices;
        if (rawVoices is List) {
          final idVoices = <Map<String, String>>[];
          for (final item in rawVoices) {
            if (item is Map) {
              final locale =
                  (item['locale'] ?? item['language'] ?? '').toString();
              if (locale.toLowerCase().contains('id')) {
                idVoices.add({
                  'name': item['name']?.toString() ?? '',
                  'locale': locale,
                  'gender': item['gender']?.toString() ?? '',
                  'quality': item['quality']?.toString() ?? '',
                });
              }
            }
          }

          if (idVoices.isNotEmpty) {
            // Urutkan suara dengan kualitas Neural/WaveNet paling atas
            idVoices.sort((a, b) {
              final scoreA = _scoreVoice(a['name'] ?? '', a['quality']);
              final scoreB = _scoreVoice(b['name'] ?? '', b['quality']);
              return scoreB.compareTo(scoreA);
            });

            // Klasifikasi suara Pria (Male) dan Wanita (Female)
            final maleVoices = idVoices.where((v) {
              final n = (v['name'] ?? '').toLowerCase();
              final g = (v['gender'] ?? '').toLowerCase();
              return (g.contains('male') && !g.contains('female')) ||
                  (n.contains('male') && !n.contains('female')) ||
                  n.contains('#male') ||
                  n.contains('bima');
            }).toList();

            final femaleVoices = idVoices.where((v) {
              final n = (v['name'] ?? '').toLowerCase();
              final g = (v['gender'] ?? '').toLowerCase();
              return g.contains('female') ||
                  n.contains('female') ||
                  n.contains('#female') ||
                  n.contains('dian') ||
                  n.contains('laras');
            }).toList();

            final neutralVoices = idVoices
                .where((v) => !maleVoices.contains(v) && !femaleVoices.contains(v))
                .toList();

            // Pasangkan objek voice native ke masing-masing profil
            final bimaNative = maleVoices.isNotEmpty
                ? maleVoices.first
                : (neutralVoices.isNotEmpty ? neutralVoices.first : idVoices.first);

            final dianNative = femaleVoices.isNotEmpty
                ? femaleVoices.first
                : (neutralVoices.length > 1 ? neutralVoices[1] : idVoices.last);

            final larasNative = femaleVoices.length > 1
                ? femaleVoices[1]
                : (femaleVoices.isNotEmpty
                    ? femaleVoices.first
                    : (neutralVoices.isNotEmpty ? neutralVoices.last : idVoices.first));

            _voiceProfiles = [
              _voiceProfiles[0].copyWith(nativeVoice: bimaNative),
              _voiceProfiles[1].copyWith(nativeVoice: dianNative),
              _voiceProfiles[2].copyWith(nativeVoice: larasNative),
              _voiceProfiles[3],
            ];
          }
        }
      } catch (e) {
        debugPrint('Voice detection notice: $e');
      }

      // 4. Muat preferensi profil suara yang tersimpan
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedProfile = prefs.getString(_voicePrefKey);
        if (savedProfile != null && savedProfile.isNotEmpty) {
          _selectedProfileName = savedProfile;
        }
      } catch (_) {}

      // Terapkan konfigurasi awal profil suara
      await applyVoiceProfile(_selectedProfileName, saveToPrefs: false);

      // 5. Handler Siklus Pemutaran Audio
      _flutterTts.setStartHandler(() {
        _playbackState = TtsPlaybackState.playing;
        if (!_stateController.isClosed) _stateController.add(_playbackState);
      });

      _flutterTts.setCompletionHandler(() {
        _playbackState = TtsPlaybackState.stopped;
        if (!_stateController.isClosed) _stateController.add(_playbackState);
        _stopFallbackTicker();
        if (!_highlightController.isClosed) {
          _highlightController.add(TtsWordHighlight.empty);
        }
        _lastPausedCharIndex = 0;
      });

      _flutterTts.setCancelHandler(() {
        _playbackState = TtsPlaybackState.stopped;
        if (!_stateController.isClosed) _stateController.add(_playbackState);
        _stopFallbackTicker();
        if (!_highlightController.isClosed) {
          _highlightController.add(TtsWordHighlight.empty);
        }
      });

      _flutterTts.setPauseHandler(() {
        _playbackState = TtsPlaybackState.paused;
        if (!_stateController.isClosed) _stateController.add(_playbackState);
        _stopFallbackTicker();
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        _playbackState = TtsPlaybackState.stopped;
        if (!_stateController.isClosed) _stateController.add(_playbackState);
        _stopFallbackTicker();
        if (!_highlightController.isClosed) {
          _highlightController.add(TtsWordHighlight.empty);
        }
      });

      // 6. Handler Penjejak Kata Real-Time (Read-Along Sync)
      _flutterTts.setProgressHandler((text, start, end, word) {
        _receivedNativeProgress = true;
        _stopFallbackTicker();

        // Android flutter_tts memberikan offset start/end relatif terhadap potongan textToSpeak
        final globalStart = (start >= _lastPausedCharIndex && start < _currentText.length)
            ? start
            : (_lastPausedCharIndex + start).clamp(0, _currentText.length);
        final globalEnd = (end > start)
            ? ((start >= _lastPausedCharIndex && end <= _currentText.length)
                ? end
                : (globalStart + (end - start)).clamp(0, _currentText.length))
            : (globalStart + word.length).clamp(0, _currentText.length);

        final snippetBefore = _currentText.substring(
          0,
          globalStart.clamp(0, _currentText.length),
        );
        final wordIndex = RegExp(r'\S+').allMatches(snippetBefore).length;

        _lastPausedCharIndex = globalStart;
        if (!_highlightController.isClosed) {
          _highlightController.add(TtsWordHighlight(
            charStart: globalStart,
            charEnd: globalEnd,
            word: word,
            wordIndex: wordIndex,
          ));
        }
      });
    } catch (e) {
      debugPrint('TtsService initialize error: $e');
    }
  }

  /// Mengubah profil suara secara instan (mengubah objek voice, speech rate, dan pitch)
  /// Jika audio sedang diputar, pembacaan langsung berganti ke suara baru secara instan
  Future<void> applyVoiceProfile(String profileName, {bool saveToPrefs = true}) async {
    final lower = profileName.toLowerCase();
    final profile = _voiceProfiles.firstWhere(
      (p) =>
          p.name.toLowerCase() == lower ||
          p.id.toLowerCase() == lower ||
          (lower.contains('bima') && p.id == 'bima') ||
          (lower.contains('dian') && p.id == 'dian') ||
          (lower.contains('laras') && p.id == 'laras'),
      orElse: () => _voiceProfiles.first,
    );

    _selectedProfileName = profile.name;
    _pitch = profile.pitch;
    _speechRate = profile.speechRate;

    try {
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_speechRate);

      if (profile.nativeVoice != null) {
        await _flutterTts.setVoice(profile.nativeVoice!);
      }
    } catch (_) {}

    if (saveToPrefs) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_voicePrefKey, _selectedProfileName);
      } catch (_) {}
    }

    // Jika sedang memutar suara, beralih langsung ke suara baru dari posisi kata saat ini
    if (_playbackState == TtsPlaybackState.playing && _currentText.isNotEmpty) {
      final resumeIndex = _lastPausedCharIndex;
      await stop();
      await speak(_currentText, fromCharIndex: resumeIndex);
    }
  }

  /// Putar sampel suara pendek untuk preview
  Future<void> testVoice(String profileName) async {
    await applyVoiceProfile(profileName, saveToPrefs: false);
    const sampleText =
        'Halo, Cak Faruq. Ini adalah contoh suara pembacaan yang tenang dan ramah disleksia.';
    await speak(sampleText);
  }

  /// Memulai atau melanjutkan pembacaan teks dari offset karakter tertentu
  Future<void> speak(String text, {int fromCharIndex = 0}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _currentText = text;
    _receivedNativeProgress = false;

    String textToSpeak = text;
    if (fromCharIndex > 0 && fromCharIndex < text.length) {
      textToSpeak = text.substring(fromCharIndex);
      _lastPausedCharIndex = fromCharIndex;
    } else {
      _lastPausedCharIndex = 0;
    }

    try {
      await _flutterTts.speak(textToSpeak);
      _playbackState = TtsPlaybackState.playing;
      if (!_stateController.isClosed) _stateController.add(_playbackState);
      _startFallbackTicker(textToSpeak, baseOffset: _lastPausedCharIndex);
    } catch (_) {
      _playbackState = TtsPlaybackState.playing;
      if (!_stateController.isClosed) _stateController.add(_playbackState);
      _startFallbackTicker(textToSpeak, baseOffset: _lastPausedCharIndex);
    }
  }

  /// Menjeda pembacaan audio
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (_) {}
    _playbackState = TtsPlaybackState.paused;
    if (!_stateController.isClosed) {
      _stateController.add(_playbackState);
    }
    _stopFallbackTicker();
  }

  /// Menghentikan pembacaan audio dan menghapus highlight aktif
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _playbackState = TtsPlaybackState.stopped;
    if (!_stateController.isClosed) {
      _stateController.add(_playbackState);
    }
    _stopFallbackTicker();
    _lastPausedCharIndex = 0;
    if (!_highlightController.isClosed) {
      _highlightController.add(TtsWordHighlight.empty);
    }
  }

  /// Mengatur kecepatan membaca (speech rate: 0.3x - 1.5x)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.3, 1.5);
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (_) {}
  }

  /// Mengatur nada suara (pitch: 0.5 - 1.5)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 1.5);
    try {
      await _flutterTts.setPitch(_pitch);
    } catch (_) {}
  }

  /// Melompat mundur atau maju sejauh delta karakter dan menyesuaikan posisi kata
  Future<void> jumpOffset(int charDelta) async {
    if (_currentText.isEmpty) return;

    int target = (_lastPausedCharIndex + charDelta).clamp(0, _currentText.length);
    if (target > 0 && target < _currentText.length) {
      // Snap ke spasi terdekat agar tidak memotong di tengah kata
      if (charDelta < 0) {
        final space = _currentText.lastIndexOf(RegExp(r'\s'), target);
        if (space != -1) target = space + 1;
      } else {
        final space = _currentText.indexOf(RegExp(r'\s'), target);
        if (space != -1) target = space + 1;
      }
    }
    target = target.clamp(0, _currentText.length);
    _lastPausedCharIndex = target;

    final snippetBefore = _currentText.substring(0, target);
    final wordIndex = RegExp(r'\S+').allMatches(snippetBefore).length;

    if (!_highlightController.isClosed) {
      _highlightController.add(TtsWordHighlight(
        charStart: target,
        charEnd: target + 1,
        word: '',
        wordIndex: wordIndex,
      ));
    }

    if (_playbackState == TtsPlaybackState.playing) {
      await stop();
      await speak(_currentText, fromCharIndex: target);
    }
  }

  /// Fallback ticker sinkronisasi kata jika mesin platform tidak memicu onProgress
  void _startFallbackTicker(String textChunk, {int baseOffset = 0}) {
    _stopFallbackTicker();

    final wordMatches = RegExp(r'\S+').allMatches(textChunk).toList();
    if (wordMatches.isEmpty) return;

    int currentMatchIndex = 0;
    final intervalMs = (160 / _speechRate).round().clamp(150, 600);

    Timer(const Duration(milliseconds: 300), () {
      if (_receivedNativeProgress || _playbackState != TtsPlaybackState.playing) {
        return;
      }

      _fallbackTicker =
          Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        if (_receivedNativeProgress ||
            _playbackState != TtsPlaybackState.playing) {
          timer.cancel();
          return;
        }

        if (currentMatchIndex >= wordMatches.length) {
          timer.cancel();
          _playbackState = TtsPlaybackState.stopped;
          if (!_stateController.isClosed) {
            _stateController.add(_playbackState);
          }
          if (!_highlightController.isClosed) {
            _highlightController.add(TtsWordHighlight.empty);
          }
          return;
        }

        final match = wordMatches[currentMatchIndex];
        final globalStart = baseOffset + match.start;
        final globalEnd = baseOffset + match.end;

        _lastPausedCharIndex = globalStart;
        if (!_highlightController.isClosed) {
          _highlightController.add(TtsWordHighlight(
            charStart: globalStart,
            charEnd: globalEnd,
            word: match.group(0) ?? '',
            wordIndex: currentMatchIndex,
          ));
        }

        currentMatchIndex++;
      });
    });
  }

  void _stopFallbackTicker() {
    _fallbackTicker?.cancel();
    _fallbackTicker = null;
  }

  void dispose() {
    _stopFallbackTicker();
    try {
      _flutterTts.stop();
    } catch (_) {}
    _stateController.close();
    _highlightController.close();
  }
}
