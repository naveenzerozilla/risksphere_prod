import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:RiskSphere/main.dart'; // for navigatorKey
import 'package:RiskSphere/providers/news_feed_provider.dart';
import 'package:RiskSphere/screens/event/notification_map_screen.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:RiskSphere/utils/api_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    PushNotificationService.showNotification(
      message.notification!.title,
      message.notification!.body,
      message.notification?.android?.imageUrl ?? "",
    );
  }
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          debugPrint('Notification payload: ${response.payload}');
        }
      },
    );
  }

  static Future<void> showNotification(
      String? title, String? body, String? imageUrl) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'Used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  static void handleNotificationNavigation(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (data['type']) {
      case 'event':
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationMapScreen(
                  notificationData: {'eventId': data['title']}),
            ));
        break;
      case 'score':
        final provider = Provider.of<NewsFeedProvider>(context, listen: false);
        provider.updateHazardData(context, jsonDecode(data['payload'] ?? '{}'));
        break;
    }
  }

  static Future<void> initFCM(String userId) async {
    debugPrint(' initFCM called with userId: $userId');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(' Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint(' Permission granted');

      if (Platform.isIOS) {
        debugPrint(' iOS detected, waiting for APNS token...');
        String? apnsToken;
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          apnsToken = await messaging.getAPNSToken();
          debugPrint(' APNS attempt $retries: $apnsToken');
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            retries++;
          }
        }
        if (apnsToken == null) {
          debugPrint(' APNS token not available after 10 retries, skipping');
          return;
        }
        debugPrint(' APNS token ready: $apnsToken');
      }

      String? token;
      try {
        debugPrint(' Fetching FCM token...');
        token = await messaging.getToken();
        debugPrint(' FCM Token: $token');
      } catch (e) {
        debugPrint(' FCM token fetch failed: $e');
        return;
      }

      if (token != null) {
        SharedPreferenceService.saveFcmToken(token);
        debugPrint(' Calling _subscribeToNotifications with userId: $userId');
        final result = await _subscribeToNotifications(userId, token);
        debugPrint(' _subscribeToNotifications result: $result');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        debugPrint(' Foreground message: ${notification?.title}');
        Fluttertoast.showToast(
          msg: notification?.title ?? "Notification",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
          timeInSecForIosWeb: 1,
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message opened app: ${message.notification?.title}');
        if (message.data.isNotEmpty) {
          handleNotificationNavigation(message.data);
        }
      });

      checkForInitialMessage();
    } else {
      debugPrint(' Permission NOT granted: ${settings.authorizationStatus}');
    }
  }

  static void checkForInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage?.data.isNotEmpty ?? false) {
      handleNotificationNavigation(initialMessage!.data);
    }
  }

  static Future<bool> _subscribeToNotifications(String userId, String token) async {
    try {
      final url = Uri.parse(AppConstant.SUBSCRIBE_NOTIFICATION);
      final payload = {
        'user_id': userId,
        'topic': 'general',
        'mobile_token': token
      };
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
