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
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT,
        unit TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_schedules (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        repeat_days TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_records (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        schedule_id TEXT,
        scheduled_time INTEGER NOT NULL,
        taken_at INTEGER,
        is_taken INTEGER NOT NULL DEFAULT 0,
        is_skipped INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');
  }

  // Medication CRUD
  Future<void> insertMedication(Medication medication) async {
    final db = await database;
    await db.insert('medications', medication.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final schedule in medication.schedules) {
      await db.insert('medication_schedules', schedule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> updateMedication(Medication medication) async {
    final db = await database;
    await db.update('medications', medication.toMap(),
        where: 'id = ?', whereArgs: [medication.id]);
    // Delete old schedules and insert new ones
    await db.delete('medication_schedules',
        where: 'medication_id = ?', whereArgs: [medication.id]);
    for (final schedule in medication.schedules) {
      await db.insert('medication_schedules', schedule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> deleteMedication(String id) async {
    final db = await database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
    await db.delete('medication_schedules',
        where: 'medication_id = ?', whereArgs: [id]);
    await db.delete('medication_records',
        where: 'medication_id = ?', whereArgs: [id]);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final medMaps = await db.query('medications');
    List<Medication> medications = [];
    for (final medMap in medMaps) {
      final scheduleMaps = await db.query('medication_schedules',
          where: 'medication_id = ?', whereArgs: [medMap['id']]);
      final schedules =
          scheduleMaps.map((m) => MedicationSchedule.fromMap(m)).toList();
      medications.add(Medication.fromMap(medMap, schedules: schedules));
    }
    return medications;
  }

  // Record CRUD
  Future<void> insertRecord(MedicationRecord record) async {
    final db = await database;
    await db.insert('medication_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateRecord(MedicationRecord record) async {
    final db = await database;
    await db.update('medication_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<List<MedicationRecord>> getRecordsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'medication_records',
      where: 'scheduled_time >= ? AND scheduled_time < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    return maps.map((m) => MedicationRecord.fromMap(m)).toList();
  }

  Future<List<MedicationRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('medication_records');
    return maps.map((m) => MedicationRecord.fromMap(m)).toList();
  }

  Future<List<MedicationRecord>> getRecordsForMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final maps = await db.query(
      'medication_records',
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );
    return maps.map((m) => MedicationRecord.fromMap(m)).toList();
  }
}
