import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'utils/theme.dart';

// ==================== Models ====================
class Medication {
  final String id;
  final String name;
  final String? dosage;
  final String? unit;
  final String? notes;
  final List<MedicationSchedule> schedules;
  final bool isActive;

  Medication({
    required this.id,
    required this.name,
    this.dosage,
    this.unit,
    this.notes,
    this.schedules = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'dosage': dosage, 'unit': unit,
    'notes': notes, 'isActive': isActive,
    'schedules': schedules.map((s) => s.toMap()).toList(),
  };

  factory Medication.fromMap(Map<String, dynamic> m) => Medication(
    id: m['id'], name: m['name'], dosage: m['dosage'], unit: m['unit'],
    notes: m['notes'], isActive: m['isActive'] ?? true,
    schedules: (m['schedules'] as List? ?? []).map((s) => MedicationSchedule.fromMap(s)).toList(),
  );

  Medication copyWith({String? name, String? dosage, String? unit, String? notes, List<MedicationSchedule>? schedules, bool? isActive}) {
    return Medication(id: id, name: name ?? this.name, dosage: dosage ?? this.dosage, unit: unit ?? this.unit, notes: notes ?? this.notes, schedules: schedules ?? this.schedules, isActive: isActive ?? this.isActive);
  }
}

class MedicationSchedule {
  final String id;
  final String timeOfDay;
  final List<int> repeatDays;
  final bool isActive;

  MedicationSchedule({required this.id, required this.timeOfDay, this.repeatDays = const [1,2,3,4,5,6,7], this.isActive = true});

  Map<String, dynamic> toMap() => {'id': id, 'timeOfDay': timeOfDay, 'repeatDays': repeatDays, 'isActive': isActive};
  factory MedicationSchedule.fromMap(Map<String, dynamic> m) => MedicationSchedule(id: m['id'], timeOfDay: m['timeOfDay'], repeatDays: List<int>.from(m['repeatDays'] ?? [1,2,3,4,5,6,7]), isActive: m['isActive'] ?? true);
}

class MedRecord {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final bool isTaken;
  final bool isSkipped;

  MedRecord({required this.id, required this.medicationId, required this.scheduledTime, this.isTaken = false, this.isSkipped = false});

  Map<String, dynamic> toMap() => {'id': id, 'medicationId': medicationId, 'scheduledTime': scheduledTime.millisecondsSinceEpoch, 'isTaken': isTaken, 'isSkipped': isSkipped};
  factory MedRecord.fromMap(Map<String, dynamic> m) => MedRecord(id: m['id'], medicationId: m['medicationId'], scheduledTime: DateTime.fromMillisecondsSinceEpoch(m['scheduledTime']), isTaken: m['isTaken'] ?? false, isSkipped: m['isSkipped'] ?? false);

  MedRecord copyWith({bool? isTaken, bool? isSkipped}) => MedRecord(id: id, medicationId: medicationId, scheduledTime: scheduledTime, isTaken: isTaken ?? this.isTaken, isSkipped: isSkipped ?? this.isSkipped);
}

// ==================== Provider ====================
class MedProvider extends ChangeNotifier {
  List<Medication> _medications = [];
  List<MedRecord> _records = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  List<Medication> get medications => _medications;
  List<MedicationRecord> get todayRecords {
    final now = DateTime.now();
    return _records.where((r) => r.scheduledTime.year == now.year && r.scheduledTime.month == now.month && r.scheduledTime.day == now.day).toList();
  }
  List<MedRecord> getRecordsForDate(DateTime d) => _records.where((r) => r.scheduledTime.year == d.year && r.scheduledTime.month == d.month && r.scheduledTime.day == d.day).toList();
  bool get isLoading => _isLoading;

  Future<void> init() async {
    // Pure in-memory - no native plugins
    _isLoading = false;
    notifyListeners();
  }

  void addMedication(String name, {String? dosage, String? unit, List<MedicationSchedule>? schedules}) {
    final med = Medication(id: _uuid.v4(), name: name, dosage: dosage, unit: unit, schedules: schedules ?? []);
    _medications.add(med);
    _generateTodayRecords();
    notifyListeners();
  }

  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    _records.removeWhere((r) => r.medicationId == id);
    notifyListeners();
  }

  void markTaken(String recordId) {
    final i = _records.indexWhere((r) => r.id == recordId);
    if (i != -1) { _records[i] = _records[i].copyWith(isTaken: true); notifyListeners(); }
  }

  void markSkipped(String recordId) {
    final i = _records.indexWhere((r) => r.id == recordId);
    if (i != -1) { _records[i] = _records[i].copyWith(isSkipped: true); notifyListeners(); }
  }

  void _generateTodayRecords() {
    final now = DateTime.now();
    final weekday = now.weekday;
    for (final med in _medications.where((m) => m.isActive)) {
      for (final sch in med.schedules) {
        if (!sch.isActive || !sch.repeatDays.contains(weekday)) continue;
        final exists = _records.any((r) => r.medicationId == med.id && r.scheduledTime.hour == int.parse(sch.timeOfDay.split(':')[0]) && r.scheduledTime.day == now.day);
        if (exists) continue;
        final parts = sch.timeOfDay.split(':');
        _records.add(MedRecord(id: _uuid.v4(), medicationId: med.id, scheduledTime: DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]))));
      }
    }
  }
}

