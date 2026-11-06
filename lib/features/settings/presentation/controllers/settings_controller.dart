import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/settings_repository.dart';
import '../../domain/reader_settings.dart';

/// Provider SharedPreferences instance (di-override di main.dart saat bootstrap)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

class SettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() {
    final repository = ref.watch(settingsRepositoryProvider);
    return repository.loadSettings();
  }

  Future<void> updateFontFamily(ReaderFontFamily font) async {
    state = state.copyWith(fontFamily: font);
    await _save();
  }

  Future<void> updateFontSize(double newSize) async {
    state = state.copyWith(fontSize: newSize.clamp(14.0, 28.0));
    await _save();
  }

  Future<void> updateLineSpacing(double newSpacing) async {
    state = state.copyWith(lineSpacing: newSpacing.clamp(1.4, 2.6));
    await _save();
  }

  Future<void> updateLetterSpacing(double newSpacing) async {
    state = state.copyWith(letterSpacing: newSpacing.clamp(0.0, 2.5));
    await _save();
  }

  Future<void> updateWordSpacing(double newSpacing) async {
    state = state.copyWith(wordSpacing: newSpacing.clamp(1.0, 3.5));
    await _save();
  }

  Future<void> updatePitch(double newPitch) async {
    state = state.copyWith(pitch: newPitch.clamp(0.5, 1.5));
    await _save();
  }

  Future<void> updateInterWordPause(int pauseMs) async {
    state = state.copyWith(interWordPauseMs: pauseMs.clamp(100, 800));
    await _save();
  }

  Future<void> togglePhonicSyllableColoring(bool enabled) async {
    state = state.copyWith(phonicSyllableColoring: enabled);
    await _save();
  }

  Future<void> toggleLineShading(bool enabled) async {
    state = state.copyWith(enableLineShading: enabled);
    await _save();
  }

  Future<void> updateColorTheme(ReaderColorTheme theme) async {
    state = state.copyWith(colorTheme: theme);
    await _save();
  }

  Future<void> updateSpeechRate(double newRate) async {
    state = state.copyWith(speechRate: newRate.clamp(0.3, 1.5));
    await _save();
  }

  Future<void> toggleReadingRuler(bool enabled) async {
    state = state.copyWith(showReadingRuler: enabled);
    await _save();
  }

  Future<void> resetToDefaults() async {
    state = const ReaderSettings();
    await _save();
  }

  Future<void> _save() async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveSettings(state);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsNotifier, ReaderSettings>(SettingsNotifier.new);
