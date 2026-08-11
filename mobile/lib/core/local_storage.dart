import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _keyStudentsMorning = 'hsp_sm';
  static const String _keyStudentsEvening = 'hsp_se';
  static const String _keyHistory = 'hsp_h';
  static const String _keyRoster = 'hsp_r';
  static const String _keyStudentDb = 'hsp_sdb';
  static const String _keySettings = 'hsp_settings';
  static const String _keySyncQueue = 'hsp_q';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // --- Student Lists (Morning / Evening) ---
  Future<void> saveStudentsMorning(List<Map<String, dynamic>> students) async {
    await _prefs.setString(_keyStudentsMorning, jsonEncode(students));
  }

  List<Map<String, dynamic>> getStudentsMorning() {
    final raw = _prefs.getString(_keyStudentsMorning);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStudentsEvening(List<Map<String, dynamic>> students) async {
    await _prefs.setString(_keyStudentsEvening, jsonEncode(students));
  }

  List<Map<String, dynamic>> getStudentsEvening() {
    final raw = _prefs.getString(_keyStudentsEvening);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Daily Evaluation History ---
  // History is a map: date_group_key -> map of student evaluation indices
  Future<void> saveHistory(Map<String, dynamic> history) async {
    await _prefs.setString(_keyHistory, jsonEncode(history));
  }

  Map<String, dynamic> getHistory() {
    final raw = _prefs.getString(_keyHistory);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  // --- Group Distribution & Hospital Roster ---
  Future<void> saveRoster(List<Map<String, dynamic>> roster) async {
    await _prefs.setString(_keyRoster, jsonEncode(roster));
  }

  List<Map<String, dynamic>> getRoster() {
    final raw = _prefs.getString(_keyRoster);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Master Student Database ---
  Future<void> saveStudentDb(List<Map<String, dynamic>> studentDb) async {
    await _prefs.setString(_keyStudentDb, jsonEncode(studentDb));
  }

  List<Map<String, dynamic>> getStudentDb() {
    final raw = _prefs.getString(_keyStudentDb);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Settings ---
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(_keySettings, jsonEncode(settings));
  }

  Map<String, dynamic> getSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  // --- Sync Queue (Offline-First Writes) ---
  Future<void> saveSyncQueue(List<Map<String, dynamic>> queue) async {
    await _prefs.setString(_keySyncQueue, jsonEncode(queue));
  }

  List<Map<String, dynamic>> getSyncQueue() {
    final raw = _prefs.getString(_keySyncQueue);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  // Clean all data (mainly for logouts or test resets)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
