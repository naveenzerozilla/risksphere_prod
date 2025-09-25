import 'environment.dart';

class Configuration {
  static String environment = Environment.qa; // Set default environment

  static const Map<String, String> projectIds = {
    Environment.dev: 'project-green-r5-1-dev',
    //'project-green-f4d78',//
    Environment.qa: 'project-green-r5-1-qa',
    //'project-green-dev-429104', // 'project-green-r5-1-qa',
    Environment.prod: 'project-green-prod',
  };

  static String get projectId => projectIds[environment]!;
}
