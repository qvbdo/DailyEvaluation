import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorage Tests', () {
    late SharedPreferences prefs;
    late LocalStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = LocalStorage(prefs);
    });

    test('should save and retrieve morning students', () async {
      final List<Map<String, dynamic>> mockStudents = [
        {'name': 'أحمد محمد علي', 'notes': 'ملاحظات الكندي'}
      ];

      await storage.saveStudentsMorning(mockStudents);
      final retrieved = storage.getStudentsMorning();

      expect(retrieved.length, 1);
      expect(retrieved[0]['name'], 'أحمد محمد علي');
    });

    test('should save and retrieve sync queue correctly', () async {
      final List<Map<String, dynamic>> mockQueue = [
        {
          'studentName': 'سارة خالد',
          'totalGrade': 14.5,
          'date': '2025-03-03',
        }
      ];

      await storage.saveSyncQueue(mockQueue);
      final retrieved = storage.getSyncQueue();

      expect(retrieved.length, 1);
      expect(retrieved[0]['studentName'], 'سارة خالد');
      expect(retrieved[0]['totalGrade'], 14.5);
    });
  });
}
