import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/reader_settings.dart';

class SettingsRepository {
  static const String _key = 'lexiread_reader_settings';
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  ReaderSettings loadSettings() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return const ReaderSettings();
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return ReaderSettings.fromMap(map);
    } catch (_) {
      return const ReaderSettings();
    }
  }

  Future<void> saveSettings(ReaderSettings settings) async {
    await _prefs.setString(_key, json.encode(settings.toMap()));
  }
}

