import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class DailyEvaluationScreen extends ConsumerStatefulWidget {
  const DailyEvaluationScreen({super.key});

  @override
  ConsumerState<DailyEvaluationScreen> createState() => _DailyEvaluationScreenState();
}

class _DailyEvaluationScreenState extends ConsumerState<DailyEvaluationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeDate = ref.watch(activeDateProvider);
    final activeShift = ref.watch(activeShiftProvider);
    final students = ref.watch(studentsProvider);
    final history = ref.watch(historyProvider);
    final queue = ref.watch(syncQueueProvider);

    final shiftStr = activeShift == GroupShift.morning ? 'morning' : 'evening';
    final key = "${activeDate}_$shiftStr";
    final dayData = history[key] ?? {};

    // Filter student list based on search query
    final filteredStudents = students.where((student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Calc Daily Statistics
    int totalCount = students.length;
    int presentCount = 0;
    int absentCount = 0;
    int evaluatedCount = 0;

    for (int i = 0; i < totalCount; i++) {
      final studentData = dayData[i.toString()] ?? {};
      final att = studentData['attendance'] ?? 'none';
      if (att == 'present') presentCount++;
      if (att == 'absent') absentCount++;
      if (studentData['evaluated'] == true) evaluatedCount++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'العمل اليومي والتقييم',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1a5276),
        actions: [
          // Queue sync action badge
          if (queue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(syncQueueProvider.notifier).processSync();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('جاري مزامنة البيانات السحابية المتراكمة...')),
                  );
                },
                icon: const Icon(Icons.sync_problem, color: Colors.amber),
                label: Text(
                  'مزامنة (${queue.length})',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats Bar
          Container(
            color: const Color(0xff1a5276).withOpacity(0.05),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('إجمالي الطلاب', totalCount.toString(), Colors.blue),
                _buildStatCard('حاضر', presentCount.toString(), Colors.green),
                _buildStatCard('غائب', absentCount.toString(), Colors.red),
                _buildStatCard('تم التقييم', evaluatedCount.toString(), Colors.orange),
              ],
            ),
          ),

          // Date & Shift selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xff1a5276)),
                    const SizedBox(width: 8),
                    Text(
                      activeDate,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(activeDate),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2028),
                        );
                        if (picked != null) {
                          ref.read(activeDateProvider.notifier).state =
                              picked.toIso8601String().substring(0, 10);
                        }
                      },
                    ),
                  ],
                ),
                // Shift toggler
                ToggleButtons(
                  isSelected: [
                    activeShift == GroupShift.morning,
                    activeShift == GroupShift.evening,
                  ],
                  onPressed: (index) {
                    ref.read(activeShiftProvider.notifier).state =
                        index == 0 ? GroupShift.morning : GroupShift.evening;
                  },
                  borderRadius: BorderRadius.circular(20),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 70),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xff1a5276),
                  children: const [
                    Text('صباحي'),
                    Text('مسائي'),
                  ],
                ),
              ],
            ),
          ),

          // Search Box and Adding Students Action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'ابحث عن اسم طالب...',
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showAddStudentDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1a5276),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إضافة طالب'),
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'لا يوجد طلاب مضافين اليوم في هذه الوجبة',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showAddStudentDialog,
                          child: const Text('إضافة أول طالب'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      // Find actual index in original un-filtered list
                      final originalIndex = students.indexOf(student);

                      final studentData = dayData[originalIndex.toString()] ?? {};
                      final att = studentData['attendance'] ?? 'none';
                      final hasPaper = studentData['paperDelivered'] ?? false;
                      final evaluated = studentData['evaluated'] ?? false;
                      final totalScore = studentData['total'] ?? 0.0;

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      student['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Evaluation mark summary or icon
                                  if (evaluated)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff1a5276).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'الدرجة: ${totalScore.toStringAsFixed(2)} / 15',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff1a5276),
                                        ),
                                      ),
                                    )
                                  else
                                    const Text(
                                      'غير مقيّم',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Grid actions (Attendance, Paper submission, detailed evaluation click)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Attendance buttons
                                  Row(
                                    children: [
                                      ChoiceChip(
                                        label: const Text('حاضر'),
                                        selected: att == 'present',
                                        selectedColor: Colors.green.withOpacity(0.2),
                                        labelStyle: TextStyle(
                                          color: att == 'present' ? Colors.green : Colors.black87,
                                          fontWeight: att == 'present'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        onSelected: (selected) {
                                          if (selected) {
                                            ref
                                                .read(historyProvider.notifier)
                                                .setAttendance(originalIndex, 'present');
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: const Text('غائب'),
                                        selected: att == 'absent',
                                        selectedColor: Colors.red.withOpacity(0.2),
                                        labelStyle: TextStyle(
                                          color: att == 'absent' ? Colors.red : Colors.black87,
                                          fontWeight: att == 'absent'
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        onSelected: (selected) {
                                          if (selected) {
                                            ref
                                                .read(historyProvider.notifier)
                                                .setAttendance(originalIndex, 'absent');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  // Actions column
                                  Row(
                                    children: [
                                      // Paper submission toggle (تسليم الورقة اليومية)
                                      IconButton(
                                        icon: Icon(
                                          hasPaper ? Icons.article : Icons.article_outlined,
                                          color: hasPaper ? Colors.blue : Colors.grey,
                                        ),
                                        tooltip: 'تسليم الورقة',
                                        onPressed: () {
                                          ref
                                              .read(historyProvider.notifier)
                                              .setPaperDelivered(originalIndex, !hasPaper);
                                        },
                                      ),
                                      // Detailed Evaluate Button
                                      ElevatedButton.icon(
                                        onPressed: att == 'absent'
                                            ? null
                                            : () => _openEvaluationModal(originalIndex, student['name']),
                                        icon: const Icon(Icons.edit_note, size: 18),
                                        label: const Text('تقييم'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xff1a5276),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      // Remove student button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                        onPressed: () {
                                          ref
                                              .read(studentsProvider.notifier)
                                              .deleteStudent(originalIndex);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة طالب جديد'),
          content: TextField(
            controller: _studentNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'اسم الطالب رباعي',
              hintText: 'أدخل الاسم الكامل...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _studentNameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(studentsProvider.notifier).addStudent(name);
                  _studentNameController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  // Clinical evaluation form modal comprising the 5 structural assessment fields (Max 15 points)
  void _openEvaluationModal(int studentIndex, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final activeDate = ref.read(activeDateProvider);
            final activeShift = ref.read(activeShiftProvider);
            final shiftStr = activeShift == GroupShift.morning ? 'morning' : 'evening';
            final key = "${activeDate}_$shiftStr";
            final historyData = ref.read(historyProvider)[key] ?? {};
            final studentData = historyData[studentIndex.toString()] ?? {};

            final previousScores = studentData['scores'] as Map<String, dynamic>? ?? {};
            final previousNotes = studentData['notes'] as String? ?? '';

            // Fields evaluation controller state variables (Sliders mapped dynamically)
            double dailyNoteScore = (previousScores['dailynote'] ?? 0.0) as double; // Max 5.0
            double groupDiscussionScore = (previousScores['gdisc'] ?? 0.0) as double; // Max 3.5
            double caseDiscussionScore = (previousScores['cdisc'] ?? 0.0) as double; // Max 3.5

            // Checkboxes representing 0.25 grade segments for communication, punctuality and appearance
            bool staffComm = (previousScores['staff'] ?? 0.0) == 0.25;
            bool studentComm = (previousScores['std'] ?? 0.0) == 0.25;
            bool teacherComm = (previousScores['tchr'] ?? 0.0) == 0.25;
            bool patientComm = (previousScores['pat'] ?? 0.0) == 0.25;

            bool latePunc = (previousScores['late'] ?? 0.0) == 0.25;
            bool meetingPunc = (previousScores['meet'] ?? 0.0) == 0.25;
            bool locationPunc = (previousScores['loc'] ?? 0.0) == 0.25;
            bool orderPunc = (previousScores['ord'] ?? 0.0) == 0.25;

            bool badgeAppear = (previousScores['badge'] ?? 0.0) == 0.25;
            bool veilAppear = (previousScores['veil'] ?? 0.0) == 0.25;
            bool uniformAppear = (previousScores['uni'] ?? 0.0) == 0.25;
            bool coatAppear = (previousScores['coat'] ?? 0.0) == 0.25;

            final TextEditingController noteController =
                TextEditingController(text: previousNotes);

            double calculateTotal() {
              double total = 0.0;
              total += dailyNoteScore;
              total += groupDiscussionScore;
              total += caseDiscussionScore;

              total += staffComm ? 0.25 : 0.0;
              total += studentComm ? 0.25 : 0.0;
              total += teacherComm ? 0.25 : 0.0;
              total += patientComm ? 0.25 : 0.0;

              total += latePunc ? 0.25 : 0.0;
              total += meetingPunc ? 0.25 : 0.0;
              total += locationPunc ? 0.25 : 0.0;
              total += orderPunc ? 0.25 : 0.0;

              total += badgeAppear ? 0.25 : 0.0;
              total += veilAppear ? 0.25 : 0.0;
              total += uniformAppear ? 0.25 : 0.0;
              total += coatAppear ? 0.25 : 0.0;

              return total > 15.0 ? 15.0 : total;
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقييم الطالب: $name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    // Section 1: Daily Note (الملاحظة اليومية) - Max 5
                    _buildSectionHeader('1. الملاحظة اليومية (الحد الأقصى: 5.0)'),
                    _buildScoreSlider(
                      value: dailyNoteScore,
                      max: 5.0,
                      divisions: 20,
                      onChanged: (val) {
                        setModalState(() {
                          dailyNoteScore = val;
                        });
                      },
                    ),

                    // Section 2: Discussion (المناقشة والتغذية الراجعة) - Max 7
                    _buildSectionHeader('2. المناقشة والتغذية الراجعة (الحد الأقصى: 7.0)'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          _buildSubScoreSlider(
                            label: 'مناقشة جماعية (Max 3.5)',
                            value: groupDiscussionScore,
                            max: 3.5,
                            onChanged: (val) {
                              setModalState(() {
                                groupDiscussionScore = val;
                              });
                            },
                          ),
                          _buildSubScoreSlider(
                            label: 'مناقشة حالة مرضية (Max 3.5)',
                            value: caseDiscussionScore,
                            max: 3.5,
                            onChanged: (val) {
                              setModalState(() {
                                caseDiscussionScore = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Section 3: Attitude & Comm (الموقف والتواصل) - Max 1 (4 x 0.25)
                    _buildSectionHeader('3. الموقف والتواصل (الحد الأقصى: 1.0)'),
                    _buildGridCheckboxes(setModalState, [
                      _GridCheckItem('الطاقم الطبي', staffComm, (v) => staffComm = v),
                      _GridCheckItem('الطالب نفسه', studentComm, (v) => studentComm = v),
                      _GridCheckItem('المشرف المعلم', teacherComm, (v) => teacherComm = v),
                      _GridCheckItem('المريض وعائلته', patientComm, (v) => patientComm = v),
                    ]),

                    // Section 4: Punctuality (الانتظام) - Max 1 (4 x 0.25)
                    _buildSectionHeader('4. الانتظام والحضور (الحد الأقصى: 1.0)'),
                    _buildGridCheckboxes(setModalState, [
                      _GridCheckItem('عدم التأخير', latePunc, (v) => latePunc = v),
                      _GridCheckItem('حضور الاجتماع', meetingPunc, (v) => meetingPunc = v),
                      _GridCheckItem('التواجد بالموقع', locationPunc, (v) => locationPunc = v),
                      _GridCheckItem('تنفيذ الأوامر', orderPunc, (v) => orderPunc = v),
                    ]),

                    // Section 5: Appearance (المظهر) - Max 1 (4 x 0.25)
                    _buildSectionHeader('5. الهندام والمظهر (الحد الأقصى: 1.0)'),
                    _buildGridCheckboxes(setModalState, [
                      _GridCheckItem('شارة الاسم', badgeAppear, (v) => badgeAppear = v),
                      _GridCheckItem('الحجاب/ترتيب الشعر', veilAppear, (v) => veilAppear = v),
                      _GridCheckItem('الزي الرسمي الكامل', uniformAppear, (v) => uniformAppear = v),
                      _GridCheckItem('المعطف الطبي السليم', coatAppear, (v) => coatAppear = v),
                    ]),

                    const SizedBox(height: 16),
                    // Notes Input
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات يومية تفصيلية...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
                    // Summary Score & Save button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المجموع الكلي: ${calculateTotal().toStringAsFixed(2)} / 15',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final double finalTotal = calculateTotal();
                            final Map<String, double> scores = {
                              'dailynote': dailyNoteScore,
                              'gdisc': groupDiscussionScore,
                              'cdisc': caseDiscussionScore,
                              'staff': staffComm ? 0.25 : 0.0,
                              'std': studentComm ? 0.25 : 0.0,
                              'tchr': teacherComm ? 0.25 : 0.0,
                              'pat': patientComm ? 0.25 : 0.0,
                              'late': latePunc ? 0.25 : 0.0,
                              'meet': meetingPunc ? 0.25 : 0.0,
                              'loc': locationPunc ? 0.25 : 0.0,
                              'ord': orderPunc ? 0.25 : 0.0,
                              'badge': badgeAppear ? 0.25 : 0.0,
                              'veil': veilAppear ? 0.25 : 0.0,
                              'uni': uniformAppear ? 0.25 : 0.0,
                              'coat': coatAppear ? 0.25 : 0.0,
                            };

                            ref.read(historyProvider.notifier).saveEvaluation(
                                  studentIndex: studentIndex,
                                  scores: scores,
                                  total: finalTotal,
                                  notes: noteController.text,
                                );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ التقييم بنجاح!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1a5276),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('حفظ التقييم'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1a5276)),
      ),
    );
  }

  Widget _buildScoreSlider({
    required double value,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSubScoreSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                max: max,
                divisions: 14, // steps of 0.25
                onChanged: onChanged,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCheckboxes(StateSetter setModalState, List<_GridCheckItem> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items.map((item) {
        return FilterChip(
          label: Text("${item.label} (+0.25)"),
          selected: item.value,
          onSelected: (selected) {
            setModalState(() {
              item.onChanged(selected);
            });
          },
        );
      }).toList(),
    );
  }
}

class _GridCheckItem {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  _GridCheckItem(this.label, this.value, this.onChanged);
}
