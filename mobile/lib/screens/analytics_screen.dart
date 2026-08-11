import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    final history = ref.watch(historyProvider);
    final activeDate = ref.watch(activeDateProvider);
    final activeShift = ref.watch(activeShiftProvider);

    final shiftStr = activeShift == GroupShift.morning ? 'morning' : 'evening';
    final key = "${activeDate}_$shiftStr";
    final dayData = history[key] ?? {};

    // Analyze attendance rates and grades distribution
    int totalCount = students.length;
    int presentCount = 0;
    int evaluatedCount = 0;
    double cumulativeGrade = 0.0;

    int gradeA = 0; // 12-15
    int gradeB = 0; // 9-11.9
    int gradeC = 0; // 6-8.9
    int gradeF = 0; // < 6

    for (int i = 0; i < totalCount; i++) {
      final studentData = dayData[i.toString()] ?? {};
      if (studentData['attendance'] == 'present') {
        presentCount++;
      }
      if (studentData['evaluated'] == true) {
        evaluatedCount++;
        final double score = (studentData['total'] ?? 0.0) as double;
        cumulativeGrade += score;

        if (score >= 12.0) {
          gradeA++;
        } else if (score >= 9.0) {
          gradeB++;
        } else if (score >= 6.0) {
          gradeC++;
        } else {
          gradeF++;
        }
      }
    }

    final double attendanceRate = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;
    final double averageGrade = evaluatedCount > 0 ? (cumulativeGrade / evaluatedCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم والإحصائيات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1a5276),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                color: const Color(0xff1a5276),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Text(
                        '🎓',
                        style: TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'كلية التمريض - جامعة بغداد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'نظام تقييم التدريب السريري والمستشفيات اليومي لعام 2025/2026',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'مؤشرات الأداء السريري اليومي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1a5276)),
              ),
              const SizedBox(height: 12),

              // KPI Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildKpiCard(
                    context,
                    title: 'نسبة الحضور اليومي',
                    value: "${attendanceRate.toStringAsFixed(1)}%",
                    icon: Icons.people_alt,
                    color: Colors.teal,
                  ),
                  _buildKpiCard(
                    context,
                    title: 'متوسط درجات التقييم',
                    value: "${averageGrade.toStringAsFixed(2)} / 15",
                    icon: Icons.analytics_outlined,
                    color: const Color(0xff1a5276),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'توزيع درجات الطلاب السريرية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1a5276)),
              ),
              const SizedBox(height: 12),

              // Chart showing grades distribution using fl_chart
              if (evaluatedCount == 0)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'قم بتقييم بعض الطلاب لعرض الإحصائيات الحية لتوزيع الدرجات',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: [gradeA, gradeB, gradeC, gradeF]
                                      .reduce((curr, next) => curr > next ? curr : next)
                                      .toDouble() +
                                  2,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      const style = TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      );
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('ممتاز (12-15)', style: style);
                                        case 1:
                                          return const Text('جيد جداً (9-12)', style: style);
                                        case 2:
                                          return const Text('متوسط (6-9)', style: style);
                                        case 3:
                                          return const Text('ضعيف (<6)', style: style);
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                                ),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                        toY: gradeA.toDouble(), color: Colors.green, width: 22)
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                        toY: gradeB.toDouble(), color: Colors.blue, width: 22)
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 2,
                                  barRods: [
                                    BarChartRodData(
                                        toY: gradeC.toDouble(), color: Colors.orange, width: 22)
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 3,
                                  barRods: [
                                    BarChartRodData(
                                        toY: gradeF.toDouble(), color: Colors.red, width: 22)
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'توزيع فئات الطلاب حسب درجات التدريب العملي السريري',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
