import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:RiskSphare/firebase_options.dart';
import 'package:RiskSphare/providers/configuration_provider.dart';
import 'package:RiskSphare/providers/drawer_selection_provider.dart';
import 'package:RiskSphare/providers/job_monitoring_provier.dart';
import 'package:RiskSphare/providers/my_location_list_provider.dart';
import 'package:RiskSphare/providers/news_feed_provider.dart';
import 'package:RiskSphare/screens/event/notification_map_screen.dart';
import 'package:RiskSphare/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:RiskSphare/providers/account_list_provider.dart';
import 'package:RiskSphare/providers/auth_provider.dart';
import 'package:RiskSphare/providers/company_provider.dart';
import 'package:RiskSphare/providers/connections_provider.dart';
import 'package:RiskSphare/providers/corporate_user_provider.dart';
import 'package:RiskSphare/providers/dashboard_provider.dart';
import 'package:RiskSphare/providers/email_provider.dart';
import 'package:RiskSphare/providers/employee_provider.dart';
import 'package:RiskSphare/providers/feature_provider.dart';
import 'package:RiskSphare/providers/location_list_provider.dart';
import 'package:RiskSphare/providers/location_profile_provider.dart';
import 'package:RiskSphare/providers/non_corporate_user_Provider.dart';
import 'package:RiskSphare/providers/role_provider.dart';
import 'package:RiskSphare/providers/sov_list_provider.dart';
import 'package:RiskSphare/providers/sub_account_list_provider.dart';
import 'package:RiskSphare/providers/upload_sov_provider.dart';
import 'package:RiskSphare/providers/user_profile_provider.dart';
import 'package:RiskSphare/providers/verification_provider.dart';
import 'package:RiskSphare/service/shared_preference_service.dart';
import 'package:provider/provider.dart';

import 'design_system/app_themes.dart';
import 'design_system/primitives/app_colors.dart';

import 'providers/theme_provider.dart';
import 'screens/onboarding/splash_screen.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      final String? payload = notificationResponse.payload;
      if (payload != null) {
        try {
          print('Received notification payload top: $payload');
          final Map<String, dynamic> data = jsonDecode(payload);
          print('Received notification payload: $data');
          handleNotificationNavigation(data);
        } catch (e) {
          print('Error parsing notification payload: $e');
        }
      }
    },
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");

  if (message.notification == null) {
    return;
  }
  String imageUrl = message.notification!.android?.imageUrl ??
      message.notification!.apple?.imageUrl ??
      message.notification!.android?.imageUrl ??
      "";
  showNotification(
      message.notification!.title, message.notification!.body, imageUrl);
}

void checkForInitialMessage() async {
  print('Checking for initial message');
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  print('Initial message: $initialMessage');

  if (initialMessage != null) {
    // Handle the notification that opened the app
    print('App launched by a notification: ${initialMessage.messageId}');
    print('Notification data: ${initialMessage.data}');
    print('Notification title: ${initialMessage.notification?.title}');
    print('Notification body: ${initialMessage.notification?.body}');
    print(
        'Notification imageUrl: ${initialMessage.notification?.android?.imageUrl}');
    print('Notification sent time: ${initialMessage.sentTime}');
    // Process the initial notification data here
    if (initialMessage != null && initialMessage.data.isNotEmpty) {
      print('App launched by a notification');
      print('Notification data: ${initialMessage.data}');
      handleNotificationNavigation(initialMessage.data);
    }
  }
}

// Clean up the Firebase message handlers
void setupFirebaseMessaging() {
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    if (message.notification != null) {
      showNotification(
        message.notification!.title,
        message.notification!.body,
        message.notification?.android?.imageUrl ?? "",
      );
    }
  });

  // Handle when the app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification opened app from background state');
    if (message.data.isNotEmpty) {
      print('Notification data: ${message.data}');
      handleNotificationNavigation(message.data);
    }
  });
}

void handleNotificationNavigation(Map<String, dynamic> data) {
  print('Handling notification navigation: $data');
  String? type = data['type'];
  print('event id: ${data['title']}');

  // Ensure we're in a valid context before navigating
  if (MyApp.navigatorKey.currentContext == null) {
    print('No valid context for navigation');
    return;
  }

  switch (type) {
    case 'event':
      Navigator.push(
        MyApp.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => NotificationMapScreen(
            notificationData: {'eventId': data['title']},
          ),
        ),
      );
      break;
    case 'score':
      if (data['payload'] != null) {
        var provider = Provider.of<NewsFeedProvider>(
          MyApp.navigatorKey.currentContext!,
          listen: false,
        );
        provider.updateHazardData(
          MyApp.navigatorKey.currentContext!,
          jsonDecode(data['payload']!),
        );
      }
      break;
    default:
      print('Unknown notification type: $type');
  }
}

