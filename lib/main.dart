import 'dart:convert';
import 'package:RiskSphere/providers/invoice_provider.dart';
import 'package:RiskSphere/providers/payment_provider.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/screens/onboarding/splash_screen.dart';
import 'package:RiskSphere/utils/backgroundhandler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    Stripe.publishableKey =
        'pk_test_51RWO7ARtw6KU9heKwCpClVPqlQ9UettHfLjbYdSUpWnR2fAf39IvocEIWlxMRve7iIxmHOcDfdr7Gao00OiGhzxN00l4zEuUzR';
    await Stripe.instance.applySettings();
  } catch (e, stackTrace) {
    debugPrint('Stripe initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  initializeNotifications();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: AppLifecycleManager(),
    ),
  );
}
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//   } catch (e) {
//     debugPrint('Firebase initialization error: $e');
//   }
//
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   try {
//     Stripe.publishableKey =
//         'pk_test_51RWO7ARtw6KU9heKwCpClVPqlQ9UettHfLjbYdSUpWnR2fAf39IvocEIWlxMRve7iIxmHOcDfdr7Gao00OiGhzxN00l4zEuUzR';
//     await Stripe.instance.applySettings();
//   } catch (e, stackTrace) {
//     debugPrint('Stripe initialization failed: $e');
//     debugPrint('Stack trace: $stackTrace');
//   }
//
//   initializeNotifications();
//
//   runApp(
//     EasyLocalization(
//       supportedLocales: const [Locale('en')],
//       path: 'assets/translations',
//       fallbackLocale: const Locale('en'),
//       child: AppLifecycleManager(),
//     ),
//   );
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   Stripe.publishableKey =
//       'pk_test_51RWO7ARtw6KU9heKwCpClVPqlQ9UettHfLjbYdSUpWnR2fAf39IvocEIWlxMRve7iIxmHOcDfdr7Gao00OiGhzxN00l4zEuUzR';
//   await Stripe.instance.applySettings();
//   initializeNotifications();
//   runApp(
//     EasyLocalization(
//       supportedLocales: const [Locale('en')],
//       path: 'assets/translations',
//       fallbackLocale: const Locale('en'),
//       child: AppLifecycleManager(),
//       // child: MyApp(),
//     ),
//   );
// }

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

    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyApp();
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
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
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
            themeMode: themeProvider.getTheme.brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: GlobalBackHandler(
              child: SplashScreen(),
            ),
            // home: SplashScreen(),
          );
        },
      ),
    );
  }
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        debugPrint('Notification payload: ${response.payload}');
        // Navigate or handle logic if needed
      }
    },
  );
}

Future<void> showNotification(
    String? title, String? body, String? imageUrl) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // must match your channel ID
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

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
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
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      print("Subscribenotification1");
      SharedPreferenceService.saveFcmToken(token);
      bool isSubscribed =
          await SharedPreferenceService.getNotificationSubscription();
      // if (!isSubscribed) {
      //   print("Subscribenotification2");
      await _subscribeToNotifications(userId, token);
      // }
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      print("📩 Foreground message received: ${notification?.title}");

      // Show toast only at top (if this is what you want)
      Fluttertoast.showToast(
        msg: notification?.title ?? "Notification",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 1, // works on some platforms
      );

      // If you want notification instead of toast, comment the above and use this
      // showNotification(notification.title, notification.body, ...);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 Foreground message received: ${message.notification?.title}");
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
    print("Subscribenotification");
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

class CustomToast {
  static void showToast(String title, String message) {
    print("Foreground notifications");
    // Example implementation using Flutter's ScaffoldMessenger
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 20, left: 16, right: 16),
          content: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(message),
              ],
            ),
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }
  }
}
