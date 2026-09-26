import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push_notify/notification_details.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp();

  debugPrint('BACKGROUND MESSAGE: ${message.messageId}');
  debugPrint('DATA: ${message.data}');

  FirebaseCrashlytics.instance.log(
    'Background notification received',
  );
}

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      FirebaseCrashlytics.instance.log(
        'NotificationService initialization started',
      );

      // 1. Initialize Local Notifications
      const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) {
          if (response.payload != null &&
              response.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data =
              jsonDecode(response.payload!);

              _navigateToDetails(data);
            } catch (error, stackTrace) {
              FirebaseCrashlytics.instance.recordError(
                error,
                stackTrace,
              );

              debugPrint(
                'Error decoding payload: $error',
              );
            }
          }
        },
      );

      // 2. Create Notification Channel
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description:
        'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Set Background Messaging Handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 4. Request Notification Permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        'Permission status: ${settings.authorizationStatus}',
      );

      // 5. Get FCM Token
      final token = await _messaging.getToken();

      debugPrint('FCM TOKEN: $token');

      FirebaseCrashlytics.instance.log(
        'FCM token generated successfully',
      );

      // 6. Foreground Notification Handling
      FirebaseMessaging.onMessage.listen(
            (RemoteMessage message) {
          try {
            debugPrint(
              'FOREGROUND MESSAGE: '
                  '${message.notification?.title}',
            );

            _showLocalNotification(message);
          } catch (error, stackTrace) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stackTrace,
            );
          }
        },
      );

      // 7. Notification Click Handling
      // Background State
      FirebaseMessaging.onMessageOpenedApp.listen(
            (RemoteMessage message) {
          try {
            debugPrint(
              'NOTIFICATION CLICKED (BACKGROUND): '
                  '${message.data}',
            );

            _navigateToDetails(message.data);
          } catch (error, stackTrace) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stackTrace,
            );
          }
        },
      );

      // 8. Notification Click Handling
      // Terminated State
      final initialMessage =
      await _messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'NOTIFICATION CLICKED (TERMINATED): '
              '${initialMessage.data}',
        );

        WidgetsBinding.instance.addPostFrameCallback(
              (_) {
            _navigateToDetails(
              initialMessage.data,
            );
          },
        );
      }

      FirebaseCrashlytics.instance.log(
        'NotificationService initialization completed',
      );
    } catch (error, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );

      debugPrint(
        'NotificationService initialization error: $error',
      );
    }
  }

  void _showLocalNotification(
      RemoteMessage message,
      ) {
    try {
      final notification = message.notification;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification?.title ?? 'New Notification',
        body: notification?.body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
            'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
      );

      debugPrint(
        'Local notification error: $error',
      );
    }
  }

  void _navigateToDetails(
      Map<String, dynamic> data,
      ) {
    try {
      if (data.isEmpty) return;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) =>
              NotificationDetailsPage(data: data),
        ),
      );
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
      );

      debugPrint(
        'Navigation error: $error',
      );
    }
  }
}