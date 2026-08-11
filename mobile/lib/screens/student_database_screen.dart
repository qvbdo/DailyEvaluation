import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class StudentDatabaseScreen extends ConsumerStatefulWidget {
  const StudentDatabaseScreen({super.key});

  @override
  ConsumerState<StudentDatabaseScreen> createState() => _StudentDatabaseScreenState();
}

class _StudentDatabaseScreenState extends ConsumerState<StudentDatabaseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _hospitalFilter = '';
  String _groupFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentDb = ref.watch(studentDbProvider);

    // Dynamic unique hospitals and groups list for filters
    final Set<String> hospitals = {};
    final Set<String> groups = {};
    for (final student in studentDb) {
      if (student['hospital'] != null && student['hospital'].isNotEmpty) {
        hospitals.add(student['hospital']);
      }
      if (student['group'] != null && student['group'].isNotEmpty) {
        groups.add(student['group']);
      }
    }

    final filteredDb = studentDb.where((student) {
      final name = (student['name'] ?? '').toString().toLowerCase();
      final hosp = student['hospital'] ?? '';
      final grp = student['group'] ?? '';

      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesHosp = _hospitalFilter.isEmpty || hosp == _hospitalFilter;
      final matchesGrp = _groupFilter.isEmpty || grp == _groupFilter;

      return matchesSearch && matchesHosp && matchesGrp;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'قاعدة بيانات الطلاب',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1a5276),
      ),
      body: Column(
        children: [
          // Database Actions & Import Controls
          Container(
            color: const Color(0xff1a5276).withOpacity(0.05),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدارة السجلات والبيانات',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'إجمالي الطلاب المخزنين: ${studentDb.length}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _importExcelTemplate,
                      icon: const Icon(Icons.file_upload, size: 18),
                      label: const Text('استيراد Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(studentDbProvider.notifier).clearStudentDb();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم مسح قاعدة البيانات بالكامل')),
                        );
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('مسح الكل'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Search Row
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'ابحث بالاسم، المستشفى، أو المجموعة...',
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dropdowns row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _hospitalFilter.isEmpty ? null : _hospitalFilter,
                            decoration: const InputDecoration(
                              labelText: 'المستشفى',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('كل المستشفيات'),
                              ),
                              ...hospitals.map((h) => DropdownMenuItem(value: h, child: Text(h))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _hospitalFilter = val ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _groupFilter.isEmpty ? null : _groupFilter,
                            decoration: const InputDecoration(
                              labelText: 'المجموعة',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('كل المجموعات'),
                              ),
                              ...groups.map((g) => DropdownMenuItem(value: g, child: Text("مجموعة $g"))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _groupFilter = val ?? '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Data table or adaptation List
          Expanded(
            child: filteredDb.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد سجلات مطابقة للبحث أو قاعدة البيانات فارغة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xff1a5276).withOpacity(0.08)),
                        columns: const [
                          DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('نوع الوجبة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المجموعة', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المستشفى المعين', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('المنطقة الكلية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: List.generate(filteredDb.length, (index) {
                          final student = filteredDb[index];
                          return DataRow(cells: [
                            DataCell(Text((index + 1).toString())),
                            DataCell(Text(student['name'] ?? '')),
                            DataCell(Text(student['type'] ?? '')),
                            DataCell(Text(student['group'] ?? '')),
                            DataCell(Text(student['hospital'] ?? '')),
                            DataCell(Text(student['area'] ?? '')),
                            DataCell(Text(student['email'] ?? '')),
                          ]);
                        }),
                      ),
                    ),
                  ),
          ),

          // Action Apply Button
          if (studentDb.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _applyDbToWorkflow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1a5276),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تطبيق قاعدة البيانات وتعميمها على مجموعات العمل اليومي'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _importExcelTemplate() async {
    // Mock parsing and uploading of student rosters via Excel templates
    final mockImportedData = [
      {
        "name": "علي حسين جاسم",
        "type": "صباحي",
        "group": "1",
        "hospital": "مستشفى الكندي",
        "area": "الكرخ",
        "email": "ali@college.edu.iq"
      },
      {
        "name": "ريم سامر نوري",
        "type": "مسائي",
        "group": "4",
        "hospital": "مستشفى ابن سينا",
        "area": "الرصافة",
        "email": "reem@college.edu.iq"
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
        "name": "هدى علاء كامل",
        "type": "صباحي",
        "group": "2",
        "hospital": "مستشفى الجمهوري",
        "area": "الكرخ",
        "email": "huda@college.edu.iq"
      }
    ];

    ref.read(studentDbProvider.notifier).setStudentDb(mockImportedData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استيراد قوالب الطلاب ومحاكاتها بنجاح!')),
    );
  }

  void _applyDbToWorkflow() {
    final studentDb = ref.read(studentDbProvider);
    final morningList = studentDb.where((element) => element['type'] == 'صباحي').toList();
    final eveningList = studentDb.where((element) => element['type'] == 'مسائي').toList();

    ref.read(studentsProvider.notifier).setStudents(morningList);
    // Trigger shift switch and back to ensure caching operates
    ref.read(activeShiftProvider.notifier).state = GroupShift.evening;
    ref.read(studentsProvider.notifier).setStudents(eveningList);
    ref.read(activeShiftProvider.notifier).state = GroupShift.morning;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تطبيق قاعدة البيانات وتعميمها على وجبات العمل اليومي')),
    );
  }
}
