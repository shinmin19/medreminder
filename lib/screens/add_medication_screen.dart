import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../utils/theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(text: '1片');
  final _notesController = TextEditingController();
  final _totalPillsController = TextEditingController(text: '30');
  final _refillThresholdController = TextEditingController(text: '7');

  String _selectedType = '口服';
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  DateTime? _expiryDate;
  
  final List<_ScheduleEntry> _schedules = [_ScheduleEntry()];

  final List<String> _medTypes = ['口服', '外用', '注射', '吸入', '其他'];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _totalPillsController.dispose();
    _refillThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ 添加药品'),
        actions: [
          TextButton(
            onPressed: _saveMedication,
            child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '药品名称 *',
                hintText: '如：阿莫西林',
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (v) => v == null || v.isEmpty ? '请输入药品名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: '每次剂量',
                hintText: '如：1片、2粒、5ml',
                prefixIcon: Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: '服用方式',
                prefixIcon: Icon(Icons.local_pharmacy),
              ),
              items: _medTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v ?? '口服'),
            ),
            const SizedBox(height: 16),
            
            _buildSectionTitle('提醒设置'),
            const SizedBox(height: 8),
            ..._buildScheduleEntries(),
            TextButton.icon(
              onPressed: () => setState(() => _schedules.add(_ScheduleEntry())),
              icon: const Icon(Icons.add),
              label: const Text('添加提醒时间'),
            ),
            const SizedBox(height: 16),
            
            _buildSectionTitle('外观'),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 12),
            _buildIconPicker(),
            const SizedBox(height: 16),
            
            _buildSectionTitle('库存管理'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalPillsController,
                    decoration: const InputDecoration(
                      labelText: '总数量',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _refillThresholdController,
                    decoration: const InputDecoration(
                      labelText: '补药提醒(天)',
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_expiryDate != null 
                  ? '有效期: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}' 
                  : '设置有效期'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickExpiryDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),
            
            _buildSectionTitle('备注'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: '如：饭前服用、每日三次',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _saveMedication,
              child: const Text('💾 保存药品', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(AppTheme.medicationColors.length, (index) {
        final color = AppTheme.medicationColors[index];
        final isSelected = _selectedColorIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = index),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
              boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }),
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(AppTheme.medicationIcons.length, (index) {
        final icon = AppTheme.medicationIcons[index];
        final isSelected = _selectedIconIndex == index;
        final color = AppTheme.medicationColors[_selectedColorIndex];
        return GestureDetector(
          onTap: () => setState(() => _selectedIconIndex = index),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
          ),
        );
      }),
    );
  }

  List<Widget> _buildScheduleEntries() {
    return List.generate(_schedules.length, (index) {
      final entry = _schedules[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.alarm, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text('提醒 ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  if (_schedules.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _schedules.removeAt(index)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(entry.time != null 
                    ? '时间: ${entry.time!.format(context)}'
                    : '点击设置时间'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickTime(index),
                dense: true,
              ),
              DropdownButtonFormField<String>(
                value: entry.frequency,
                decoration: const InputDecoration(
                  labelText: '频率',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('每天')),
                  DropdownMenuItem(value: 'interval', child: Text('每隔N天')),
                  DropdownMenuItem(value: 'weekly', child: Text('每周')),
                ],
                onChanged: (v) => setState(() => _schedules[index].frequency = v ?? 'daily'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '${entry.advanceMinutes}',
                      decoration: const InputDecoration(
                        labelText: '提前(分钟)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _schedules[index].advanceMinutes = int.tryParse(v) ?? 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: '${entry.repeatIntervalMinutes}',
                      decoration: const InputDecoration(
                        labelText: '间隔(分钟)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _schedules[index].repeatIntervalMinutes = int.tryParse(v) ?? 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: '${entry.repeatCount}',
                      decoration: const InputDecoration(
                        labelText: '重复次数',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _schedules[index].repeatCount = int.tryParse(v) ?? 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _pickTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _schedules[index].time ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _schedules[index].time = time);
    }
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_schedules.isEmpty || _schedules.any((s) => s.time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少设置一个提醒时间')),
      );
      return;
    }

    final schedulesData = _schedules.map((s) => {
      'time': s.time,
      'frequency': s.frequency,
      'advanceMinutes': s.advanceMinutes,
      'repeatIntervalMinutes': s.repeatIntervalMinutes,
      'repeatCount': s.repeatCount,
    }).toList();

    context.read<MedicationProvider>().addMedication(
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      medicationType: _selectedType,
      colorHex: '#${AppTheme.medicationColors[_selectedColorIndex].value.toRadixString(16).substring(2)}',
      iconIndex: _selectedIconIndex,
      notes: _notesController.text.trim(),
      totalPills: int.tryParse(_totalPillsController.text) ?? 30,
      refillThreshold: int.tryParse(_refillThresholdController.text) ?? 7,
      expiryDate: _expiryDate,
      schedulesData: schedulesData,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 药品添加成功！'),
        backgroundColor: AppTheme.takenColor,
      ),
    );
  }
}

class _ScheduleEntry {
  TimeOfDay? time;
  String frequency = 'daily';
  int advanceMinutes = 10;
  int repeatIntervalMinutes = 15;
  int repeatCount = 3;
}
