import 'dart:convert';

import 'package:employee_manager/data/auth_repository.dart';
import 'package:employee_manager/models/app_user.dart';
import 'package:pocketbase/pocketbase.dart';

String testToken({bool expired = false}) =>
    'test.${base64Url.encode(utf8.encode(jsonEncode({'exp': DateTime.now().add(Duration(hours: expired ? -1 : 1)).millisecondsSinceEpoch ~/ 1000}))).replaceAll('=', '')}.signature';

RecordModel testUserRecord({String role = 'Admin'}) => RecordModel.fromJson({
  'id': 'testuser0000001',
  'collectionName': 'Auth',
  'name': 'مدیر آزمایشی',
  'email': 'test@example.test',
  'role': role,
});

class MemorySessionStorage implements SessionStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

class TestAuthRepository extends AuthRepository {
  TestAuthRepository({String role = 'Admin'})
    : super(
        PocketBase('http://example.test'),
        storage: MemorySessionStorage(),
      ) {
    client.authStore.save(testToken(), testUserRecord(role: role));
  }
  @override
  Future<AppUser?> restore() async => currentUser;
  @override
  Future<AppUser?> refresh() async => currentUser;
}
