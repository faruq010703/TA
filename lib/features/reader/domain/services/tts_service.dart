import 'dart:async';
import 'dart:io';
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
    double? pitch,
    double? speechRate,
    String? description,
  }) {
    return TtsVoiceProfile(
      id: id,
      name: name,
      description: description ?? this.description,
      pitch: pitch ?? this.pitch,
      speechRate: speechRate ?? this.speechRate,
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

/// Layanan Text-to-Speech (TTS) Multiplatform (Windows Desktop & Android HP)
/// Dioptimalkan untuk Bahasa Indonesia ('id-ID') dengan penanganan khusus:
/// - Windows: Penyesuaian pitch & rate SAPI (Bima: 0.75/0.45, Dian: 1.40/0.50, Laras: 1.60/0.60)
/// - Android: Voice Engine Google TTS + Voice ID pria/wanita + pitch 0.95 / 1.05 / 1.15
/// - Fallback ticker otomatis untuk platform desktop jika onProgress tidak ditembakkan
class TtsService {
  static const String _voicePrefKey = 'lexiread_selected_voice_profile';

  final FlutterTts _flutterTts = FlutterTts();
  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  late double _speechRate;
  late double _pitch;
  String _currentText = '';
  int _lastPausedCharIndex = 0;
  String _selectedProfileName = 'Bima - Pria Tenang';

  late List<TtsVoiceProfile> _voiceProfiles;

  final _stateController = StreamController<TtsPlaybackState>.broadcast();
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  final _highlightController = StreamController<TtsWordHighlight>.broadcast();
  Stream<TtsWordHighlight> get highlightStream => _highlightController.stream;

  Timer? _fallbackTicker;
  bool _receivedNativeProgress = false;

  TtsService() {
    _voiceProfiles = _getInitialVoiceProfiles();
    _pitch = getPlatformPitch('bima');
    _speechRate = getPlatformSpeechRate('bima');
  }

  TtsPlaybackState get playbackState => _playbackState;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String get currentText => _currentText;
  int get lastPausedCharIndex => _lastPausedCharIndex;
  List<TtsVoiceProfile> get voiceProfiles => _voiceProfiles;
  String get selectedProfileName => _selectedProfileName;

  /// Daftar profil suara bawaan yang disesuaikan secara dinamis dengan platform OS
  List<TtsVoiceProfile> _getInitialVoiceProfiles() {
    final isWindows = !kIsWeb && Platform.isWindows;
    return [
      TtsVoiceProfile(
        id: 'bima',
        name: 'Bima - Pria Tenang',
        description: isWindows
            ? 'Suara pria berbobot & tenang (Windows SAPI pitch 0.75, rate 0.45)'
            : 'Suara pria tenang, vokal hangat, artikulasi berbobot',
        pitch: isWindows ? 0.75 : 0.95,
        speechRate: isWindows ? 0.45 : 0.88,
        gender: 'Pria',
      ),
      TtsVoiceProfile(
        id: 'dian',
        name: 'Dian - Wanita Alami',
        description: isWindows
            ? 'Suara wanita natural & ramah (Windows SAPI pitch 1.40, rate 0.50)'
            : 'Suara wanita natural, artikulasi jernih dan ramah',
        pitch: isWindows ? 1.40 : 1.05,
        speechRate: isWindows ? 0.50 : 0.90,
        gender: 'Wanita',
      ),
      TtsVoiceProfile(
        id: 'laras',
        name: 'Laras - Cepat & Artikulatif',
        description: isWindows
            ? 'Suara wanita nyaring & dinamis (Windows SAPI pitch 1.60, rate 0.60)'
            : 'Suara wanita jelas, tempo dinamis, artikulasi fokus',
        pitch: isWindows ? 1.60 : 1.15,
        speechRate: isWindows ? 0.60 : 1.00,
        gender: 'Wanita',
      ),
      TtsVoiceProfile(
        id: 'system',
        name: 'Default Sistem',
        description: 'Profil netral engine bawaan gawai',
        pitch: 1.0,
        speechRate: isWindows ? 0.50 : 0.95,
        gender: 'Netral',
      ),
    ];
  }

  /// Menentukan nilai pitch spesifik per platform (Windows SAPI vs Android/iOS)
  double getPlatformPitch(String profileId) {
    if (kIsWeb) return 1.0;
    if (Platform.isWindows) {
      switch (profileId.toLowerCase()) {
        case 'bima':
          return 0.75; // Pitch rendah/berat khas pria di Windows SAPI
        case 'dian':
          return 1.40; // Pitch tinggi khas wanita natural di Windows SAPI
        case 'laras':
          return 1.60; // Pitch lebih tinggi dan nyaring di Windows SAPI
        default:
          return 1.0;
      }
    } else {
      switch (profileId.toLowerCase()) {
        case 'bima':
          return 0.95;
        case 'dian':
          return 1.05;
        case 'laras':
          return 1.15;
        default:
          return 1.0;
      }
    }
  }

  /// Menentukan nilai speech rate spesifik per platform (Windows SAPI vs Android/iOS)
  double getPlatformSpeechRate(String profileId) {
    if (kIsWeb) return 0.9;
    if (Platform.isWindows) {
      switch (profileId.toLowerCase()) {
        case 'bima':
          return 0.45; // Tempo santai & nyaman skala Windows
        case 'dian':
          return 0.50;
        case 'laras':
          return 0.60; // Tempo lebih tangkas skala Windows
        default:
          return 0.50;
      }
    } else {
      switch (profileId.toLowerCase()) {
        case 'bima':
          return 0.88;
        case 'dian':
          return 0.90;
        case 'laras':
          return 1.00;
        default:
          return 0.95;
      }
    }
  }

  /// Skor kualitas suara untuk memprioritaskan paket suara Neural / WaveNet / High-Quality
  int _scoreVoice(String name, String? networkQuality) {
    int score = 0;
    final lower = name.toLowerCase();
    if (lower.contains('natural') ||
        lower.contains('network') ||
        lower.contains('wavenet') ||
        lower.contains('neural') ||
        (networkQuality != null && networkQuality.contains('high'))) {
      score += 50;
    }
    if (lower.contains('dfz') || lower.contains('ide') || lower.contains('sul')) {
      score += 20; // Paket suara Google TTS id-ID standar berkualitas tinggi
    }
    if (lower.contains('ardi') || lower.contains('gadis') || lower.contains('andika')) {
      score += 40; // Suara Microsoft Edge / Windows Natural Voice id-ID
    }
    return score;
  }

  Future<void> initialize() async {
    try {
      final isAndroid = !kIsWeb && Platform.isAndroid;

      // 1. Pada Android, prioritaskan Voice Engine bawaan Google TTS ('com.google.android.tts')
      if (isAndroid) {
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
      }

      // 2. Tetapkan bahasa Indonesia ('id-ID' atau 'id')
      try {
        await _flutterTts.setLanguage('id-ID');
      } catch (_) {
        try {
          await _flutterTts.setLanguage('id');
        } catch (_) {}
      }

      // 3. Deteksi seluruh variasi suara Bahasa Indonesia & prioritaskan varian pria/wanita
      try {
        final dynamic rawVoices = await _flutterTts.getVoices;
        if (rawVoices is List) {
          final idVoices = <Map<String, String>>[];
          for (final item in rawVoices) {
            if (item is Map) {
              final locale =
                  (item['locale'] ?? item['language'] ?? '').toString();
              final name = (item['name'] ?? '').toString();
              if (locale.toLowerCase().contains('id') ||
                  name.toLowerCase().contains('indonesia') ||
                  name.toLowerCase().contains('andika') ||
                  name.toLowerCase().contains('ardi') ||
                  name.toLowerCase().contains('gadis')) {
                idVoices.add({
                  'name': name,
                  'locale': locale,
                  'gender': item['gender']?.toString() ?? '',
                  'quality': item['quality']?.toString() ?? '',
                });
              }
            }
          }

          if (idVoices.isNotEmpty) {
            // Urutkan suara dengan kualitas terbaik paling atas
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
                  n.contains('bima') ||
                  n.contains('ardi') ||
                  n.contains('andika');
            }).toList();

            final femaleVoices = idVoices.where((v) {
              final n = (v['name'] ?? '').toLowerCase();
              final g = (v['gender'] ?? '').toLowerCase();
              return g.contains('female') ||
                  n.contains('female') ||
                  n.contains('#female') ||
                  n.contains('dian') ||
                  n.contains('laras') ||
                  n.contains('gadis');
            }).toList();

            final neutralVoices = idVoices
                .where((v) => !maleVoices.contains(v) && !femaleVoices.contains(v))
                .toList();

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

            // Khusus Web / Microsoft Edge Natural Voices
            if (kIsWeb) {
              for (final item in rawVoices) {
                if (item is Map) {
                  final name = (item['name'] ?? '').toString();
                  final locale = (item['locale'] ?? item['language'] ?? '').toString();
                  final isId = locale.toLowerCase().contains('id') ||
                      name.toLowerCase().contains('indonesia');

                  if (isId) {
                    // Pria: nama suara mengandung 'Ardi' atau 'Natural' dengan locale 'id-ID'
                    if (name.contains('Ardi') ||
                        (name.contains('Natural') && locale.contains('id-ID'))) {
                      _voiceProfiles[0] = _voiceProfiles[0].copyWith(
                        nativeVoice: {
                          'name': name,
                          'locale': locale.isNotEmpty ? locale : 'id-ID',
                        },
                      );
                    }
                    // Wanita (Dian & Laras): nama suara mengandung 'Gadis' atau 'Natural' dengan locale 'id-ID'
                    if (name.contains('Gadis') ||
                        (name.contains('Natural') && locale.contains('id-ID'))) {
                      final femaleVoice = {
                        'name': name,
                        'locale': locale.isNotEmpty ? locale : 'id-ID',
                      };
                      _voiceProfiles[1] = _voiceProfiles[1].copyWith(nativeVoice: femaleVoice);
                      _voiceProfiles[2] = _voiceProfiles[2].copyWith(nativeVoice: femaleVoice);
                    }
                  }
                }
              }
            }
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

  /// Mengubah profil suara secara instan dengan parameter akustik adaptif per platform
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
    _pitch = getPlatformPitch(profile.id);
    _speechRate = getPlatformSpeechRate(profile.id);

    try {
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_speechRate);

      await _setNativeVoiceForProfile(profile);
    } catch (e) {
      debugPrint('applyVoiceProfile error: $e');
    }

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

  /// Memasang voice objek native dengan dukungan khusus Microsoft Edge Natural Voices pada Web
  Future<void> _setNativeVoiceForProfile(TtsVoiceProfile profile) async {
    try {
      if (kIsWeb) {
        final dynamic rawVoices = await _flutterTts.getVoices;
        if (rawVoices is List) {
          Map<String, String>? matchedVoice;
          final isMale = profile.gender.toLowerCase() == 'pria';

          for (final item in rawVoices) {
            if (item is Map) {
              final name = (item['name'] ?? '').toString();
              final locale =
                  (item['locale'] ?? item['language'] ?? '').toString();
              final isId = locale.toLowerCase().contains('id') ||
                  name.toLowerCase().contains('indonesia');

              if (isId) {
                if (isMale) {
                  // Pria: nama suara mengandung 'Ardi' atau 'Natural' dengan locale 'id-ID'
                  if (name.contains('Ardi') ||
                      (name.contains('Natural') && locale.contains('id-ID'))) {
                    matchedVoice = {
                      'name': name,
                      'locale': locale.isNotEmpty ? locale : 'id-ID',
                    };
                    break;
                  }
                } else {
                  // Wanita (Dian & Laras): nama suara mengandung 'Gadis' atau 'Natural' dengan locale 'id-ID'
                  if (name.contains('Gadis') ||
                      (name.contains('Natural') && locale.contains('id-ID'))) {
                    matchedVoice = {
                      'name': name,
                      'locale': locale.isNotEmpty ? locale : 'id-ID',
                    };
                    break;
                  }
                }
              }
            }
          }

          if (matchedVoice != null) {
            await _flutterTts.setVoice({
              "name": matchedVoice['name'] ?? '',
              "locale": matchedVoice['locale'] ?? 'id-ID',
            });
            return;
          }
        }
      }

      if (profile.nativeVoice != null) {
        await _flutterTts.setVoice({
          "name": profile.nativeVoice!['name'] ?? '',
          "locale": profile.nativeVoice!['locale'] ?? 'id-ID',
        });
      }
    } catch (e) {
      debugPrint('setVoice notice: $e');
    }
  }

  /// Memutar sampel suara profil secara langsung tanpa ter-override oleh nilai default
  Future<void> speakProfileSample(String profileKey) async {
    final lower = profileKey.toLowerCase();
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
    final targetPitch = getPlatformPitch(profile.id);
    final targetRate = getPlatformSpeechRate(profile.id);

    _pitch = targetPitch;
    _speechRate = targetRate;

    try {
      await _flutterTts.stop();
      await _flutterTts.setPitch(targetPitch);
      await _flutterTts.setSpeechRate(targetRate);

      await _setNativeVoiceForProfile(profile);
    } catch (e) {
      debugPrint('Error applying sample voice: $e');
    }

    const sampleText =
        'Halo, Cak Faruq. Ini adalah contoh suara pembacaan yang tenang dan ramah disleksia.';
    _currentText = sampleText;
    _lastPausedCharIndex = 0;
    _receivedNativeProgress = false;

    _playbackState = TtsPlaybackState.playing;
    if (!_stateController.isClosed) _stateController.add(_playbackState);

    try {
      await _flutterTts.speak(sampleText);
    } catch (_) {}

    _startFallbackTicker(sampleText, baseOffset: 0);
  }

  /// Alias fungsi testVoice yang meneruskan ke speakProfileSample
  Future<void> testVoice(String profileName) async {
    await speakProfileSample(profileName);
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

  /// Mengatur nada suara (pitch: 0.5 - 1.8)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 1.8);
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

  /// Menghitung estimasi durasi pembacaan kata (ms) berdasarkan panjang kata, tanda baca, dan platform
  int _calculateWordDurationMs(String word, double rate, bool isWindows) {
    final cleanLen = word.replaceAll(RegExp(r'[^\w]'), '').length.clamp(2, 16);
    double baseMs = isWindows
        ? (cleanLen * 42.0 + 120.0) / (rate * 1.8)
        : (cleanLen * 30.0 + 100.0) / rate;

    if (word.endsWith('.') || word.endsWith('!') || word.endsWith('?')) {
      baseMs += isWindows ? 280 : 200;
    } else if (word.endsWith(',') || word.endsWith(';') || word.endsWith(':')) {
      baseMs += isWindows ? 150 : 100;
    }

    return baseMs.round().clamp(160, 1200);
  }

  /// Fallback ticker sinkronisasi kata jika mesin platform (khususnya Windows) tidak memicu onProgress
  void _startFallbackTicker(String textChunk, {int baseOffset = 0}) {
    _stopFallbackTicker();

    final wordMatches = RegExp(r'\S+').allMatches(textChunk).toList();
    if (wordMatches.isEmpty) return;

    final isWindows = !kIsWeb && Platform.isWindows;
    final initialDelay = isWindows
        ? const Duration(milliseconds: 60)
        : const Duration(milliseconds: 250);

    Timer(initialDelay, () {
      if (_receivedNativeProgress || _playbackState != TtsPlaybackState.playing) {
        return;
      }
      _scheduleNextWord(wordMatches, 0, baseOffset);
    });
  }

  /// Menjadwalkan pembaruan kata berikutnya secara rekursif dengan durasi dinamis
  void _scheduleNextWord(
    List<RegExpMatch> matches,
    int index,
    int baseOffset,
  ) {
    if (_receivedNativeProgress || _playbackState != TtsPlaybackState.playing) {
      return;
    }

    if (index >= matches.length) {
      _playbackState = TtsPlaybackState.stopped;
      if (!_stateController.isClosed) _stateController.add(_playbackState);
      if (!_highlightController.isClosed) {
        _highlightController.add(TtsWordHighlight.empty);
      }
      return;
    }

    final match = matches[index];
    final globalStart = baseOffset + match.start;
    final globalEnd = baseOffset + match.end;
    final word = match.group(0) ?? '';

    _lastPausedCharIndex = globalStart;
    if (!_highlightController.isClosed) {
      _highlightController.add(TtsWordHighlight(
        charStart: globalStart,
        charEnd: globalEnd,
        word: word,
        wordIndex: index,
      ));
    }

    final isWindows = !kIsWeb && Platform.isWindows;
    final durationMs = _calculateWordDurationMs(word, _speechRate, isWindows);

    _fallbackTicker = Timer(Duration(milliseconds: durationMs), () {
      _scheduleNextWord(matches, index + 1, baseOffset);
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
