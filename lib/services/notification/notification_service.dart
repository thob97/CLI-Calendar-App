import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  ///-----PLUGIN-----
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ///init
  Future<void> initNotification() async {
    ///android settings
    //get logo from: app/src/main/res/drawable
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_logo.jpg');

    ///ios settings
    const initializationSettingsIOS = DarwinInitializationSettings(
      // ignore: avoid_redundant_argument_values
      requestAlertPermission: true,
      // ignore: avoid_redundant_argument_values
      requestBadgePermission: true,
      // ignore: avoid_redundant_argument_values
      requestSoundPermission: true,

      ///ios < 10.0
      //show notifications in foreground for ios devices older than ios 10.0
      // onDidReceiveLocalNotification:
      //     (int id, String? title, String? body, String? payload) async {},
    );

    ///set android+ios settings
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,

      ///ios < 10.0
      //show notifications in foreground for ios devices older than ios 10.0
      // onDidReceiveNotificationResponse:
      //     (NotificationResponse notificationResponse) async {},
    );
  }

  ///get device specified details
  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.max,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  ///-----METHODS-----
  Future showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return _notificationsPlugin.show(
      id,
      title,
      body,
      _getNotificationDetails(),
    );
  }

  Future scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    required DateTime scheduledNotificationTime,
  }) async {
    //debugPrint('added scheduled notification at:$scheduledNotificationTime, title:$title, body:$body');
    return _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(
        scheduledNotificationTime,
        tz.local,
      ),
      _getNotificationDetails(),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
