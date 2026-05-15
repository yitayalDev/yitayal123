import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PushNotificationService {
  static FirebaseMessaging? _fcm;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static void Function(RemoteMessage)? _onMessageReceived;

  static void setOnMessageReceived(void Function(RemoteMessage) callback) {
    _onMessageReceived = callback;
  }

  static Future<void> initialize() async {
    try {
      _fcm = FirebaseMessaging.instance;
      
      // Request permissions for iOS
      if (!kIsWeb && Platform.isIOS) {
        await _fcm?.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Initialize Local Notifications for Foreground messages
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: const DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initializationSettings);

      // Only set up Firebase listeners if _fcm is available
      if (_fcm != null && !kIsWeb) {
        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
          if (_onMessageReceived != null) {
            _onMessageReceived!(message);
          }
        });
      }
      print("Push Notification Service Initialized Successfully");
    } catch (e) {
      print("Error initializing Push Notification Service: $e");
      print("Make sure google-services.json is present in android/app/");
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  static void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
    );
  }

  static Future<String?> getToken() async {
    return await _fcm?.getToken();
  }
}
