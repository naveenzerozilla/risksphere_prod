import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:RiskSphere/design_system/app_themes.dart';
import 'package:RiskSphere/firebase_options.dart';
import 'package:RiskSphere/screens/onboarding/splash_screen.dart';
import 'package:RiskSphere/utils/api_constants.dart';
import 'package:RiskSphere/utils/http_client.dart';
import 'package:RiskSphere/utils/global_imports.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
import 'package:RiskSphere/providers/app_providers.dart';
import 'package:RiskSphere/service/push_notification_service.dart';
import 'package:RiskSphere/service/deep_link_service.dart';

late PerformanceHttpClient httpClient;
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run essential initializations concurrently to unblock the first frame faster
  await Future.wait([
    dotenv.load(fileName: ".env"),
    EasyLocalization.ensureInitialized(),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      if (kDebugMode) {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      }
    }).catchError((e) {
      debugPrint(' Firebase init error: $e');
    }),
  ]);

  // Launch non-blocking background initializations
  _initializeDeferredServices();

  http.runWithClient(
    () => runApp(
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
        child: const AppLifecycleManager(),
      ),
    ),
    () => PerformanceHttpClient(),
  );
}

/// Runs initializations that are not strictly required for the first frame
void _initializeDeferredServices() {
  Future.microtask(() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
      debugPrint(' AppCheck activated');
    } catch (e) {
      debugPrint(' AppCheck activation error: $e');
    }

    try {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      httpClient = PerformanceHttpClient();
      bool isEnabled = await FirebasePerformance.instance.isPerformanceCollectionEnabled();
      debugPrint(' Firebase Performance isEnabled: $isEnabled');
    } catch (e) {
      debugPrint(' Performance error: $e');
    }

    // Initialize Push Notifications
    PushNotificationService.initializeNotifications();

    try {
      Stripe.publishableKey = AppConstant.Stripe_prod;
      await Stripe.instance.applySettings();
      debugPrint(' Stripe initialized');
    } catch (e, stackTrace) {
      debugPrint(' Stripe initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  });
}

class AppLifecycleManager extends StatefulWidget {
  const AppLifecycleManager({super.key});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DeepLinkService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle lifecycle changes if needed
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

    return MultiProvider(
      providers: AppProviders.allProviders,
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
            navigatorObservers: [routeObserver],
            home: GlobalBackHandler(
              child: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
