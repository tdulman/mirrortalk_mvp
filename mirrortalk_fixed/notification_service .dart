// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'prefs_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const ios = DarwinInitializationSettings(
      // App foreground iken uyarı gösterebilmek için:
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: false,
      defaultPresentSound: true,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(iOS: ios, android: android);
    await _plugin.initialize(settings);
  }

  /// iOS için izin iste (init’ten sonra çağır)
  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
  }

  static Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily',
          'Daily',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// (İstersen) yeniden planlamadan önce hepsini silmek için:
  // ... NotificationService içindeki diğer metodlar ...

  /// (İstersen) yeniden planlamadan önce hepsini silmek için:
  static Future<void> cancelAll() => _plugin.cancelAll();
} // <<<--- NotificationService BURADA KAPANIYOR

// ====== AŞAĞIDAKİLER TOP-LEVEL (sınıfın DIŞINDA) OLMALI ======

// (Kullanılmıyorsa NotificationPlans'ı tamamen silebilirsin)
class NotificationPlans {
  final int morningH, morningM;
  final int eveningH, eveningM;
  const NotificationPlans(
      this.morningH, this.morningM, this.eveningH, this.eveningM);
}

class NotificationPlanner {
  static Future<void> rescheduleFromPrefs() async {
    final (mh, mm) = await PrefsService.getMorning();
    final (eh, em) = await PrefsService.getEvening();

    await NotificationService.cancelAll();
    await NotificationService.scheduleDaily(
      id: 100,
      hour: mh,
      minute: mm,
      title: 'Morning focus',
      body: 'What do you want to accomplish today?',
    );
    await NotificationService.scheduleDaily(
      id: 101,
      hour: eh,
      minute: em,
      title: 'Evening check-in',
      body: 'What did you get done today?',
    );
  }
}

// (İstersen NotificationPlans sınıfını silebilirsin; kullanılmıyor.)
