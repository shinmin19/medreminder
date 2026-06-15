import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication.dart';
import '../models/medication_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medreminder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute("""
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT DEFAULT '1片',
        medicationType TEXT DEFAULT '口服',
        colorHex TEXT DEFAULT '#4CAF50',
        iconIndex INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        totalPills INTEGER DEFAULT 30,
        remainingPills INTEGER DEFAULT 30,
        refillThreshold INTEGER DEFAULT 7,
        expiryDate TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    """);

    await db.execute("""
      CREATE TABLE medication_schedules (
        id TEXT PRIMARY KEY,
        medicationId TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        frequency TEXT DEFAULT 'daily',
        intervalDays INTEGER DEFAULT 1,
        weekdays TEXT DEFAULT '1,2,3,4,5,6,7',
        advanceMinutes INTEGER DEFAULT 10,
        repeatIntervalMinutes INTEGER DEFAULT 15,
        repeatCount INTEGER DEFAULT 3,
        isEnabled INTEGER DEFAULT 1,
        FOREIGN KEY (medicationId) REFERENCES medications (id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE medication_records (
        id TEXT PRIMARY KEY,
        medicationId TEXT NOT NULL,
        scheduleId TEXT NOT NULL,
        scheduledTime TEXT NOT NULL,
        actualTime TEXT,
        status TEXT DEFAULT 'missed',
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (medicationId) REFERENCES medications (id) ON DELETE CASCADE
      )
    """);

    await db.execute('CREATE INDEX idx_records_date ON medication_records(scheduledTime)');
    await db.execute('CREATE INDEX idx_records_med ON medication_records(medicationId)');
    await db.execute('CREATE INDEX idx_schedules_med ON medication_schedules(medicationId)');
  }

  // ===== Medication CRUD =====

  Future<String> insertMedication(Medication med) async {
    final db = await database;
    await db.insert('medications', med.toMap());
    for (final schedule in med.schedules) {
      await db.insert('medication_schedules', schedule.toMap());
    }
    return med.id;
  }

  Future<Medication?> getMedication(String id) async {
    final db = await database;
    final maps = await db.query('medications', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final med = Medication.fromMap(maps.first);
    final schedules = await getSchedules(id);
    return med.copyWith(schedules: schedules);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final maps = await db.query('medications', orderBy: 'createdAt DESC');
    List<Medication> meds = [];
    for (final map in maps) {
      final med = Medication.fromMap(map);
      final schedules = await getSchedules(med.id);
      meds.add(med.copyWith(schedules: schedules));
    }
    return meds;
  }

  Future<List<Medication>> getActiveMedications() async {
    final db = await database;
    final maps = await db.query('medications', where: 'isActive = 1', orderBy: 'createdAt DESC');
    List<Medication> meds = [];
    for (final map in maps) {
      final med = Medication.fromMap(map);
      final schedules = await getSchedules(med.id);
      meds.add(med.copyWith(schedules: schedules));
    }
    return meds;
  }

  Future<int> updateMedication(Medication med) async {
    final db = await database;
    int result = await db.update('medications', med.toMap(), where: 'id = ?', whereArgs: [med.id]);
    await db.delete('medication_schedules', where: 'medicationId = ?', whereArgs: [med.id]);
    for (final schedule in med.schedules) {
      await db.insert('medication_schedules', schedule.toMap());
    }
    return result;
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    await db.delete('medication_schedules', where: 'medicationId = ?', whereArgs: [id]);
    await db.delete('medication_records', where: 'medicationId = ?', whereArgs: [id]);
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // ===== Schedule CRUD =====

  Future<List<MedicationSchedule>> getSchedules(String medicationId) async {
    final db = await database;
    final maps = await db.query('medication_schedules', where: 'medicationId = ?', whereArgs: [medicationId]);
    return maps.map((map) => MedicationSchedule.fromMap(map)).toList();
  }

  Future<List<MedicationSchedule>> getAllSchedules() async {
    final db = await database;
    final maps = await db.query('medication_schedules', where: 'isEnabled = 1');
    return maps.map((map) => MedicationSchedule.fromMap(map)).toList();
  }

  // ===== Record CRUD =====

  Future<String> insertRecord(MedicationRecord record) async {
    final db = await database;
    await db.insert('medication_records', record.toMap());
    return record.id;
  }

  Future<int> updateRecord(MedicationRecord record) async {
    final db = await database;
    return await db.update('medication_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<MedicationRecord?> getRecordForSchedule(String scheduleId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final maps = await db.query(
      'medication_records',
      where: 'scheduleId = ? AND scheduledTime >= ? AND scheduledTime < ?',
      whereArgs: [scheduleId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MedicationRecord.fromMap(maps.first);
  }

  Future<List<MedicationRecord>> getRecordsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final maps = await db.query(
      'medication_records',
      where: 'scheduledTime >= ? AND scheduledTime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'scheduledTime ASC',
    );
    return maps.map((map) => MedicationRecord.fromMap(map)).toList();
  }

  Future<List<MedicationRecord>> getRecordsForMonth(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final maps = await db.query(
      'medication_records',
      where: 'scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'scheduledTime ASC',
    );
    return maps.map((map) => MedicationRecord.fromMap(map)).toList();
  }

  Future<void> generateTodayRecords() async {
    final schedules = await getAllSchedules();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final schedule in schedules) {
      final existing = await getRecordForSchedule(schedule.id, today);
      if (existing == null) {
        final scheduledTime = DateTime(today.year, today.month, today.day, schedule.time.hour, schedule.time.minute);
        final record = MedicationRecord(
          id: '${schedule.id}_${today.toIso8601String().substring(0, 10)}',
          medicationId: schedule.medicationId,
          scheduleId: schedule.id,
          scheduledTime: scheduledTime,
          status: scheduledTime.isBefore(now) ? 'missed' : 'pending',
        );
        await insertRecord(record);
      }
    }
  }

  Future<Map<String, dynamic>> getAdherenceStats(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'medication_records',
      where: 'scheduledTime >= ? AND scheduledTime <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    
    int total = maps.length;
    int taken = maps.where((m) => m['status'] == 'taken').length;
    int missed = maps.where((m) => m['status'] == 'missed').length;
    int skipped = maps.where((m) => m['status'] == 'skipped').length;
    
    return {
      'total': total,
      'taken': taken,
      'missed': missed,
      'skipped': skipped,
      'adherenceRate': total > 0 ? (taken / total * 100).round() : 0,
    };
  }

  Future<void> consumePill(String medicationId) async {
    final db = await database;
    final maps = await db.query('medications', where: 'id = ?', whereArgs: [medicationId]);
    if (maps.isNotEmpty) {
      int remaining = (maps.first['remainingPills'] as int?) ?? 0;
      if (remaining > 0) {
        await db.update('medications', {'remainingPills': remaining - 1}, where: 'id = ?', whereArgs: [medicationId]);
      }
    }
  }
}
