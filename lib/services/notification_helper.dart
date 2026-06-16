/// No-op notification helper.
/// Notifications are disabled to avoid iOS 27 compatibility issues
/// with flutter_local_notifications, timezone, and permission_handler packages.
class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._();
  NotificationHelper._();

  Future<void> init() async {
    // No-op: notifications disabled
  }

  Future<void> scheduleMedicationReminder({
    required String id,
    required String medicationName,
    required DateTime scheduledTime,
    String? dosage,
  }) async {
    // No-op
  }

  Future<void> cancelReminder(String id) async {
    // No-op
  }

  Future<void> cancelAllReminders() async {
    // No-op
  }
}