// ==================== App ====================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedProvider()..init(),
      child: MaterialApp(title: '用药提醒', debugShowCheckedModeBanner: false, theme: AppTheme.greenTheme, home: const HomeScreen()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [_HomePage(), _CalendarPage(), _StatsPage()][_tab],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
        selectedItemColor: AppTheme.primaryColor, unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '日历'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('添加药物', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '药物名称', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: dosageCtrl, decoration: const InputDecoration(labelText: '剂量', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '单位', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            context.read<MedProvider>().addMedication(nameCtrl.text.trim(), dosage: dosageCtrl.text.trim().isEmpty ? null : dosageCtrl.text.trim(), unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim());
            Navigator.pop(ctx);
          },
          child: const Text('添加'),
        )),
      ]),
    ));
  }
}

// ==================== Pages ====================
class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日用药')),
      body: Consumer<MedProvider>(builder: (ctx, prov, _) {
        final records = prov.todayRecords;
        final taken = records.where((r) => r.isTaken).length;
        final skipped = records.where((r) => r.isSkipped).length;
        final pending = records.length - taken - skipped;
        final now = DateTime.now();
        final weekdays = ['一','二','三','四','五','六','日'];

        return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(Icons.today, color: AppTheme.primaryColor, size: 32),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${now.year}年${now.month}月${now.day}日', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('星期${weekdays[now.weekday - 1]}', style: TextStyle(color: AppTheme.textSecondary)),
            ]),
          ]))),
          const SizedBox(height: 16),
          if (records.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('待服', pending, Colors.orange),
            _statItem('已服', taken, AppTheme.primaryColor),
            _statItem('跳过', skipped, Colors.red),
          ]))),
          const SizedBox(height: 16),
          const Text('今日用药计划', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (records.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Column(children: [
            Icon(Icons.medication_liquid, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(prov.medications.isEmpty ? '暂无用药计划\n点击 + 添加药物' : '今日暂无用药计划', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          ]))))
          else ...records.map((r) {
            final med = prov.medications.where((m) => m.id == r.medicationId).firstOrNull;
            if (med == null) return const SizedBox.shrink();
            final color = r.isTaken ? AppTheme.primaryColor : r.isSkipped ? Colors.red : Colors.orange;
            final status = r.isTaken ? '已服用' : r.isSkipped ? '已跳过' : '待服用';
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: CircleAvatar(backgroundColor: color.withAlpha(25), child: Icon(r.isTaken ? Icons.check : r.isSkipped ? Icons.close : Icons.medication, color: color)),
              title: Text(med.name),
              subtitle: Text('${r.scheduledTime.hour.toString().padLeft(2,'0')}:${r.scheduledTime.minute.toString().padLeft(2,'0')} ${med.dosage ?? ''} ${med.unit ?? ''}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 12))),
                if (!r.isTaken && !r.isSkipped) ...[
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.check_circle, color: AppTheme.primaryColor), onPressed: () => prov.markTaken(r.id)),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => prov.markSkipped(r.id)),
                ],
              ]),
            ));
          }),
        ]));
      }),
    );
  }

  Widget _statItem(String label, int count, Color color) => Column(children: [
    Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(color: AppTheme.textSecondary)),
  ]);
}

class _CalendarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: Consumer<MedProvider>(builder: (ctx, prov, _) {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        return Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text('${now.year}年${now.month}月', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Expanded(child: GridView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7), itemCount: daysInMonth, itemBuilder: (ctx, i) {
            final day = i + 1;
            final date = DateTime(now.year, now.month, day);
            final records = prov.getRecordsForDate(date);
            final isToday = day == now.day;
            final hasRecords = records.isNotEmpty;
            final allTaken = records.isNotEmpty && records.every((r) => r.isTaken);
            return Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryColor : allTaken ? AppTheme.primaryColor.withAlpha(25) : null,
              borderRadius: BorderRadius.circular(8),
              border: hasRecords && !allTaken ? Border.all(color: Colors.orange, width: 2) : null,
            ), child: Center(child: Text('$day', style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.white : null))));
          })),
        ]);
      }),
    );
  }
}

class _StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: Consumer<MedProvider>(builder: (ctx, prov, _) {
        final all = prov.todayRecords;
        final taken = all.where((r) => r.isTaken).length;
        final total = all.length;
        final rate = total > 0 ? (taken / total * 100).round() : 0;
        return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _card('今日服药率', '$rate%', AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _card('已服用', '$taken', AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _card('总计划', '$total', Colors.orange)),
          ]),
          const SizedBox(height: 24),
          const Text('各药物统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...prov.medications.map((med) {
            final medRecords = prov.todayRecords.where((r) => r.medicationId == med.id).toList();
            final medTaken = medRecords.where((r) => r.isTaken).length;
            final medTotal = medRecords.length;
            return Card(child: ListTile(
              leading: const Icon(Icons.medication, color: AppTheme.primaryColor),
              title: Text(med.name),
              subtitle: LinearProgressIndicator(value: medTotal > 0 ? medTaken / medTotal : 0, backgroundColor: Colors.grey[200], color: AppTheme.primaryColor),
              trailing: Text('${medTotal > 0 ? (medTaken / medTotal * 100).round() : 0}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ));
          }),
        ]));
      }),
    );
  }

  Widget _card(String title, String value, Color color) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
    const SizedBox(height: 4),
    Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
  ])));
}
