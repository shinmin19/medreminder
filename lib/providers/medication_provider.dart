import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/medication.dart';
import '../models/medication_record.dart';
import '../database/database_helper.dart';
import '../services/notification_helper.dart';

class MedicationProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationHelper _notif = NotificationHelper.instance;
  final Uuid _uuid = const Uuid();

  List<Medication> _medications = [];
  List<Medication> _activeMedications = [];
  List<MedicationRecord> _todayRecords = [];
  Map<String, dynamic> _todayStats = {};
  Map<String, dynamic> _weekStats = {};
  Map<String, dynamic> _monthStats = {};
  bool _isLoading = false;

  // Getters
  List<Medication> get medications => _medications;
  List<Medication> get activeMedications => _activeMedications;
  List<MedicationRecord> get todayRecords => _todayRecords;
  Map<String, dynamic> get todayStats => _todayStats;
  Map<String, dynamic> get weekStats => _weekStats;
  Map<String, dynamic> get monthStats => _monthStats;
  bool get isLoading => _isLoading;

  int get todayTaken => _todayRecords.where((r) => r.status == 'taken').length;
  int get todayTotal => _todayRecords.length;
  int get todayMissed => _todayRecords.where((r) => r.status == 'missed').length;
  int get todayPending => _todayRecords.where((r) => r.status != 'taken' && r.status != 'missed').length;

  double get todayProgress => todayTotal > 0 ? todayTaken / todayTotal : 0;

  /// Initialize - load all data
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _notif.initialize();
      await _notif.requestPermission();
    } catch (e) {
      print('Notification init failed: $e');
      // Continue without notifications
    }

    try {
      await _loadMedications();
      await _generateTodayRecords();
      await _loadTodayRecords();
      await _loadStats();
    } catch (e) {
      print('Data load failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMedications() async {
    _medications = await _db.getAllMedications();
    _activeMedications = await _db.getActiveMedications();
  }

  Future<void> _generateTodayRecords() async {
    await _db.generateTodayRecords();
  }

  Future<void> _loadTodayRecords() async {
    _todayRecords = await _db.getRecordsForDate(DateTime.now());
  }

  Future<void> _loadStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    _todayStats = await _db.getAdherenceStats(today, today.add(Duration(days: 1)));
    _weekStats = await _db.getAdherenceStats(weekStart, today.add(Duration(days: 1)));
    _monthStats = await _db.getAdherenceStats(monthStart, today.add(Duration(days: 1)));
  }

  // ===== Medication CRUD =====

  Future<void> addMedication({
    required String name,
    required String dosage,
    required String medicationType,
    required String colorHex,
    required int iconIndex,
    String notes = '',
    int totalPills = 30,
    int refillThreshold = 7,
    DateTime? expiryDate,
    required List<Map<String, dynamic>> schedulesData,
  }) async {
    final id = _uuid.v4();
    List<MedicationSchedule> schedules = schedulesData.map((s) {
      return MedicationSchedule(
        id: _uuid.v4(),
        medicationId: id,
        time: s['time'],
        frequency: s['frequency'] ?? 'daily',
        intervalDays: s['intervalDays'] ?? 1,
        weekdays: s['weekdays'] ?? [1, 2, 3, 4, 5, 6, 7],
        advanceMinutes: s['advanceMinutes'] ?? 10,
        repeatIntervalMinutes: s['repeatIntervalMinutes'] ?? 15,
        repeatCount: s['repeatCount'] ?? 3,
      );
    }).toList();

    final med = Medication(
      id: id,
      name: name,
      dosage: dosage,
      medicationType: medicationType,
      colorHex: colorHex,
      iconIndex: iconIndex,
      notes: notes,
      totalPills: totalPills,
      remainingPills: totalPills,
      refillThreshold: refillThreshold,
      expiryDate: expiryDate,
      schedules: schedules,
    );

    await _db.insertMedication(med);
    await _notif.setupAllReminders(await _db.getActiveMedications());
    await refresh();
  }

  Future<void> updateMedication(Medication med) async {
    await _db.updateMedication(med);
    await _notif.setupAllReminders(await _db.getActiveMedications());
    await refresh();
  }

  Future<void> deleteMedication(String id) async {
    await _db.deleteMedication(id);
    await _notif.setupAllReminders(await _db.getActiveMedications());
    await refresh();
  }

  // ===== Check-in =====

  Future<void> checkIn(MedicationRecord record) async {
    final updated = record.copyWith(
      actualTime: DateTime.now(),
      status: 'taken',
    );
    await _db.updateRecord(updated);
    await _db.consumePill(record.medicationId);
    await _loadTodayRecords();
    await _loadStats();
    notifyListeners();
  }

  Future<void> skipDose(MedicationRecord record) async {
    final updated = record.copyWith(status: 'skipped');
    await _db.updateRecord(updated);
    await _loadTodayRecords();
    await _loadStats();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _loadMedications();
    await _generateTodayRecords();
    await _loadTodayRecords();
    await _loadStats();
    notifyListeners();
  }

  /// Get records for a specific date
  Future<List<MedicationRecord>> getRecordsForDate(DateTime date) async {
    return await _db.getRecordsForDate(date);
  }

  /// Get records for a month
  Future<List<MedicationRecord>> getRecordsForMonth(int year, int month) async {
    return await _db.getRecordsForMonth(year, month);
  }

  /// Get medication by ID
  Future<Medication?> getMedicationById(String id) async {
    return await _db.getMedication(id);
  }

  /// Toggle medication active state
  Future<void> toggleMedication(String id, bool isActive) async {
    final med = await _db.getMedication(id);
    if (med != null) {
      final updated = med.copyWith(isActive: isActive);
      await _db.updateMedication(updated);
      await _notif.setupAllReminders(await _db.getActiveMedications());
      await refresh();
    }
  }
}
