import 'dart:convert';
import 'dart:io';
import 'package:RiskSphere/providers/payment_provider.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/screens/onboarding/splash_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'design_system/app_themes.dart';
import 'package:RiskSphere/providers/connectivity_provider.dart';
import 'package:RiskSphere/providers/data_list_parameters.dart';
import 'package:RiskSphere/firebase_options.dart';
import 'package:RiskSphere/providers/configuration_provider.dart';
import 'package:RiskSphere/providers/drawer_selection_provider.dart';
import 'package:RiskSphere/providers/job_monitoring_provier.dart';
import 'package:RiskSphere/providers/my_location_list_provider.dart';
import 'package:RiskSphere/providers/news_feed_provider.dart';
import 'package:RiskSphere/screens/event/notification_map_screen.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:RiskSphere/providers/account_list_provider.dart';
import 'package:RiskSphere/providers/auth_provider.dart';
import 'package:RiskSphere/providers/company_provider.dart';
import 'package:RiskSphere/providers/connections_provider.dart';
import 'package:RiskSphere/providers/corporate_user_provider.dart';
import 'package:RiskSphere/providers/dashboard_provider.dart';
import 'package:RiskSphere/providers/email_provider.dart';
import 'package:RiskSphere/providers/employee_provider.dart';
import 'package:RiskSphere/providers/feature_provider.dart';
import 'package:RiskSphere/providers/location_list_provider.dart';
import 'package:RiskSphere/providers/location_profile_provider.dart';
import 'package:RiskSphere/providers/non_corporate_user_Provider.dart';
import 'package:RiskSphere/providers/role_provider.dart';
import 'package:RiskSphere/providers/sov_list_provider.dart';
import 'package:RiskSphere/providers/sub_account_list_provider.dart';
import 'package:RiskSphere/providers/upload_sov_provider.dart';
import 'package:RiskSphere/providers/user_profile_provider.dart';
import 'package:RiskSphere/providers/verification_provider.dart';
import 'package:RiskSphere/service/shared_preference_service.dart';
import 'package:provider/provider.dart';
import 'design_system/primitives/app_colors.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    showNotification(
      message.notification!.title,
      message.notification!.body,
      message.notification?.android?.imageUrl ?? "",
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  Stripe.publishableKey =
      'pk_test_51RWO7ARtw6KU9heKwCpClVPqlQ9UettHfLjbYdSUpWnR2fAf39IvocEIWlxMRve7iIxmHOcDfdr7Gao00OiGhzxN00l4zEuUzR';
  await Stripe.instance.applySettings();
  initializeNotifications();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: AppLifecycleManager(),
      // child: MyApp(),
    ),
  );
}

class AppLifecycleManager extends StatefulWidget {
  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔁 App lifecycle changed: $state");

    // Handle all possible states including 'hidden'
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed
        break;
      case AppLifecycleState.inactive:
        // App inactive
        break;
      case AppLifecycleState.paused:
        // App paused
        break;
      case AppLifecycleState.detached:
        // App detached (usually on iOS)
        break;
      case AppLifecycleState.hidden:
        // App is hidden (e.g., background but not closed)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(); // original root widget
  }
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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
        ChangeNotifierProvider(create: (_) => SubaccountParameterProvider()),
        ChangeNotifierProvider(create: (_) => UploadSovProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
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
      ),
    );
  }
}

void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          final data = jsonDecode(response.payload!);
          handleNotificationNavigation(data);
        } catch (e) {
          print('Error parsing payload: $e');
        }
      }
    },
  );
}

Future<void> showNotification(
    String? title, String? body, String? imageUrl) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'your_channel_id_test_1',
    'your_channel_name_test_1',
    description: 'High importance notifications',
    importance: Importance.high,
  );

  AndroidNotificationDetails androidDetails;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final filePath =
          '${(await getApplicationDocumentsDirectory()).path}/noti_image.jpg';
      final file = File(filePath)..writeAsBytesSync(response.bodyBytes);

      androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        styleInformation: BigPictureStyleInformation(
          FilePathAndroidBitmap(file.path),
          contentTitle: title,
          summaryText: body,
        ),
        importance: Importance.max,
        priority: Priority.high,
      );
    } catch (e) {
      androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.high,
      );
    }
  } else {
    androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    NotificationDetails(android: androidDetails),
    payload: jsonEncode({'type': 'event', 'title': title}),
  );
}

void handleNotificationNavigation(Map<String, dynamic> data) {
  final context = MyApp.navigatorKey.currentContext;
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

Future<void> initFCM(String userId) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings =
      await messaging.requestPermission(alert: true, badge: true, sound: true);

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      SharedPreferenceService.saveFcmToken(token);
      bool isSubscribed =
          await SharedPreferenceService.getNotificationSubscription();
      if (isSubscribed) {
        await _subscribeToNotifications(userId, token);
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          message.notification!.title,
          message.notification!.body,
          message.notification?.android?.imageUrl ?? "",
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        handleNotificationNavigation(message.data);
      }
    });

    checkForInitialMessage();
  }
}

void checkForInitialMessage() async {
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage?.data.isNotEmpty ?? false) {
    handleNotificationNavigation(initialMessage!.data);
  }
}

Future<bool> _subscribeToNotifications(String userId, String token) async {
  try {
    final url = Uri.parse(AppConstant.SUBSCRIBE_NOTIFICATION);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'user_id': userId, 'topic': 'general', 'mobile_token': token}),
    );
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
