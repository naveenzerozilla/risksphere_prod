
import 'dart:io';

import 'package:green/providers/drawer_selection_provider.dart';
import 'package:green/providers/job_monitoring_provier.dart';
import 'package:green/providers/my_location_list_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:green/providers/account_list_provider.dart';
import 'package:green/providers/auth_provider.dart';
import 'package:green/providers/company_provider.dart';
import 'package:green/providers/connections_provider.dart';
import 'package:green/providers/corporate_user_provider.dart';
import 'package:green/providers/dashboard_provider.dart';
import 'package:green/providers/email_provider.dart';
import 'package:green/providers/employee_provider.dart';
import 'package:green/providers/feature_provider.dart';
import 'package:green/providers/location_list_provider.dart';
import 'package:green/providers/location_profile_provider.dart';
import 'package:green/providers/non_corporate_user_Provider.dart';
import 'package:green/providers/role_provider.dart';
import 'package:green/providers/sov_list_provider.dart';
import 'package:green/providers/sub_account_list_provider.dart';
import 'package:green/providers/upload_sov_provider.dart';
import 'package:green/providers/user_profile_provider.dart';
import 'package:green/providers/verification_provider.dart';
import 'package:green/service/shared_preference_service.dart';
import 'package:provider/provider.dart';

import 'design_system/app_themes.dart';
import 'design_system/primitives/app_colors.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/splash_screen.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");

  if (message.notification == null) {
    return;
  }
  String imageUrl = message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl ?? message.notification!.android?.imageUrl ?? "";
  showNotification(message.notification!.title, message.notification!.body, imageUrl);
}

void checkForInitialMessage() async {
  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // Handle the notification that opened the app
    print('App launched by a notification: ${initialMessage.messageId}');
    // Process the initial notification data here
  }
}


Future<void> initFCM() async {
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
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  // getting token
  String? token = await messaging.getToken();
  print('FCM Token: $token');
  SharedPreferenceService.saveFcmToken(token??"");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification?.body} ${message.notification?.title} ${message.notification?.android?.channelId} ${message.notification?.android?.clickAction} ${message.notification?.android?.color} ${message.notification?.android?.imageUrl} ${message.notification?.android?.link} ${message.notification?.android?.priority} ${message.notification?.android?.smallIcon} ${message.notification?.android?.ticker} ${message.notification?.android?.visibility}  ${message.notification?.android?.sound}  ${message.notification?.android?.visibility}');
    }

    if (message.notification != null) {
      // Show notification using flutter_local_notifications
      print('Showing notification');
      print('Message notification title: ${message.notification!.title}');
      print('Message notification body: ${message.notification!.body}');
      print('Message notification imageUrl: ${message.notification!.android!.imageUrl}');

      if (Platform.isAndroid && message.notification!.android!.imageUrl != null) {
        showNotification(message.notification!.title, message.notification!.body, message.notification?.android?.imageUrl??"");
      } else if (Platform.isIOS && message.notification!.apple!.imageUrl != null) {
        showNotification(message.notification!.title, message.notification!.body, message.notification?.apple?.imageUrl??"");
      } else {
        showNotification(message.notification!.title, message.notification!.body, message.notification?.web?.image??"");
      }
      //showNotification(message.notification!.title, message.notification!.body, message.notification!.android!.imageUrl);
    }
  });






  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await  FirebaseMessaging.instance.subscribeToTopic('test96');

}


Future<void> showNotification(String? title, String? body, String? imageUrl) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'your_channel_id_test_1',
    'your_channel_name_test_1',
    description: 'This is your channel description',
    importance: Importance.high,
  );

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
        FilePathAndroidBitmap(filePath), // Use the saved file path
        largeIcon: const FilePathAndroidBitmap('ic_launcher'),  // Your app icon
        contentTitle: title,
        summaryText: body,
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      );

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id_test_1',
        'your_channel_name_test_1',
        icon: 'ic_launcher',
        styleInformation: bigPicture,  // Attach the big picture style
        importance: Importance.max,
        priority: Priority.high,
      );
    } catch (e) {
      print('Error downloading image: $e');
      // Fallback to a notification without the image if the download fails
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id_test_1',
        'your_channel_name_test_1',
        icon: 'ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
      );
    }
  } else {
    // No imageUrl provided, create a simple notification
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
    0,  // Notification ID
    title,
    body,
    platformChannelSpecifics,
  );
}







void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initFCM();
  // Check if the app was opened by a notification
  checkForInitialMessage();


  final themeProvider = ThemeProvider(AppThemes.darkTheme); // Default to dark theme
  await themeProvider.loadTheme(); // Load the saved theme

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('es'), Locale('fr'), Locale('ja'), Locale('zh')],
      path: 'assets/translations', // Path to translation files
      fallbackLocale: Locale('en'),
      saveLocale: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthNotifier()),
          ChangeNotifierProvider(create: (_) => ThemeProvider(AppThemes.darkTheme)),
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
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        print('themeProvider.getTheme.brightness: ${themeProvider.getTheme.brightness}');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Risk Sphere',
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: themeProvider.getTheme,
          darkTheme:  ThemeData(
            colorSchemeSeed: AppColors.primaryMain,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),// Define your dark theme here
          themeMode: themeProvider.getTheme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: SplashScreen(),
        );
      },
    );
  }
}
