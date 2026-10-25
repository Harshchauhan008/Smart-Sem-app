
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../model/assignment_model.dart';

class ReminderService {
  ReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Synchronizes locally scheduled reminders with backend assignments.
  static Future<void> syncAssignments(
      List<AssignmentModel> assignments,
      ) async {
    await init();

    for (final assignment in assignments) {
      // Reserve three notification IDs per assignment.
      for (var i = 1; i <= 3; i++) {
        await _plugin.cancel(assignment.id * 10 + i);
      }

      if (assignment.status.toUpperCase() != 'PENDING') continue;

      final deadline = assignment.deadline;
      if (deadline == null) continue;

      final due = tz.TZDateTime.from(deadline, tz.local);

      await _schedule(
        assignment.id * 10 + 1,
        'Assignment due tomorrow',
        '${assignment.title} is due tomorrow.',
        tz.TZDateTime(tz.local, due.year, due.month, due.day - 1, 9),
      );

      await _schedule(
        assignment.id * 10 + 2,
        'Assignment due today',
        '${assignment.title} is due today.',
        tz.TZDateTime(tz.local, due.year, due.month, due.day, 8),
      );

      await _schedule(
        assignment.id * 10 + 3,
        'Assignment deadline approaching',
        '${assignment.title} is due in 2 hours.',
        due.subtract(const Duration(hours: 2)),
      );
    }
  }

  static Future<void> _schedule(
      int id,
      String title,
      String body,
      tz.TZDateTime scheduledTime,
      ) async {
    if (!scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'assignment_reminders',
          'Assignment reminders',
          channelDescription: 'Reminders for upcoming SmartSem assignments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
