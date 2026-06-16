import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/medication.dart';
import '../models/medication_record.dart';

class MedicationProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<Medication> _medications = [];
  List<MedicationRecord> _records = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  List<MedicationRecord> get records => _records;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  List<Medication> get activeMedications =>
      _medications.where((m) => m.isActive).toList();

  List<MedicationRecord> get todayRecords {
    final now = DateTime.now();
    return _records.where((r) {
      return r.scheduledTime.year == now.year &&
          r.scheduledTime.month == now.month &&
          r.scheduledTime.day == now.day;
    }).toList();
  }

  List<MedicationRecord> getRecordsForDate(DateTime date) {
    return _records.where((r) {
      return r.scheduledTime.year == date.year &&
          r.scheduledTime.month == date.month &&
          r.scheduledTime.day == date.day;
    }).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _medications = await _db.getAllMedications();
    _records = await _db.getAllRecords();

    _isLoading = false;
    notifyListeners();

    // Auto-generate today's records after loading
    await generateRecordsForDate(DateTime.now());
  }

  Future<void> addMedication({
    required String name,
    String? dosage,
    String? unit,
    String? notes,
    List<MedicationSchedule>? schedules,
  }) async {
    final medication = Medication(
      id: _uuid.v4(),
      name: name,
      dosage: dosage,
      unit: unit,
      notes: notes,
      schedules: schedules ?? [],
    );
    await _db.insertMedication(medication);
    await loadData();
  }

  Future<void> updateMedication(Medication medication) async {
    await _db.updateMedication(medication);
    await loadData();
  }

  Future<void> deleteMedication(String id) async {
    await _db.deleteMedication(id);
    await loadData();
  }

  Future<void> markAsTaken(String recordId) async {
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      final updated = _records[index].copyWith(
        isTaken: true,
        takenAt: DateTime.now(),
      );
      await _db.updateRecord(updated);
      _records[index] = updated;
      notifyListeners();
    }
  }

  Future<void> markAsSkipped(String recordId) async {
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      final updated = _records[index].copyWith(isSkipped: true);
      await _db.updateRecord(updated);
      _records[index] = updated;
      notifyListeners();
    }
  }

  Future<void> generateRecordsForDate(DateTime date) async {
    final existingRecords = getRecordsForDate(date);
    final weekday = date.weekday;

    for (final medication in activeMedications) {
      for (final schedule in medication.schedules) {
        if (!schedule.isActive) continue;
        if (!schedule.repeatDays.contains(weekday)) continue;

        // Check if record already exists
        final alreadyExists = existingRecords.any(
          (r) =>
              r.medicationId == medication.id &&
              r.scheduleId == schedule.id,
        );
        if (alreadyExists) continue;

        final parts = schedule.timeOfDay.split(':');
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        final record = MedicationRecord(
          id: _uuid.v4(),
          medicationId: medication.id,
          scheduleId: schedule.id,
          scheduledTime: scheduledTime,
        );
        await _db.insertRecord(record);
      }
    }
    // Don't call loadData() here to avoid infinite recursion
    // The caller should reload data after calling this method
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<List<MedicationRecord>> getRecordsForMonth(int year, int month) async {
    return await _db.getRecordsForMonth(year, month);
  }
}
