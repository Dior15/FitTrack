import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart';

class Notification {

  final channelID = "mealReminder";
  final channelName = "Meal Time!";
  final channelDescription = "Don't forget to log your meal in our app!";

  // late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  var _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  NotificationDetails? _platformChannelInfo;
  var _notificationID = 67;

  Future init() async {

    if (Platform.isIOS) {
      _requestIOSPermission();
    } else if (Platform.isAndroid) {
      _requestAndroidPermission();
    }

    var initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
    var initializationSettingsIOS = DarwinInitializationSettings(
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) {
          return null;
        }
    );
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    var androidChannelInfo = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDescription: channelDescription,
    );

    var iosChannelInfo = DarwinNotificationDetails();

    _platformChannelInfo = NotificationDetails(
      android: androidChannelInfo,
      iOS: iosChannelInfo,
    );

  }

  sendNoficationMealtime(String title, String body, String payload, TZDateTime when) {

    return _flutterLocalNotificationsPlugin.zonedSchedule(
      _notificationID++,
      title,
      body,
      when,
      _platformChannelInfo!,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      payload: payload,
    );

  }

  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() {
    return _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<void> _requestAndroidPermission() async {
    if (await Permission.notification.isDenied) {
      PermissionStatus status = await Permission.notification.request();
      if (status.isDenied) {
        print("Notification permission denied");
      } else if (status.isGranted) {
        print("Notification permission granted");
      }
    }
  }

  _requestIOSPermission() {
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()!
        .requestPermissions(
      sound: true, badge: true, alert: true,
    );
  }

}