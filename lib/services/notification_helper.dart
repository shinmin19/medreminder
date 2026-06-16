import '../models/medication.dart';

class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._init();
  bool _initialized = false;

  NotificationHelper._init();

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<void> requestPermission() async {
    // No-op for now
  }

  Future<void> scheduleMedicationReminder({
    required Medication medication,
    required MedicationSchedule schedule,
  }) async {
    // No-op for now
  }

  Future<void> cancelScheduleReminders(String scheduleId, {int repeatCount = 3}) async {
    // No-op for now
  }

  Future<void> cancelAll() async {
    // No-op for now
  }

  Future<void> setupAllReminders(List<Medication> medications) async {
    // No-op for now
  }
}
