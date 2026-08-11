import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class GroupDistributionScreen extends ConsumerStatefulWidget {
  const GroupDistributionScreen({super.key});

  @override
  ConsumerState<GroupDistributionScreen> createState() => _GroupDistributionScreenState();
}

class _GroupDistributionScreenState extends ConsumerState<GroupDistributionScreen> {
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  String _selectedShift = 'صباحي';

  @override
  void dispose() {
    _hospitalController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(rosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'توزيع المجموعات والمستشفيات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xff1a5276),
      ),
      body: Column(
        children: [
          // Distribution Inputs Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'توزيع وجبات الطلاب (صباحي/مسائي) والمستشفيات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1a5276)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _hospitalController,
                            decoration: const InputDecoration(
                              labelText: 'المستشفى المعين',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _groupController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'رقم المجموعة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نوع وجبة الدوام:'),
                        DropdownButton<String>(
                          value: _selectedShift,
                          items: const [
                            DropdownMenuItem(value: 'صباحي', child: Text('صباحي (Morning)')),
                            DropdownMenuItem(value: 'مسائي', child: Text('مسائي (Evening)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedShift = val;
                              });
                            }
                          },
                        ),
                        ElevatedButton(
                          onPressed: _addNewDistributionRecord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1a5276),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('إضافة توزيع'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Custom Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'قائمة التوزيع الحالية وعقود المستشفيات:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),

          // Distribution List view
          Expanded(
            child: roster.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد توزيعات مسجلة حالياً',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: roster.length,
                    itemBuilder: (context, index) {
                      final item = roster[index];
                      final isMorning = item['type'] == 'صباحي';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMorning ? Colors.orange.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                            child: Text(isMorning ? '🌅' : '🌙'),
                          ),
                          title: Text(
                            "مستشفى: ${item['hospital']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "مجموعة رقم: ${item['group']} | الدوام: ${item['type']}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              final updatedRoster = List<Map<String, dynamic>>.from(roster);
                              updatedRoster.removeAt(index);
                              ref.read(rosterProvider.notifier).setRoster(updatedRoster);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Upload Parse Excel Scaffolding Instruction Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.green.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.green.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'يدعم هذا القسم رفع وتفسير ملفات Excel لقوالب توزيعات المستشفيات مباشرة عبر حوسبة سحابية متكاملة.',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewDistributionRecord() {
    final hosp = _hospitalController.text.trim();
    final grp = _groupController.text.trim();

    if (hosp.isNotEmpty && grp.isNotEmpty) {
      final newRecord = {
        'hospital': hosp,
        'group': grp,
        'type': _selectedShift,
      };

      final updated = [...ref.read(rosterProvider), newRecord];
      ref.read(rosterProvider.notifier).setRoster(updated);

      _hospitalController.clear();
      _groupController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة سجل التوزيع بنجاح!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة لتنفيذ الإجراء')),
      );
    }
  }
}
