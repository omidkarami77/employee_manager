class PocketBaseConfig {
  PocketBaseConfig._();

  static const baseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://192.168.1.200:8090',
  );

  static const employeesCollection = 'employees';
  static const authCollection = 'auth';
}
