class PocketBaseConfig {
  PocketBaseConfig._();

  static const baseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  static const employeesCollection = 'employees';
  static const authCollection = 'Auth';
}
