import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status pembacaan Text-to-Speech
enum TtsPlaybackState { stopped, playing, paused }

/// Model profil suara alami (Human-Like Voice Profile)
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

/// Model data untuk penyorotan kata yang sedang dibacakan secara real-time
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

/// Layanan Text-to-Speech (TTS) Multi-Voice yang dioptimalkan untuk bahasa Indonesia ('id-ID')
/// dengan profil suara alami (Bima, Dian, Laras, Default Sistem) dan penyorotan kata real-time.
class TtsService {
  static const String _voicePrefKey = 'lexiread_selected_voice_profile';

  final FlutterTts _flutterTts = FlutterTts();
  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  double _speechRate = 0.85;
  double _pitch = 1.0;
  String _currentText = '';
  int _lastPausedCharIndex = 0;
  String _selectedProfileName = 'Bima - Pria Tenang';

  // Daftar 4 profil suara alami bawaan
  List<TtsVoiceProfile> _voiceProfiles = [
    const TtsVoiceProfile(
      id: 'bima',
      name: 'Bima - Pria Tenang',
      description: 'Suara pria tenang, vokal hangat, tempo relaksasi membaca',
      pitch: 0.95,
      speechRate: 0.85,
      gender: 'Pria',
    ),
    const TtsVoiceProfile(
      id: 'dian',
      name: 'Dian - Wanita Alami',
      description: 'Suara wanita natural, artikulasi jernih, intonasi ramah',
      pitch: 1.0,
      speechRate: 0.90,
      gender: 'Wanita',
    ),
    const TtsVoiceProfile(
      id: 'laras',
      name: 'Laras - Cepat & Artikulatif',
      description: 'Suara wanita cerah, tempo tangkas, fokus efisiensi baca',
      pitch: 1.05,
      speechRate: 1.05,
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

  Future<void> initialize() async {
    try {
      // 1. Atur bahasa default ke Indonesia ('id-ID')
      try {
        await _flutterTts.setLanguage('id-ID');
      } catch (_) {
        try {
          await _flutterTts.setLanguage('id');
        } catch (_) {}
      }

      // 2. Deteksi voice engine bawaan sistem dan filter bahasa Indonesia
      try {
        final dynamic rawVoices = await _flutterTts.getVoices;
        if (rawVoices is List) {
          final indonesianVoices = <Map<String, String>>[];
          for (final item in rawVoices) {
            if (item is Map) {
              final locale = (item['locale'] ?? item['language'] ?? '').toString();
              if (locale.toLowerCase().contains('id')) {
                indonesianVoices.add({
                  'name': item['name']?.toString() ?? '',
                  'locale': locale,
                });
              }
            }
          }

          // Pasangkan ke profil jika suara native id-ID tersedia
          if (indonesianVoices.isNotEmpty) {
            final maleVoice = indonesianVoices.firstWhere(
              (v) => v['name']!.toLowerCase().contains('male') ||
                  v['name']!.toLowerCase().contains('bima'),
              orElse: () => indonesianVoices.first,
            );
            final femaleVoice = indonesianVoices.firstWhere(
              (v) => v['name']!.toLowerCase().contains('female') ||
                  v['name']!.toLowerCase().contains('dian'),
              orElse: () => indonesianVoices.last,
            );

            _voiceProfiles = [
              _voiceProfiles[0].copyWith(nativeVoice: maleVoice),
              _voiceProfiles[1].copyWith(nativeVoice: femaleVoice),
              _voiceProfiles[2].copyWith(nativeVoice: femaleVoice),
              _voiceProfiles[3],
            ];
          }
        }
      } catch (_) {}

      // 3. Muat preferensi profil suara yang tersimpan
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedProfile = prefs.getString(_voicePrefKey);
        if (savedProfile != null && savedProfile.isNotEmpty) {
          _selectedProfileName = savedProfile;
        }
      } catch (_) {}

      // Terapkan profil aktif
      await applyVoiceProfile(_selectedProfileName, saveToPrefs: false);

      // 4. Handler Siklus Pemutaran Audio
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

      // 5. Handler Sinkronisasi Kata Real-Time (Read-Along)
      _flutterTts.setProgressHandler((text, start, end, word) {
        _receivedNativeProgress = true;
        _stopFallbackTicker();

        final snippetBefore = _currentText.substring(
          0,
          start.clamp(0, _currentText.length),
        );
        final wordIndex = RegExp(r'\S+').allMatches(snippetBefore).length;

        _lastPausedCharIndex = start;
        if (!_highlightController.isClosed) {
          _highlightController.add(TtsWordHighlight(
            charStart: start,
            charEnd: end,
            word: word,
            wordIndex: wordIndex,
          ));
        }
      });
    } catch (_) {}
  }

  /// Terapkan profil suara alami (Pitch, Speech Rate, Voice ID)
  Future<void> applyVoiceProfile(String profileName, {bool saveToPrefs = true}) async {
    final profile = _voiceProfiles.firstWhere(
      (p) => p.name.toLowerCase() == profileName.toLowerCase() ||
          p.id.toLowerCase() == profileName.toLowerCase(),
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
  }

  /// Putar sampel suara pendek untuk uji dengar di pengaturan
  Future<void> testVoice(String profileName) async {
    await applyVoiceProfile(profileName, saveToPrefs: false);
    const sampleText =
        'Halo, Cak Faruq. Ini adalah contoh suara pembacaan yang tenang dan ramah disleksia.';
    await speak(sampleText);
  }

  /// Memulai atau melanjutkan pembacaan teks
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

  /// Menjeda pembacaan
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

  /// Menghentikan pembacaan dan menghapus sorotan kata
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

  /// Melompat mundur atau maju sejauh sejumlah karakter atau kata
  Future<void> jumpOffset(int charDelta) async {
    if (_currentText.isEmpty) return;
    final newOffset =
        (_lastPausedCharIndex + charDelta).clamp(0, _currentText.length - 1);
    await stop();
    await speak(_currentText, fromCharIndex: newOffset);
  }

  /// Fallback ticker sinkronisasi kata jika mesin platform tidak memicu onProgress
  void _startFallbackTicker(String textChunk, {int baseOffset = 0}) {
    _stopFallbackTicker();

    final wordMatches = RegExp(r'\S+').allMatches(textChunk).toList();
    if (wordMatches.isEmpty) return;

    int currentMatchIndex = 0;
    final intervalMs = (160 / _speechRate).round().clamp(150, 600);

    Timer(const Duration(milliseconds: 350), () {
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
