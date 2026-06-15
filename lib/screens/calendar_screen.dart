import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication_record.dart';
import '../utils/theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<MedicationRecord>> _recordsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadMonthRecords();
  }

  Future<void> _loadMonthRecords() async {
    final provider = context.read<MedicationProvider>();
    final records = await provider.getRecordsForMonth(
      _focusedDay.year, 
      _focusedDay.month,
    );
    
    setState(() {
      _recordsByDay = {};
      for (final record in records) {
        final day = DateTime(
          record.scheduledTime.year,
          record.scheduledTime.month,
          record.scheduledTime.day,
        );
        _recordsByDay[day] = [...(_recordsByDay[day] ?? []), record];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 用药日历'),
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 8),
          _buildMonthStats(),
          const SizedBox(height: 8),
          Expanded(child: _buildDayRecords()),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _loadMonthRecords();
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppTheme.pendingColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final dayRecords = _recordsByDay[DateTime(day.year, day.month, day.day)];
          if (dayRecords == null || dayRecords.isEmpty) return null;
          
          final allTaken = dayRecords.every((r) => r.status == 'taken');
          final allMissed = dayRecords.every((r) => r.status == 'missed');
          final someMissed = dayRecords.any((r) => r.status == 'missed') && !allTaken;
          
          Color markerColor;
          if (allTaken) {
            markerColor = AppTheme.takenColor;
          } else if (allMissed) {
            markerColor = AppTheme.missedColor;
          } else if (someMissed) {
            markerColor = AppTheme.pendingColor;
          } else {
            markerColor = AppTheme.skippedColor;
          }
          
          return Positioned(
            bottom: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthStats() {
    final records = _recordsByDay.values.expand((r) => r).toList();
    final total = records.length;
    final taken = records.where((r) => r.status == 'taken').length;
    final missed = records.where((r) => r.status == 'missed').length;
    final rate = total > 0 ? (taken / total * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMonthStatItem('📊 总次数', '$total', AppTheme.textPrimary),
            _buildMonthStatItem('✅ 已服用', '$taken', AppTheme.takenColor),
            _buildMonthStatItem('❌ 已漏服', '$missed', AppTheme.missedColor),
            _buildMonthStatItem('📈 依从率', '$rate%', AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildDayRecords() {
    if (_selectedDay == null) return const Center(child: Text('选择日期查看'));
    
    final dayRecords = _recordsByDay[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];
    
    if (dayRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '${DateFormat('yyyy年M月d日').format(_selectedDay!)}',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '无用药记录',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayRecords.length,
      itemBuilder: (context, index) {
        final record = dayRecords[index];
        final statusColor = AppTheme.getStatusColor(record.status);
        final statusText = AppTheme.getStatusText(record.status);
        final timeStr = DateFormat('HH:mm').format(record.scheduledTime);
        final actualStr = record.actualTime != null ? DateFormat('HH:mm').format(record.actualTime!) : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(AppTheme.getStatusIcon(record.status), color: statusColor),
            ),
            title: Text('药品 ${record.medicationId.substring(0, 8)}'),
            subtitle: Text('计划: $timeStr${actualStr.isNotEmpty ? " | 实际: $actualStr" : ""}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(statusText, style: TextStyle(fontSize: 12, color: statusColor)),
            ),
          ),
        );
      },
    );
  }
}
