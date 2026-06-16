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
  Map<DateTime, List<MedicationRecord>> _recordsMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final provider = context.read<MedicationProvider>();
    final records = await provider.getRecordsForMonth(
      _focusedDay.year,
      _focusedDay.month,
    );
    setState(() {
      _recordsMap = {};
      for (final record in records) {
        final day = DateTime(
          record.scheduledTime.year,
          record.scheduledTime.month,
          record.scheduledTime.day,
        );
        _recordsMap[day] = [...(_recordsMap[day] ?? []), record];
      }
    });
  }

  List<MedicationRecord> _getRecordsForDay(DateTime day) {
    return _recordsMap[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用药日历'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'zh_CN',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadRecords();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('请选择日期'))
                : _buildDayRecords(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRecords() {
    final records = _getRecordsForDay(_selectedDay!);
    if (records.isEmpty) {
      return const Center(child: Text('该日无用药记录'));
    }

    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final medication = provider.medications
                .where((m) => m.id == record.medicationId)
                .firstOrNull;
            if (medication == null) return const SizedBox.shrink();

            final timeStr = DateFormat('HH:mm').format(record.scheduledTime);
            final statusColor = record.isTaken
                ? AppTheme.primaryColor
                : record.isSkipped
                    ? Colors.red
                    : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    record.isTaken ? Icons.check : Icons.medication,
                    color: statusColor,
                  ),
                ),
                title: Text(medication.name),
                subtitle: Text('$timeStr ${medication.dosage ?? ""} ${medication.unit ?? ""}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.isTaken ? '已服用' : record.isSkipped ? '已跳过' : '待服用',
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
