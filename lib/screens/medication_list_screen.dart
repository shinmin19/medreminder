import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../utils/theme.dart';
import 'add_medication_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('药物管理'),
        automaticallyImplyLeading: true,
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无药物\n点击右下角 + 添加药物',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.medications.length,
            itemBuilder: (context, index) {
              final medication = provider.medications[index];
              return _buildMedicationCard(context, provider, medication);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicationCard(
      BuildContext context, MedicationProvider provider, Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: medication.isActive
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            Icons.medication,
            color: medication.isActive ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          medication.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: medication.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${medication.dosage ?? "未设置剂量"} ${medication.unit ?? ""}',
        ),
        children: [
          if (medication.schedules.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('用药计划:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...medication.schedules.map((schedule) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(schedule.timeOfDay),
                          const SizedBox(width: 8),
                          Text(
                            _getRepeatDaysText(schedule.repeatDays),
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (medication.notes != null && medication.notes!.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('备注: ${medication.notes}'),
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMedicationScreen(
                        existingMedication: medication,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('编辑'),
              ),
              TextButton.icon(
                onPressed: () {
                  _showDeleteDialog(context, provider, medication);
                },
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
              Switch(
                value: medication.isActive,
                onChanged: (value) {
                  provider.updateMedication(medication.copyWith(isActive: value));
                },
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRepeatDaysText(List<int> days) {
    if (days.length == 7) return '每天';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return '工作日';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return '周末';
    }
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return days.map((d) => '周${names[d - 1]}').join(' ');
  }

  void _showDeleteDialog(
      BuildContext context, MedicationProvider provider, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${medication.name}」吗？\n相关的用药记录也将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMedication(medication.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
