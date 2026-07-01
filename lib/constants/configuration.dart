import 'environment.dart';

class Configuration {
  static String environment = Environment.prod;

  static const Map<String, String> projectIds = {
    Environment.dev: 'project-green-r5-1-dev',
    Environment.qa: 'project-green-r5-1-qa',
    Environment.prod: 'project-green-prod',
  };

  static String get projectId => projectIds[environment]!;
}
