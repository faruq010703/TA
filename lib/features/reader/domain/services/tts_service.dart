import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Status pembacaan Text-to-Speech
enum TtsPlaybackState { stopped, playing, paused }

/// Layanan Text-to-Speech (TTS) yang dioptimalkan untuk kecepatan dengar ramah disleksia.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsPlaybackState _playbackState = TtsPlaybackState.stopped;

  final _stateController = StreamController<TtsPlaybackState>.broadcast();
  Stream<TtsPlaybackState> get stateStream => _stateController.stream;

  final _wordProgressController = StreamController<int>.broadcast();
  Stream<int> get wordProgressStream => _wordProgressController.stream;

  TtsPlaybackState get playbackState => _playbackState;

  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage('id-ID');
      // Kecepatan membaca disetel lebih santai (0.45 - 0.5) agar pelafalan kata terdengar jelas
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _playbackState = TtsPlaybackState.playing;
        _stateController.add(_playbackState);
      });

      _flutterTts.setCompletionHandler(() {
        _playbackState = TtsPlaybackState.stopped;
        _stateController.add(_playbackState);
      });

      _flutterTts.setCancelHandler(() {
        _playbackState = TtsPlaybackState.stopped;
        _stateController.add(_playbackState);
      });

      _flutterTts.setPauseHandler(() {
        _playbackState = TtsPlaybackState.paused;
        _stateController.add(_playbackState);
      });

      _flutterTts.setProgressHandler((text, start, end, word) {
        _wordProgressController.add(start);
      });
    } catch (_) {
      // Menangani bila TTS belum terpasang pada emulator/platform tertentu
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _flutterTts.speak(text);
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _playbackState = TtsPlaybackState.paused;
    _stateController.add(_playbackState);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _playbackState = TtsPlaybackState.stopped;
    _stateController.add(_playbackState);
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  void dispose() {
    _flutterTts.stop();
    _stateController.close();
    _wordProgressController.close();
  }
}

