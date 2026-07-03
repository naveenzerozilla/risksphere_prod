import 'package:RiskSphere/providers/data_list_parameters.dart';
import 'package:RiskSphere/screens/onboarding/login_screen.dart';
import 'package:RiskSphere/utils/http_client.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import '../../utils/global_imports.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'design_system/app_themes.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

late PerformanceHttpClient httpClient;
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(' Firebase initialized');

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  } catch (e) {
    debugPrint(' Firebase init error: $e');
  }

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
    debugPrint(' AppCheck activated');
  } catch (e) {
    debugPrint(' AppCheck activation error: $e');
  }

  try {
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    httpClient = PerformanceHttpClient();
    bool isEnabled =
        await FirebasePerformance.instance.isPerformanceCollectionEnabled();
    debugPrint(' Firebase Performance isEnabled: $isEnabled');
  } catch (e) {
    debugPrint(' Performance error: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    Stripe.publishableKey = AppConstant.Stripe_prod;

    await Stripe.instance.applySettings();
    debugPrint(' Stripe initialized');
  } catch (e, stackTrace) {
    debugPrint(' Stripe initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  initializeNotifications();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('ja'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: AppLifecycleManager(),
    ),
  );
}

class AppLifecycleManager extends StatefulWidget {
  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleDeepLink();
    _handleSharedGoogleMapsLink();
  }

  void _handleSharedGoogleMapsLink() {
    FlutterSharingIntent.instance.getInitialSharing().then((value) {
      debugPrint(' getInitialSharing called, count: ${value.length}');
      if (value.isNotEmpty) {
        final text = value.first.value ?? '';
        debugPrint(' Shared text: $text');
        PendingSharedLocation.sharedText = text;
        PendingSharedLocation.wasLaunchedViaShare = true;
      } else {
        debugPrint(' No shared text received');
      }
    });

    FlutterSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        final text = value.first.value ?? '';
        debugPrint(' Warm share: $text');
        _extractLatLngAndNavigate(text);
      }
    });
  }

  void _extractLatLngAndNavigate(String sharedText) async {
    double? lat;
    double? lng;

    String resolvedUrl = sharedText.trim();
    debugPrint('Original shared URL: $resolvedUrl');

    if (resolvedUrl.contains('goo.gl') || resolvedUrl.contains('maps.app')) {
      try {
        final response = await http.get(
          Uri.parse(resolvedUrl),
          headers: {'User-Agent': 'Mozilla/5.0'},
        );
        resolvedUrl = response.request?.url.toString() ?? resolvedUrl;
        debugPrint('Resolved URL: $resolvedUrl');
      } catch (e) {
        debugPrint('Failed to resolve URL: $e');
      }
    }

    final uri = Uri.tryParse(resolvedUrl);
    if (uri != null) {
      final q = uri.queryParameters['q'];
      if (q != null && q.contains(',')) {
        final parts = q.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }

      if (lat == null) {
        final match =
            RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(resolvedUrl);
        if (match != null) {
          lat = double.tryParse(match.group(1) ?? '');
          lng = double.tryParse(match.group(2) ?? '');
        }
      }
    }

    debugPrint('Extracted → lat: $lat, lng: $lng');

    if (lat == null || lng == null) {
      debugPrint('Could not extract lat/lng from shared URL');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final accountId = await SharedPreferenceService.getDefaultAccountID() ?? '';

    final subAccountId =
        await SharedPreferenceService.getDefaultSubAccountID() ?? '';
    final accountName =
        await SharedPreferenceService.GetDefaultAccountName() ?? '';
    final subAccountName =
        await SharedPreferenceService.GetDefaultSUBAccountName() ?? '';

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AddLocationScreen(
            accountId: accountId,
            subAccountId: subAccountId,
            sovId: '',
            locationId: '',
            accountName: (accountName.isNotEmpty)
                ? accountName
                : 'Default Account',
            subAccountName:
                (subAccountName.isNotEmpty)
                    ? subAccountName
                    : 'Default Subaccount',
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleDeepLink() async {
    _appLinks = AppLinks();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = await _appLinks.getInitialLink();
      if (uri != null && uri.host == 'app.risksphere.ai') {
        _routeFromDeepLink(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'app.risksphere.ai') {
        _routeFromDeepLink(uri);
      }
    });
  }

  void _routeFromDeepLink(Uri uri) async {
    final user = FirebaseAuth.instance.currentUser;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (user != null) {
      PendingDeepLink.isDeepLinkPending = true;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AddLocationScreen(
            accountId: '',
            subAccountId: '',
            sovId: '',
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(" App lifecycle changed: $state");

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
  // static final GlobalKey<NavigatorState> navigatorKey =
  //     GlobalKey<NavigatorState>();
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
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
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

Future<void> initFCM(String userId) async {
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

    debugPrint(' Token null check: ${token == null ? "NULL " : "HAS VALUE "}');

    if (token != null) {
      SharedPreferenceService.saveFcmToken(token);
      debugPrint(' Calling _subscribeToNotifications with userId: $userId');
      final result = await _subscribeToNotifications(userId, token);
      debugPrint(' _subscribeToNotifications result: $result');
    } else {
      debugPrint(' Token is null, skipping subscribe');
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

class CustomToast {
  static void showToast(String title, String message) {
    print("Foreground notifications");
    final context = navigatorKey.currentContext;
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

class PendingDeepLink {
  static bool isDeepLinkPending = false;
}

class PendingSharedLocation {
  static String? sharedText;
  static bool wasLaunchedViaShare = false;

  static bool get hasSharedText => sharedText != null && sharedText!.isNotEmpty;
}
