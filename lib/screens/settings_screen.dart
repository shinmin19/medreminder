import 'package:flutter/material.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSection(
            '通知设置',
            [
              _buildSettingItem(
                icon: Icons.notifications,
                title: '提醒通知',
                subtitle: '服药提醒已关闭（为兼容iOS 27）',
                trailing: Switch(
                  value: false,
                  onChanged: null,
                  activeColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          _buildSection(
            '数据管理',
            [
              _buildSettingItem(
                icon: Icons.backup,
                title: '导出数据',
                subtitle: '导出用药记录到文件',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中')),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.restore,
                title: '导入数据',
                subtitle: '从文件导入用药记录',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('功能开发中')),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            '关于',
            [
              _buildSettingItem(
                icon: Icons.info,
                title: '关于应用',
                subtitle: '版本 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: '用药提醒',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(
                      Icons.medication,
                      color: AppTheme.primaryColor,
                      size: 48,
                    ),
                    children: const [
                      Text('一款简单易用的用药提醒应用'),
                      SizedBox(height: 8),
                      Text('帮助您按时服药，管理用药记录。'),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
