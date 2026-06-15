import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication_record.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💊 今日用药'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MedicationProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProgressCard(provider),
                const SizedBox(height: 16),
                _buildStreakCard(provider),
                const SizedBox(height: 16),
                _buildSectionTitle('今日用药'),
                const SizedBox(height: 8),
                if (provider.todayRecords.isEmpty)
                  _buildEmptyState()
                else
                  ...provider.todayRecords.map((record) => 
                    _buildMedicationRecordCard(context, record, provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(MedicationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '今日进度',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: provider.todayProgress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(provider.todayProgress * 100).round()}%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${provider.todayTaken}/${provider.todayTotal}',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('✅ 已服用', '${provider.todayTaken}', AppTheme.takenColor),
                _buildStatItem('⏰ 待服用', '${provider.todayPending}', AppTheme.pendingColor),
                _buildStatItem('❌ 已漏服', '${provider.todayMissed}', AppTheme.missedColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(MedicationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              '连续打卡 ${provider.monthStats['taken'] ?? 0} 天',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无用药计划',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角 + 添加你的第一个药品',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRecordCard(BuildContext context, MedicationRecord record, MedicationProvider provider) {
    final timeStr = DateFormat('HH:mm').format(record.scheduledTime);
    final statusColor = AppTheme.getStatusColor(record.status);
    final statusIcon = AppTheme.getStatusIcon(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          record.medicationId, // Will be replaced with actual name
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('计划时间: $timeStr'),
        trailing: _buildActionButtons(context, record, provider),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MedicationRecord record, MedicationProvider provider) {
    if (record.status == 'taken') {
      return Chip(
        label: const Text('✅ 已服用', style: TextStyle(fontSize: 12)),
        backgroundColor: AppTheme.takenColor.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppTheme.takenColor),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (record.status != 'taken' && record.scheduledTime.isAfter(DateTime.now().subtract(const Duration(hours: 1)))) ...[
          TextButton.icon(
            onPressed: () => _showSnoozeDialog(context, record, provider),
            icon: const Icon(Icons.snooze, size: 18),
            label: const Text('稍后', style: TextStyle(fontSize: 12)),
          ),
        ],
        ElevatedButton.icon(
          onPressed: () async {
            await provider.checkIn(record);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ 打卡成功！'),
                  backgroundColor: AppTheme.takenColor,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('服用', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _showSnoozeDialog(BuildContext context, MedicationRecord record, MedicationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ 稍后提醒'),
        content: const Text('选择延迟时间'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement snooze with notification
            },
            child: const Text('5分钟'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement snooze with notification
            },
            child: const Text('15分钟'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement snooze with notification
            },
            child: const Text('30分钟'),
          ),
        ],
      ),
    );
  }
}
