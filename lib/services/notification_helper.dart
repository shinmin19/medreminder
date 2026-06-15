import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/medication.dart';

class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._init();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationHelper._init();

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      tz_data.initializeTimeZones();
      // Use UTC as fallback if timezone detection fails
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      } catch (e) {
        tz.setLocalLocation(tz.UTC);
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      print('Notification init error: $e');
      // Don't crash the app if notifications fail
      _initialized = false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  /// Schedule a medication reminder
  Future<void> scheduleMedicationReminder({
    required Medication medication,
    required MedicationSchedule schedule,
  }) async {
    if (!_initialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        schedule.time.hour,
        schedule.time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final advanceDate = scheduledDate.subtract(Duration(minutes: schedule.advanceMinutes));

      await _plugin.zonedSchedule(
        schedule.id.hashCode,
        '💊 该吃药啦',
        '${medication.name} - ${medication.dosage}',
        advanceDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'med_reminder',
            '用药提醒',
            channelDescription: '用药提醒通知',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: schedule.frequency == 'daily' 
            ? DateTimeComponents.time 
            : null,
      );
    } catch (e) {
      print('Schedule notification error: $e');
    }
  }

  /// Cancel all reminders for a schedule
  Future<void> cancelScheduleReminders(String scheduleId, {int repeatCount = 3}) async {
    try {
      await _plugin.cancel(scheduleId.hashCode);
      for (int i = 1; i <= repeatCount; i++) {
        await _plugin.cancel(scheduleId.hashCode + i);
      }
    } catch (e) {
      print('Cancel notification error: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      print('Cancel all error: $e');
    }
  }

  /// Setup all active medication reminders
  Future<void> setupAllReminders(List<Medication> medications) async {
    if (!_initialized) return;
    try {
      await cancelAll();
      for (final med in medications) {
        if (!med.isActive) continue;
        for (final schedule in med.schedules) {
          if (!schedule.isEnabled) continue;
          await scheduleMedicationReminder(medication: med, schedule: schedule);
        }
      }
    } catch (e) {
      print('Setup reminders error: $e');
    }
  }
}
