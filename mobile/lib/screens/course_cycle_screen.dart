import 'package:flutter/material.dart';

class CourseCycleScreen extends StatelessWidget {
  const CourseCycleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold system representing existing courses/cycles
    final List<Map<String, dynamic>> mockCycles = [
      {
        'title': 'نظام الدورة الأولى - تمريض البالغين السريري',
        'duration': '4 أسابيع',
        'studentsCount': 42,
        'status': 'نشط حالياً',
        'progress': 0.75,
      },
      {
        'title': 'نظام الدورة الثانية - تمريض صحة المجتمع',
        'duration': '6 أسابيع',
        'studentsCount': 35,
        'status': 'قادم',
        'progress': 0.0,
      },
      {
        'title': 'نظام الدورة الثالثة - تمريض الأطفال والولادة السريري',
        'duration': '4 أسابيع',
        'studentsCount': 48,
        'status': 'مكتمل',
        'progress': 1.0,
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'نظام الدورة والكورسات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1a5276),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الدورات والأنظمة التدريبية الحالية في جامعة بغداد',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1a5276)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: mockCycles.length,
                itemBuilder: (context, index) {
                  final cycle = mockCycles[index];
                  final statusColor = cycle['status'] == 'نشط حالياً'
                      ? Colors.green
                      : cycle['status'] == 'قادم'
                          ? Colors.orange
                          : Colors.grey;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cycle['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Chip(
                                label: Text(cycle['status']),
                                backgroundColor: statusColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('المدة الكلية للتدريب: ${cycle['duration']}'),
                          Text('عدد الطلاب الملتحقين بالدورة السريرية: ${cycle['studentsCount']} طالب وطالبة'),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: cycle['progress'],
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xff1a5276),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
