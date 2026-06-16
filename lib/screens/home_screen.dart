import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../models/medication_record.dart';
import '../utils/theme.dart';
import 'add_medication_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日用药'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final todayRecords = provider.todayRecords;
          final now = DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.today, color: AppTheme.primaryColor, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('yyyy年M月d日', 'zh_CN').format(now),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getWeekdayName(now.weekday),
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Summary
                if (todayRecords.isNotEmpty) ...[
                  _buildSummaryCard(todayRecords),
                  const SizedBox(height: 16),
                ],

                // Today's medications
                const Text(
                  '今日用药计划',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (todayRecords.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.medication_liquid,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              provider.activeMedications.isEmpty
                                  ? '暂无用药计划\n点击 + 添加药物'
                                  : '今日暂无用药计划',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...todayRecords.map(
                    (record) => _buildRecordCard(context, provider, record),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<MedicationRecord> records) {
    final taken = records.where((r) => r.isTaken).length;
    final skipped = records.where((r) => r.isSkipped).length;
    final pending = records.length - taken - skipped;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('待服', pending, Colors.orange),
            _buildSummaryItem('已服', taken, AppTheme.primaryColor),
            _buildSummaryItem('跳过', skipped, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRecordCard(
      BuildContext context, MedicationProvider provider, MedicationRecord record) {
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
    final statusText =
        record.isTaken ? '已服用' : record.isSkipped ? '已跳过' : '待服用';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            record.isTaken
                ? Icons.check
                : record.isSkipped
                    ? Icons.close
                    : Icons.medication,
            color: statusColor,
          ),
        ),
        title: Text(medication.name),
        subtitle: Text(
          '$timeStr ${medication.dosage ?? ""} ${medication.unit ?? ""}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
            if (!record.isTaken && !record.isSkipped) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                onPressed: () => provider.markAsTaken(record.id),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => provider.markAsSkipped(record.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return names[weekday - 1];
  }
}
