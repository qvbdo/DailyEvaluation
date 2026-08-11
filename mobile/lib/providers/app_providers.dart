import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/local_storage.dart';
import '../core/api_service.dart';
import '../core/auth_service.dart';

// SharedPreferences provider, initialized at app startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError("Initialize SharedPreferences in main");
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current active session date
final activeDateProvider = StateProvider<String>((ref) {
  return DateTime.now().toIso8601String().substring(0, 10);
});

// Current Group Shift (morning / evening)
enum GroupShift { morning, evening }

final activeShiftProvider = StateProvider<GroupShift>((ref) {
  return GroupShift.morning;
});

// Settings State Notifier
class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final LocalStorage _storage;
  SettingsNotifier(this._storage) : super(_storage.getSettings());

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    state = {...state, ...newSettings};
    await _storage.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SettingsNotifier(storage);
});

// Students List state management (filtered based on GroupShift)
class StudentsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final LocalStorage _storage;
  final Ref _ref;

  StudentsNotifier(this._storage, this._ref) : super([]) {
    _loadFromCache();
    // Listen to shift changes to reload list dynamically
    _ref.listen<GroupShift>(activeShiftProvider, (_, __) {
      reload();
    });
  }

  void _loadFromCache() {
    final shift = _ref.read(activeShiftProvider);
    if (shift == GroupShift.morning) {
      state = _storage.getStudentsMorning();
    } else {
      state = _storage.getStudentsEvening();
    }
  }

  Future<void> addStudent(String name) async {
    final student = {
      'name': name,
      'notes': '',
    };
    state = [...state, student];
    await _saveToCache();
  }

  Future<void> deleteStudent(int index) async {
    final list = List<Map<String, dynamic>>.from(state);
    list.removeAt(index);
    state = list;
    await _saveToCache();
  }

  Future<void> setStudents(List<Map<String, dynamic>> list) async {
    state = list;
    await _saveToCache();
  }

  Future<void> _saveToCache() async {
    final shift = _ref.read(activeShiftProvider);
    if (shift == GroupShift.morning) {
      await _storage.saveStudentsMorning(state);
    } else {
      await _storage.saveStudentsEvening(state);
    }
  }

  void reload() {
    _loadFromCache();
  }
}

final studentsProvider = StateNotifierProvider<StudentsNotifier, List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return StudentsNotifier(storage, ref);
});

// Daily Evaluation history notifier: caches grade scores, paper delivered, and attendance
class HistoryNotifier extends StateNotifier<Map<String, dynamic>> {
  final LocalStorage _storage;
  final Ref _ref;

  HistoryNotifier(this._storage, this._ref) : super(_storage.getHistory());

  /// Sets attendance for a student at the active date
  Future<void> setAttendance(int studentIndex, String attendance) async {
    final date = _ref.read(activeDateProvider);
    final shiftStr = _ref.read(activeShiftProvider) == GroupShift.morning ? 'morning' : 'evening';
    final key = "${date}_$shiftStr";

    final updated = Map<String, dynamic>.from(state);
    final dayData = Map<String, dynamic>.from(updated[key] ?? {});
    final studentData = Map<String, dynamic>.from(dayData[studentIndex.toString()] ?? {});

    studentData['attendance'] = attendance;
    if (attendance == 'present') {
      final now = DateTime.now();
      final minStr = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
      studentData['attendanceTime'] = "${now.hour}:$minStr";
    } else {
      studentData.remove('attendanceTime');
    }

    dayData[studentIndex.toString()] = studentData;
    updated[key] = dayData;
    state = updated;
    await _storage.saveHistory(state);
  }

  /// Sets paper delivery status (سلّم الورقة اليومية)
  Future<void> setPaperDelivered(int studentIndex, bool delivered) async {
    final date = _ref.read(activeDateProvider);
    final shiftStr = _ref.read(activeShiftProvider) == GroupShift.morning ? 'morning' : 'evening';
    final key = "${date}_$shiftStr";

    final updated = Map<String, dynamic>.from(state);
    final dayData = Map<String, dynamic>.from(updated[key] ?? {});
    final studentData = Map<String, dynamic>.from(dayData[studentIndex.toString()] ?? {});

    studentData['paperDelivered'] = delivered;
    dayData[studentIndex.toString()] = studentData;
    updated[key] = dayData;
    state = updated;
    await _storage.saveHistory(state);
  }

