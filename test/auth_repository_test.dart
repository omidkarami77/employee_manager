import 'dart:async';
import 'dart:convert';

import 'package:employee_manager/data/auth_repository.dart';
import 'package:employee_manager/data/employee_repository.dart';
import 'package:employee_manager/models/employee.dart';
import 'package:employee_manager/state/auth_cubit.dart';
import 'package:employee_manager/state/employees_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketbase/pocketbase.dart';

import 'auth_test_support.dart';

void main() {
  test(
    'login uses PocketBase AuthStore and persists a session without a password',
    () async {
      final storage = MemorySessionStorage();
      final client = makeClient((request) async {
        expect(request.url.path, '/api/collections/Auth/auth-with-password');
        expect(jsonDecode(request.body), {
          'identity': 'test@example.test',
          'password': 'test-password',
        });
        return authResponse();
      });
      final repository = AuthRepository(client, storage: storage);
      final user = await repository.login(
        ' test@example.test ',
        'test-password',
      );
      expect(user.isAdmin, isTrue);
      expect(client.authStore.isValid, isTrue);
      expect(client.authStore.record!.id, user.id);
      expect(storage.value, isNot(contains('test-password')));
      expect(jsonDecode(storage.value!)['record']['role'], 'Admin');
      await repository.logout();
      expect(client.authStore.token, isEmpty);
      expect(client.authStore.record, isNull);
      expect(storage.value, isNull);
    },
  );

  test(
    'restore refreshes the token and reads the current server role',
    () async {
      final storage = MemorySessionStorage()..value = session();
      final repository = AuthRepository(
        makeClient((request) async {
          expect(request.url.path, '/api/collections/Auth/auth-refresh');
          expect(request.headers['authorization'], isNotEmpty);
          return authResponse(role: 'User');
        }),
        storage: storage,
      );
      expect((await repository.restore())!.isAdmin, isFalse);
      expect(jsonDecode(storage.value!)['record']['role'], 'User');
    },
  );

  test('expired, malformed and revoked sessions are cleared', () async {
    for (final stored in ['invalid', session(expired: true), session()]) {
      final storage = MemorySessionStorage()..value = stored;
      final repository = AuthRepository(
        makeClient((_) async => response({}, 401)),
        storage: storage,
      );
      expect(await repository.restore(), isNull);
      expect(repository.currentUser, isNull);
      expect(storage.value, isNull);
    }
  });

  test('unknown roles fail closed and are never persisted', () async {
    final storage = MemorySessionStorage();
    final repository = AuthRepository(
      makeClient((_) async => authResponse(role: 'owner')),
      storage: storage,
    );
    await expectLater(
      repository.login('test@example.test', 'test-password'),
      throwsA(isA<AuthRepositoryException>()),
    );
    expect(repository.currentUser, isNull);
    expect(storage.value, isNull);
  });

  test(
    'bad credentials and connection failures return Persian messages',
    () async {
      for (final code in [400, 429, 500]) {
        final repository = AuthRepository(
          makeClient((_) async => response({}, code)),
          storage: MemorySessionStorage(),
        );
        await expectLater(
          repository.login('test@example.test', 'test-password'),
          throwsA(
            isA<AuthRepositoryException>().having(
              (e) => e.message,
              'message',
              contains(
                code == 400
                    ? 'ایمیل یا رمز'
                    : code == 429
                    ? 'تعداد تلاش'
                    : 'ورود انجام نشد',
              ),
            ),
          ),
        );
      }
      final repository = AuthRepository(
        makeClient((_) async => throw http.ClientException('offline')),
        storage: MemorySessionStorage(),
      );
      await expectLater(
        repository.login('test@example.test', 'test-password'),
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.message,
            'message',
            contains('ارتباط'),
          ),
        ),
      );
    },
  );

  test(
    'cubit does not admit an offline cached session and supports retry',
    () async {
      var offline = true;
      final storage = MemorySessionStorage()..value = session();
      final repository = AuthRepository(
        makeClient((_) async {
          if (offline) throw http.ClientException('offline');
          return authResponse();
        }),
        storage: storage,
      );
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);
      expect(cubit.state.status, AuthStatus.initial);
      final restoring = cubit.restore();
      expect(cubit.state.status, AuthStatus.loading);
      await restoring;
      expect(cubit.state.status, AuthStatus.error);
      expect(cubit.canManageEmployees, isFalse);
      expect(storage.value, isNotNull);
      offline = false;
      await cubit.restore();
      expect(cubit.state.status, AuthStatus.authenticated);
      await cubit.logout();
      expect(cubit.state.status, AuthStatus.unauthenticated);
    },
  );

  test('duplicate login requests are ignored and logout clears authenticated state', () async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final cubit = AuthCubit(
      AuthRepository(
        makeClient((_) {
          calls++;
          return pending.future;
        }),
        storage: MemorySessionStorage(),
      ),
    );
    addTearDown(cubit.close);
    final login = cubit.login('test@example.test', 'test-password');
    await cubit.login('test@example.test', 'test-password');
    pending.complete(authResponse());
    await login;
    expect(calls, 1);
    expect(cubit.canManageEmployees, isTrue);
    await cubit.logout();
    expect(cubit.canManageEmployees, isFalse);
  });

  test('repository and controller both reject non-admin mutations without HTTP calls', () async {
    var calls = 0;
    final client = makeClient((_) async {
      calls++;
      return response({});
    });
    client.authStore.save(testToken(), testUserRecord(role: 'User'));
    final repository = EmployeeRepository(client);
    final controller = EmployeesController(repository);
    addTearDown(controller.dispose);
    final employee = Employee(
      id: 'employee0000001',
      firstName: '',
      lastName: '',
      nationalCode: '',
      mobile: '',
      personnelCode: '',
      jobTitle: '',
      department: '',
      hireDate: DateTime(2020),
      isActive: true,
    );
    for (final operation in [
      () => repository.createEmployee(employee),
      () => repository.updateEmployee(employee),
      () => repository.deleteEmployee(employee.id),
      () => controller.saveEmployee(employee),
      () => controller.deleteEmployee(employee),
    ]) {
      await expectLater(
        operation(),
        throwsA(isA<EmployeeRepositoryException>()),
      );
    }
    client.authStore.clear();
    await expectLater(
      repository.createEmployee(employee),
      throwsA(isA<EmployeeRepositoryException>()),
    );
    await expectLater(
      repository.getEmployees(),
      throwsA(isA<EmployeeRepositoryException>()),
    );
    expect(calls, 0);
  });
}

PocketBase makeClient(Future<http.Response> Function(http.Request) handler) =>
    PocketBase(
      'http://example.test',
      httpClientFactory: () => MockClient(handler),
    );

http.Response response(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response authResponse({String role = 'Admin'}) => response({
  'token': testToken(),
  'record': testUserRecord(role: role).toJson(),
});

String session({bool expired = false}) => jsonEncode({
  'token': testToken(expired: expired),
  'record': testUserRecord().toJson(),
});
