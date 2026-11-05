import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Status status pembacaan Text-to-Speech
enum TtsPlaybackState { stopped, playing, paused }

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

/// Layanan Text-to-Speech (TTS) yang dioptimalkan untuk bahasa Indonesia ('id-ID')
/// dan penyorotan kata real-time (Read-Along) ramah disleksia.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;
  double _speechRate = 0.48; // Kecepatan baca santai (0.3 - 1.0)
  String _currentText = '';
  int _lastPausedCharIndex = 0;

  final _stateController = StreamController<TtsPlaybackState>.broadcast();
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  final _highlightController = StreamController<TtsWordHighlight>.broadcast();
  Stream<TtsWordHighlight> get highlightStream => _highlightController.stream;

  Timer? _fallbackTicker;
  bool _receivedNativeProgress = false;

  TtsPlaybackState get playbackState => _playbackState;
  double get speechRate => _speechRate;
  String get currentText => _currentText;

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

      // 2. Kecepatan bicara (0.3x - 1.0x), volume penuh, nada bicara normal
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // 3. Handler Siklus Pemutaran Audio
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

      // 4. Handler Sinkronisasi Kata Real-Time (Read-Along)
      _flutterTts.setProgressHandler((text, start, end, word) {
        _receivedNativeProgress = true;
        _stopFallbackTicker();

        // Hitung perkiraan indeks kata ke-berapa dalam teks
        final snippetBefore = _currentText.substring(
          0,
          start.clamp(0, _currentText.length),
        );
        final wordIndex = RegExp(r'\S+').allMatches(snippetBefore).length;

        _lastPausedCharIndex = start;
        _highlightController.add(TtsWordHighlight(
          charStart: start,
          charEnd: end,
          word: word,
          wordIndex: wordIndex,
        ));
      });
    } catch (_) {
      // Penanganan aman bila engine TTS belum terpasang di simulator
    }
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
      _stateController.add(_playbackState);

      // Jalankan fallback ticker jika platform tidak mengirimkan event native progress
      _startFallbackTicker(textToSpeak, baseOffset: _lastPausedCharIndex);
    } catch (_) {
      // Jalankan fallback simulasi pembacaan jika native engine offline
      _playbackState = TtsPlaybackState.playing;
      _stateController.add(_playbackState);
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

  /// Mengatur kecepatan membaca (speech rate: 0.3x - 1.0x)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.3, 1.0);
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (_) {}
  }

  /// Fallback ticker sinkronisasi kata jika mesin TTS platform tidak memicu onProgress
  void _startFallbackTicker(String textChunk, {int baseOffset = 0}) {
    _stopFallbackTicker();

    final wordMatches = RegExp(r'\S+').allMatches(textChunk).toList();
    if (wordMatches.isEmpty) return;

    int currentMatchIndex = 0;

    // Rerata durasi membaca satu kata berdasarkan speechRate (0.48x sekitar 320ms per kata)
    final intervalMs = (160 / _speechRate).round().clamp(150, 600);

    // Beri jeda 350ms agar native handler punya kesempatan merespons lebih dulu
    Timer(const Duration(milliseconds: 350), () {
      if (_receivedNativeProgress || _playbackState != TtsPlaybackState.playing) {
        return;
      }

      _fallbackTicker = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        if (_receivedNativeProgress || _playbackState != TtsPlaybackState.playing) {
          timer.cancel();
          return;
        }

        if (currentMatchIndex >= wordMatches.length) {
          timer.cancel();
          _playbackState = TtsPlaybackState.stopped;
          _stateController.add(_playbackState);
          _highlightController.add(TtsWordHighlight.empty);
          return;
        }

        final match = wordMatches[currentMatchIndex];
        final globalStart = baseOffset + match.start;
        final globalEnd = baseOffset + match.end;

        _lastPausedCharIndex = globalStart;
        _highlightController.add(TtsWordHighlight(
          charStart: globalStart,
          charEnd: globalEnd,
          word: match.group(0) ?? '',
          wordIndex: currentMatchIndex,
        ));

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