Future<void> initFCM(String userId) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      SharedPreferenceService.saveFcmToken(token);
      bool isSubscribed =
          await SharedPreferenceService.getNotificationSubscription();

      if (!isSubscribed) {
        // Call the subscription API
        bool success = await _subscribeToNotifications(userId, token);

        if (success) {
          SharedPreferenceService.saveNotificationSubscription(true);
          print('Subscribed to topic: general');
        }
      } else {
        print('Already subscribed to notifications');
      }
    }
  } else {
    print('User declined or has not accepted permission');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('onMessage received: ${message.messageId}');
    print('Foreground message received: ${message.notification?.title}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');
    print('Message sent time: ${message.sentTime}');
    print('Message ttl: ${message.ttl}');
    print('Message collapse key: ${message.collapseKey}');
    print('Message messageId: ${message.messageId}');
    print('Message messageType: ${message.messageType}');
    print('Message from: ${message.from}');

    if (message.notification != null) {
      showNotification(
        message.notification!.title,
        message.notification!.body,
        message.notification?.android?.imageUrl ?? "",
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification opened app');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');
    print('Message sent time: ${message.sentTime}');
    print('Message ttl: ${message.ttl}');
    print('Message collapse key: ${message.collapseKey}');
    print('Message messageId: ${message.messageId}');
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app');
      if (message.data.isNotEmpty) {
        print('Notification data: ${message.data}');
        handleNotificationNavigation(message.data);
      }
    });
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<bool> _subscribeToNotifications(String userId, String token) async {
  try {
    var url = Uri.parse('${AppConstant.SUBSCRIBE_NOTIFICATION}');
    var body = jsonEncode({
      'user_id': userId,
      'topic': 'general',
      'mobile_token': token,
    });

    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      print('Successfully subscribed to notification');
      return true;
    } else {
      print('Failed to subscribe: ${response.body}');
      return false;
    }
  } catch (error) {
    print('Error subscribing to notifications: $error');
    return false;
  }
}

Future<void> showNotification(
    String? title, String? body, String? imageUrl) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'your_channel_id_test_1',
    'your_channel_name_test_1',
    description: 'This is your channel description',
    importance: Importance.high,
  );

  // Create the notification payload
  final Map<String, dynamic> payload = {
    'type': 'event', // Or whatever type you need
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
  };

  AndroidNotificationDetails androidPlatformChannelSpecifics;

  // If imageUrl is not null or empty, download the image
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      print('Downloading image for notification: $imageUrl');
      final http.Response response = await http.get(Uri.parse(imageUrl));

      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/notification_image.jpg';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print('Image downloaded and saved at: $filePath');

      final BigPictureStyleInformation bigPicture = BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath),
        largeIcon: const FilePathAndroidBitmap('ic_launcher'),
        contentTitle: title,
        summaryText: body,
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      );

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id_test_1',
        'your_channel_name_test_1',
        icon: 'ic_launcher',
        styleInformation: bigPicture,
        importance: Importance.max,
        priority: Priority.high,
      );
    } catch (e) {
      print('Error downloading image: $e');
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id_test_1',
        'your_channel_name_test_1',
        icon: 'ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
      );
    }
  } else {
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id_test_1',
      'your_channel_name_test_1',
      icon: 'ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  // Ensure the channel is created
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: jsonEncode(payload),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  initializeNotifications();
  setupFirebaseMessaging();

  String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  // await initFCM(userId);
  // Check if the app was opened by a notification
  checkForInitialMessage();

  final themeProvider =
      ThemeProvider(AppThemes.darkTheme); // Default to dark theme
  await themeProvider.loadTheme(); // Load the saved theme

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('ja'),
        Locale('zh')
      ],
      path: 'assets/translations',
      // Path to translation files
      fallbackLocale: Locale('en'),
      saveLocale: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthNotifier()),
          ChangeNotifierProvider(
              create: (_) => ThemeProvider(AppThemes.darkTheme)),
          ChangeNotifierProvider(create: (_) => CompanyProvider()),
          ChangeNotifierProvider(create: (_) => FeatureProvider()),
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider(create: (_) => EmailProvider()),
          ChangeNotifierProvider(create: (_) => EmployeeProvider()),
          ChangeNotifierProvider(create: (_) => VerificationProvider()),
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => ConnectionsProvider()),
          ChangeNotifierProvider(create: (_) => CorporateProvider()),
          ChangeNotifierProvider(create: (_) => NonCorporateProvider()),
          ChangeNotifierProvider(create: (_) => AccountListProvider()),
          ChangeNotifierProvider(create: (_) => SubAccountListProvider()),
          ChangeNotifierProvider(create: (_) => SOVListProvider()),
          ChangeNotifierProvider(create: (_) => LocationListProvider()),
          ChangeNotifierProvider(create: (_) => LocationProfileProvider()),
          ChangeNotifierProvider(create: (_) => UploadSovProvider()),
          ChangeNotifierProvider(create: (_) => JobMonitoringProvider()),
          ChangeNotifierProvider(create: (_) => MyLocationListProvider()),
          ChangeNotifierProvider(create: (_) => DrawerSelectionProvider()),
          ChangeNotifierProvider(create: (_) => ConfigurationProvider()),
          ChangeNotifierProvider(create: (_) => NewsFeedProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        print(
            'themeProvider.getTheme.brightness: ${themeProvider.getTheme.brightness}');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          title: 'Risk Sphere',
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: themeProvider.getTheme,
          darkTheme: ThemeData(
            colorSchemeSeed: AppColors.primaryMain,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          // Define your dark theme here
          themeMode: themeProvider.getTheme.brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: SplashScreen(),
        );
      },
    );
  }
}