  /// Sets specific scores for the student's evaluation (total max 15 points)
  Future<void> saveEvaluation({
    required int studentIndex,
    required Map<String, double> scores,
    required double total,
    required String notes,
  }) async {
    final date = _ref.read(activeDateProvider);
    final shiftStr = _ref.read(activeShiftProvider) == GroupShift.morning ? 'morning' : 'evening';
    final key = "${date}_$shiftStr";

    final updated = Map<String, dynamic>.from(state);
    final dayData = Map<String, dynamic>.from(updated[key] ?? {});
    final studentData = Map<String, dynamic>.from(dayData[studentIndex.toString()] ?? {});

    studentData['scores'] = scores;
    studentData['total'] = total;
    studentData['notes'] = notes;
    studentData['evaluated'] = true;

    dayData[studentIndex.toString()] = studentData;
    updated[key] = dayData;
    state = updated;
    await _storage.saveHistory(state);

    // Queue evaluation for API synchronization
    final studentList = _ref.read(studentsProvider);
    if (studentIndex < studentList.length) {
      final student = studentList[studentIndex];
      final settings = _ref.read(settingsProvider);
      final queueItem = {
        'studentName': student['name'],
        'studentEmail': student['email'] ?? '',
        'date': date,
        'groupType': shiftStr == 'morning' ? 'صباحي' : 'مسائي',
        'hospitalName': settings['hospitalName'] ?? '',
        'totalGrade': total,
        'gradesTable': scores.entries.map((e) => "${e.key}: ${e.value}").join('\n'),
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _ref.read(syncQueueProvider.notifier).addToQueue(queueItem);
    }
  }

  Future<void> clearDay() async {
    final date = _ref.read(activeDateProvider);
    final shiftStr = _ref.read(activeShiftProvider) == GroupShift.morning ? 'morning' : 'evening';
    final key = "${date}_$shiftStr";

    final updated = Map<String, dynamic>.from(state);
    updated.remove(key);
    state = updated;
    await _storage.saveHistory(state);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, Map<String, dynamic>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return HistoryNotifier(storage, ref);
});

// Master database providers
class StudentDbNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final LocalStorage _storage;
  StudentDbNotifier(this._storage) : super(_storage.getStudentDb());

  Future<void> setStudentDb(List<Map<String, dynamic>> list) async {
    state = list;
    await _storage.saveStudentDb(state);
  }

  Future<void> clearStudentDb() async {
    state = [];
    await _storage.saveStudentDb([]);
  }
}

final studentDbProvider = StateNotifierProvider<StudentDbNotifier, List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return StudentDbNotifier(storage);
});

// Hospital roster group distribution records
class RosterNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final LocalStorage _storage;
  RosterNotifier(this._storage) : super(_storage.getRoster());

  Future<void> setRoster(List<Map<String, dynamic>> list) async {
    state = list;
    await _storage.saveRoster(state);
  }

  Future<void> clearRoster() async {
    state = [];
    await _storage.saveRoster([]);
  }
}

final rosterProvider = StateNotifierProvider<RosterNotifier, List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return RosterNotifier(storage);
});

// Sync Queue state management
class SyncQueueNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final LocalStorage _storage;
  final Ref _ref;

  SyncQueueNotifier(this._storage, this._ref) : super(_storage.getSyncQueue());

  Future<void> addToQueue(Map<String, dynamic> item) async {
    state = [...state, item];
    await _storage.saveSyncQueue(state);
  }

  Future<void> removeFromQueue(int index) async {
    final list = List<Map<String, dynamic>>.from(state);
    list.removeAt(index);
    state = list;
    await _storage.saveSyncQueue(state);
  }

  Future<void> processSync() async {
    if (state.isEmpty) return;
    final apiService = _ref.read(apiServiceProvider);
    final settings = _ref.read(settingsProvider);
    final gasUrl = settings['gasUrl'] ?? '';

    // Attempt processing
    final success = await apiService.syncPendingQueue(state, gasUrl);
    if (success) {
      state = [];
      await _storage.saveSyncQueue([]);
    }
  }
}

final syncQueueProvider = StateNotifierProvider<SyncQueueNotifier, List<Map<String, dynamic>>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SyncQueueNotifier(storage, ref);
});
