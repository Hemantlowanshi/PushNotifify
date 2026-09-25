import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_notify/notification_details.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('BACKGROUND MESSAGE: ${message.messageId}');
  debugPrint('DATA: ${message.data}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _navigateToDetails(data);
          } catch (e) {
            debugPrint('Error decoding payload: $e');
          }
        }
      },
    );

    // Create Notification Channel for Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Set Background Messaging Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Request Notification Permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Permission status: ${settings.authorizationStatus}');

    // 4. Get and Print FCM Token
    final token = await _messaging.getToken();
    debugPrint('FCM TOKEN: $token');

    // 5. Foreground Notification Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FOREGROUND MESSAGE: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 6. Notification Click Handling (Background State)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('NOTIFICATION CLICKED (BACKGROUND): ${message.data}');
      _navigateToDetails(message.data);
    });

    // 7. Notification Click Handling (Terminated State)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('NOTIFICATION CLICKED (TERMINATED): ${initialMessage.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDetails(initialMessage.data);
      });
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification?.title ?? 'New Notification',
      body: notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _navigateToDetails(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationDetailsPage(data: data),
      ),
    );
  }
}
