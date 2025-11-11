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

  // NOTE: This function is currently not working as intended, prof knows about this, will hopefully be resolved on Thursday.

  sendNotificationMealtime(String title, String body, String payload, TZDateTime when) {

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

  // NOTE: This is a placeholder function, purely to demonstrate notification functionality. This is actually not needed,
  // but prof wanted me to put it in due to some technical issues with the above function.

  Future<void> sendNotificationDelayed() async {

    await Future.delayed(Duration(seconds: 5), () async {

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'your_channel_id',  // Unique channel ID
        'your_channel_name',  // Name of the notification channel
        channelDescription: 'your channel description',  // Description of the channel
        importance: Importance.max,  // High importance to display the notification immediately
        priority: Priority.high,  // High priority to pop-up the notification
      );

      // Combine the notification details into NotificationDetails
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        0,  // Notification ID (0 for simplicity)
        'Good Progress!',  // Title of the notification
        'You\'ve already spent 5 seconds on this app. Great job, keep it up!',  // Body of the notification
        platformChannelSpecifics,  // Notification details
        payload: 'Notification Payload',  // Optional payload for notification taps
      );

    });

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