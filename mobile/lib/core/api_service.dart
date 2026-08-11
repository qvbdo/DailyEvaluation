import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = "https://surveys89.firebaseapp.com"});

  /// Simulates fetching student lists from the existing backend.
  /// Ready to be configured with direct HTTP calls.
  Future<List<Map<String, dynamic>>> fetchStudentsRoster() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return [
      {
        "name": "أحمد محمد علي",
        "type": "صباحي",
        "group": "1",
        "hospital": "مستشفى الكندي",
        "area": "الرصافة",
        "email": "ahmed@college.edu.iq"
      },
      {
        "name": "سارة خالد حسن",
        "type": "صباحي",
        "group": "1",
        "hospital": "مستشفى الكندي",
        "area": "الرصافة",
        "email": "sara@college.edu.iq"
      },
      {
        "name": "نور أحمد سعيد",
        "type": "مسائي",
        "group": "2",
        "hospital": "مستشفى الكندي",
        "area": "الرصافة",
        "email": "noor@college.edu.iq"
      },
      {
        "name": "زينب كريم طاهر",
        "type": "صباحي",
        "group": "3",
        "hospital": "مستشفى ابن سينا",
        "area": "الرصافة",
        "email": "zainab@college.edu.iq"
      },
      {
        "name": "ريم سامر نوري",
        "type": "مسائي",
        "group": "4",
        "hospital": "مستشفى ابن سينا",
        "area": "الرصافة",
        "email": "reem@college.edu.iq"
      },
    ];
  }

  /// Sends daily evaluation data to the backend.
  /// Also includes triggering the Google Apps Script integration that emails grades to students.
  Future<bool> submitDailyEvaluation({
    required String studentName,
    required String studentEmail,
    required String date,
    required String groupType,
    required String hospitalName,
    required double totalGrade,
    required String gradesTable,
    required String notes,
    required String gasUrl,
  }) async {
    if (kDebugMode) {
      print("Submitting eval to backend: $studentName, Date: $date, Grade: $totalGrade");
    }

    // Connect to Web App Webhook or Google Apps Script trigger
    if (gasUrl.isNotEmpty) {
      try {
        final payload = {
          "to_email": studentEmail,
          "to_name": studentName,
          "from_name": "مشرف الكلية",
          "hospital_name": hospitalName,
          "group_type": groupType,
          "grades_table": gradesTable,
          "average_grade": totalGrade.toStringAsFixed(2),
          "message": notes.isNotEmpty ? notes : "تقرير تقييمك اليومي في المستشفى.",
          "date": date,
        };

        if (kDebugMode) {
          print("Simulating Apps Script email dispatch: ${jsonEncode(payload)}");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error in Apps Script triggering: $e");
        }
        return false;
      }
    }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network latency
    return true; // Successfully submitted/queued
  }

  /// Simulates syncing the entire offline sync queue once online connection is recovered
  Future<bool> syncPendingQueue(List<Map<String, dynamic>> queuedEvals, String gasUrl) async {
    if (queuedEvals.isEmpty) return true;

    if (kDebugMode) {
      print("Syncing ${queuedEvals.length} evaluations to server...");
    }

    for (final eval in queuedEvals) {
      final success = await submitDailyEvaluation(
        studentName: eval['studentName'] ?? 'طالب',
        studentEmail: eval['studentEmail'] ?? '',
        date: eval['date'] ?? '',
        groupType: eval['groupType'] ?? '',
        hospitalName: eval['hospitalName'] ?? '',
        totalGrade: (eval['totalGrade'] ?? 0.0) as double,
        gradesTable: eval['gradesTable'] ?? '',
        notes: eval['notes'] ?? '',
        gasUrl: gasUrl,
      );
      if (!success) return false;
    }
    return true;
  }
}
