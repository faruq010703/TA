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

  Future<void> updateFontSize(double newSize) async {
    state = state.copyWith(fontSize: newSize);
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveSettings(state);
  }

  Future<void> updateLineSpacing(double newSpacing) async {
    state = state.copyWith(lineSpacing: newSpacing);
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveSettings(state);
  }

  Future<void> updateSpeechRate(double newRate) async {
    state = state.copyWith(speechRate: newRate);
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveSettings(state);
  }

  Future<void> toggleReadingRuler(bool enabled) async {
    state = state.copyWith(showReadingRuler: enabled);
    final repository = ref.read(settingsRepositoryProvider);
    await repository.saveSettings(state);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsNotifier, ReaderSettings>(SettingsNotifier.new);
