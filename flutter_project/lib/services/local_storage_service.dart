import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyPremium = 'app_is_premium';
  static const String _keyTrial = 'app_is_trial';
  static const String _keyLicense = 'app_license_key';
  static const String _keyDevice = 'app_activated_device_id';
  static const String _keyStreak = 'app_streak_count';
  static const String _keyLastActiveDate = 'app_last_active_date';
  static const String _keyFavorites = 'app_favorites_list';
  static const String _keyNotes = 'app_notes_map';
  static const String _keyDarkMode = 'app_is_dark_mode';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Initialize service instance asynchronously
  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Theme Mode Cache ---
  bool isDarkMode() => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool val) => _prefs.setBool(_keyDarkMode, val);

  // --- License State Cache ---
  bool isPremium() => _prefs.getBool(_keyPremium) ?? false;
  Future<void> setPremium(bool val) => _prefs.setBool(_keyPremium, val);

  bool isTrial() => _prefs.getBool(_keyTrial) ?? false;
  Future<void> setTrial(bool val) => _prefs.setBool(_keyTrial, val);

  String? getLicenseKey() => _prefs.getString(_keyLicense);
  Future<void> setLicenseKey(String key) => _prefs.setString(_keyLicense, key);

  String? getActivatedDeviceId() => _prefs.getString(_keyDevice);
  Future<void> setActivatedDeviceId(String id) => _prefs.setString(_keyDevice, id);

  // Remove licensing states if key gets revoked or reset
  Future<void> clearLicense() async {
    await _prefs.remove(_keyPremium);
    await _prefs.remove(_keyTrial);
    await _prefs.remove(_keyLicense);
    await _prefs.remove(_keyDevice);
  }

  // --- Daily Streak System Cache ---
  int getStreakCount() => _prefs.getInt(_keyStreak) ?? 0;
  Future<void> setStreakCount(int count) => _prefs.setInt(_keyStreak, count);

  String? getLastActiveDate() => _prefs.getString(_keyLastActiveDate);
  Future<void> setLastActiveDate(String dateStr) => _prefs.setString(_keyLastActiveDate, dateStr);

  // --- User Saved Data Cache (Favorites & Notes) ---
  List<String> getFavorites() {
    return _prefs.getStringList(_keyFavorites) ?? [];
  }

  Future<void> saveFavorites(List<String> favs) {
    return _prefs.setStringList(_keyFavorites, favs);
  }

  Map<String, String> getNotes() {
    final String? notesJsonRef = _prefs.getString(_keyNotes);
    if (notesJsonRef == null) return {};
    try {
      final decodedMap = json.decode(notesJsonRef) as Map<String, dynamic>;
      return decodedMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveNotes(Map<String, String> notes) {
    final String notesJson = json.encode(notes);
    return _prefs.setString(_keyNotes, notesJson);
  }
}
