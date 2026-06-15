import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _defaultAdvanceMinutes = 10;
  int _defaultRepeatInterval = 15;
  int _defaultRepeatCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 设置'),
      ),
      body: ListView(
        children: [
          _buildSectionTitle('通知设置'),
          SwitchListTile(
            title: const Text('启用通知'),
            subtitle: const Text('关闭后将不再收到用药提醒'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('提醒声音'),
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
            secondary: const Icon(Icons.volume_up),
          ),
          SwitchListTile(
            title: const Text('震动提醒'),
            value: _vibrationEnabled,
            onChanged: (v) => setState(() => _vibrationEnabled = v),
            secondary: const Icon(Icons.vibration),
          ),
          
          _buildSectionTitle('默认提醒设置'),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('默认提前时间'),
            subtitle: Text('$_defaultAdvanceMinutes 分钟'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker('提前时间(分钟)', _defaultAdvanceMinutes, (v) {
              setState(() => _defaultAdvanceMinutes = v);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('默认间隔时间'),
            subtitle: Text('$_defaultRepeatInterval 分钟'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker('间隔时间(分钟)', _defaultRepeatInterval, (v) {
              setState(() => _defaultRepeatInterval = v);
            }),
          ),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('默认重复次数'),
            subtitle: Text('$_defaultRepeatCount 次'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker('重复次数', _defaultRepeatCount, (v) {
              setState(() => _defaultRepeatCount = v);
            }),
          ),
          
          _buildSectionTitle('数据管理'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            subtitle: const Text('导出用药记录到本地'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            subtitle: const Text('从备份文件恢复'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
            subtitle: const Text('删除所有药品和记录'),
            onTap: _clearAllData,
          ),
          
          _buildSectionTitle('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: const Text('v1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('吃药提醒APP'),
            subtitle: const Text('按时服药，健康生活'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _showNumberPicker(String title, int currentValue, Function(int) onChanged) {
    showDialog(
      context: context,
      builder: (context) {
        int tempValue = currentValue;
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$tempValue', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  Slider(
                    value: tempValue.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '$tempValue',
                    onChanged: (v) => setDialogState(() => tempValue = v.round()),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                onChanged(tempValue);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📤 数据导出功能开发中...')),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📥 数据恢复功能开发中...')),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 确认清除'),
        content: const Text('此操作将删除所有药品和用药记录，且无法恢复！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear all data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ 数据已清除')),
              );
            },
            child: const Text('确认清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
