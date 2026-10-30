import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:RiskSphere/design_system/app_themes.dart';
import 'package:RiskSphere/providers/theme_provider.dart';
// Note: We need to import all the necessary providers here.
import '../utils/global_imports.dart'; // Contains all provider exports usually
import 'package:RiskSphere/providers/data_list_parameters.dart';

class AppProviders {
  static List<SingleChildWidget> get allProviders => [
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
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ];
}
