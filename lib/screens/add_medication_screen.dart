import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../utils/theme.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? existingMedication;

  const AddMedicationScreen({super.key, this.existingMedication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();

  List<MedicationSchedule> _schedules = [];
  final _uuid = const Uuid();

  bool get _isEditing => widget.existingMedication != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final med = widget.existingMedication!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage ?? '';
      _unitController.text = med.unit ?? '';
      _notesController.text = med.notes ?? '';
      _schedules = List.from(med.schedules);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addSchedule() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _schedules.add(MedicationSchedule(
        id: _uuid.v4(),
        medicationId: '',
        timeOfDay:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      ));
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  void _editScheduleRepeatDays(int index) {
    final schedule = _schedules[index];
    final selectedDays = List<int>.from(schedule.repeatDays);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('选择重复日期'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('选择服药日期:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final isSelected = selectedDays.contains(day);
                      final names = ['一', '二', '三', '四', '五', '六', '日'];
                      return FilterChip(
                        label: Text('周${names[i]}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _schedules[index] = MedicationSchedule(
                        id: schedule.id,
                        medicationId: schedule.medicationId,
                        timeOfDay: schedule.timeOfDay,
                        repeatDays: selectedDays.isNotEmpty
                            ? selectedDays
                            : [1, 2, 3, 4, 5, 6, 7],
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MedicationProvider>();

    if (_isEditing) {
      provider.updateMedication(
        widget.existingMedication!.copyWith(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim().isNotEmpty
              ? _dosageController.text.trim()
              : null,
          unit: _unitController.text.trim().isNotEmpty
              ? _unitController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          schedules: _schedules,
        ),
      );
    } else {
      provider.addMedication(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim().isNotEmpty
            ? _dosageController.text.trim()
            : null,
        unit: _unitController.text.trim().isNotEmpty
            ? _unitController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        schedules: _schedules,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? '药物已更新' : '药物已添加')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑药物' : '添加药物'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '药物名称 *',
                  hintText: '例如：阿莫西林',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入药物名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dosage and unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: '剂量',
                        hintText: '例如：500',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: '单位',
                        hintText: '例如：mg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '例如：饭后服用',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Schedules
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '用药计划',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSchedule,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加时间'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_schedules.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '暂无用药计划\n请点击上方按钮添加',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_schedules.length, (index) {
                  final schedule = _schedules[index];
                  final repeatText = _getRepeatDaysText(schedule.repeatDays);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.access_time,
                          color: AppTheme.primaryColor),
                      title: Text(
                        schedule.timeOfDay,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(repeatText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_calendar, size: 20),
                            onPressed: () => _editScheduleRepeatDays(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _removeSchedule(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? '保存修改' : '添加药物',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRepeatDaysText(List<int> days) {
    if (days.length == 7) return '每天';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return '工作日（周一至周五）';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return '周末（周六、周日）';
    }
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return days.map((d) => '周${names[d - 1]}').join('、');
  }
}
