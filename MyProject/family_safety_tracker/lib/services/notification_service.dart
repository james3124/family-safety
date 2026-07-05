import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  StreamController<String?> _tokenController = StreamController<String?>.broadcast();
  Stream<String?> get fcmTokenStream => _tokenController.stream;

  Future<void> init() async {
    await _fcm.requestPermission();
    final token = await _fcm.getToken();
    _tokenController.add(token);

    _fcm.onTokenRefresh.listen((t) => _tokenController.add(t));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ));

    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showNotification(notification.title ?? '', notification.body ?? '');
    }
  }

  Future<void> showNotification(String title, String body) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails('family_tracker', 'Family Tracker',
          importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void dispose() => _tokenController.close();
}
