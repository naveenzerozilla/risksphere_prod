import 'environment.dart';

class Configuration {
  static String environment = Environment.qa;

  static const Map<String, String> projectIds = {
    Environment.dev: 'risksphere-qa',
    Environment.qa: 'risksphere-qa',
    Environment.prod: 'risksphere-prod',
  };

  static String get projectId => projectIds[environment]!;
}
