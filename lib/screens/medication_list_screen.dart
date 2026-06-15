import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../utils/theme.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💊 药品管理'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('还没有添加药品', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('点击下方 + 按钮添加', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.medications.length,
            itemBuilder: (context, index) {
              final med = provider.medications[index];
              return _buildMedicationCard(context, med, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication med, MedicationProvider provider) {
    final remaining = med.remainingPills;
    final isLow = remaining <= med.refillThreshold;
    final isExpired = med.expiryDate != null && med.expiryDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMedicationDetail(context, med),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: med.color.withValues(alpha: 0.2),
                    child: Icon(Theme.of(context).platform == TargetPlatform.iOS 
                        ? Icons.medication 
                        : AppTheme.medicationIcons[med.iconIndex % AppTheme.medicationIcons.length],
                      color: med.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${med.dosage} · ${med.medicationType}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: med.isActive,
                    onChanged: (v) => provider.toggleMedication(med.id, v),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.access_time, 
                    '${med.schedules.length}个提醒', AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.inventory_2, 
                    '剩余${med.remainingPills}片', isLow ? AppTheme.missedColor : AppTheme.textSecondary),
                  if (isLow) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.warning_amber, '需补药', AppTheme.missedColor),
                  ],
                  if (isExpired) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.error, '已过期', AppTheme.missedColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  void _showMedicationDetail(BuildContext context, Medication med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: med.color.withValues(alpha: 0.2),
                    child: Icon(AppTheme.medicationIcons[med.iconIndex % AppTheme.medicationIcons.length],
                      color: med.color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('${med.dosage} · ${med.medicationType}',
                          style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('状态', med.isActive ? '✅ 启用中' : '⏸️ 已暂停'),
              _buildDetailRow('库存', '${med.remainingPills}/${med.totalPills}片'),
              _buildDetailRow('补药阈值', '${med.refillThreshold}天'),
              if (med.expiryDate != null)
                _buildDetailRow('有效期', '${med.expiryDate!.year}-${med.expiryDate!.month.toString().padLeft(2, '0')}-${med.expiryDate!.day.toString().padLeft(2, '0')}'),
              if (med.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('备注', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(med.notes, style: const TextStyle(color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 24),
              const Text('提醒时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...med.schedules.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.alarm, color: AppTheme.primaryColor),
                title: Text('${s.time.format(context)}'),
                subtitle: Text(s.frequency == 'daily' ? '每天' : 
                  s.frequency == 'interval' ? '每隔${s.intervalDays}天' : '每周'),
                trailing: Text('提前${s.advanceMinutes}分钟'),
              )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to edit screen
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('编辑'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(context, med);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medication med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ 删除药品'),
        content: Text('确定要删除"${med.name}"吗？\n相关记录也会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<MedicationProvider>().deleteMedication(med.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
