import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import '../models/medication.dart';

class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._init();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationHelper._init();

  Future<void> initialize() async {
    if (_initialized) return;
    
    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a medication reminder
  Future<void> scheduleMedicationReminder({
    required Medication medication,
    required MedicationSchedule schedule,
  }) async {
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      schedule.time.hour,
      schedule.time.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Calculate advance reminder time
    final advanceDate = scheduledDate.subtract(Duration(minutes: schedule.advanceMinutes));

    // Main reminder notification
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
          actions: [
            const AndroidNotificationAction('taken', '✅ 已服用'),
            const AndroidNotificationAction('snooze', '⏰ 稍后提醒'),
          ],
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

    // Schedule repeat reminders if enabled
    if (schedule.repeatCount > 0) {
      for (int i = 1; i <= schedule.repeatCount; i++) {
        final repeatDate = scheduledDate.add(Duration(minutes: schedule.repeatIntervalMinutes * i));
        await _plugin.zonedSchedule(
          schedule.id.hashCode + i,
          '💊 还没吃药哦',
          '${medication.name} - 已提醒$i次',
          repeatDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'med_repeat',
              '用药重复提醒',
              channelDescription: '用药重复提醒通知',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
          }
          }
  }

  /// Cancel all reminders for a schedule
  Future<void> cancelScheduleReminders(String scheduleId, {int repeatCount = 3}) async {
    await _plugin.cancel(scheduleId.hashCode);
    for (int i = 1; i <= repeatCount; i++) {
      await _plugin.cancel(scheduleId.hashCode + i);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Setup all active medication reminders
  Future<void> setupAllReminders(List<Medication> medications) async {
    await cancelAll();
    for (final med in medications) {
      if (!med.isActive) continue;
      for (final schedule in med.schedules) {
        if (!schedule.isEnabled) continue;
        await scheduleMedicationReminder(medication: med, schedule: schedule);
      }
    }
  }
}
