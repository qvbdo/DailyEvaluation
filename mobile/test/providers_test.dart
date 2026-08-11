import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Riverpod Providers Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('should load default empty list of students', () {
      final containerObj = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final students = containerObj.read(studentsProvider);
      expect(students, isEmpty);
    });

    test('should add student and persist correctly', () async {
      final containerObj = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = containerObj.read(studentsProvider.notifier);
      await notifier.addStudent('حيدر علي طه');

      final students = containerObj.read(studentsProvider);
      expect(students.length, 1);
      expect(students[0]['name'], 'حيدر علي طه');
    });
  });
}
