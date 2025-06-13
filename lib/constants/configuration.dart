import 'environment.dart';

class Configuration {
  static String environment = Environment.dev; // Set default environment

  static const Map<String, String> projectIds = {
    Environment.dev: 'project-green-r5-1-dev', //'project-green-f4d78',//
    Environment.qa:  'project-green-r5-1-qa',//'project-green-dev-429104', // 'project-green-r5-1-qa',
    Environment.prod: 'prod-project-id',
  };

  static String get projectId => projectIds[environment]!;
}
