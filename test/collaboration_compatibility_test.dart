import 'dart:convert';

import 'package:employee_manager/config/pocketbase_config.dart';
import 'package:employee_manager/data/employee_repository.dart';
import 'package:employee_manager/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketbase/pocketbase.dart';

import 'auth_test_support.dart';

void main() {
  for (final entry in {
    Employee.provincialCollaboration: 'معارف جنگ و روساء گروه های استانی',
    'استاد': 'اساتید',
    'استاد پیشکسوت': 'اساتید پیشکسوت',
  }.entries) {
    for (final creating in [false, true]) {
      test(
        '${creating ? 'create' : 'update'} retries ${entry.key} on old server',
        () async {
          final requests = <Map<String, dynamic>>[];
          final client = _client((request) async {
            if (request.method == 'GET') return _reply(_record(entry.value));
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            requests.add(body);
            if (requests.length == 1) {
              return _reply({
                'data': {
                  'collaboration_type': {'code': 'validation_in_invalid'},
                },
              }, status: 400);
            }
            return _reply(_record(entry.value));
          });
          final repository = EmployeeRepository(client);
          final employee = _employee(entry.key, creating: creating);
          final saved = creating
              ? await repository.createEmployee(employee)
              : await repository.updateEmployee(employee);
          expect(requests.length, 2);
          expect(requests.first['collaboration_type'], entry.key);
          expect(requests.last['collaboration_type'], entry.value);
          expect(requests.last['job_title'], 'سرهنگ');
          expect({
            ...requests.first,
            'collaboration_type': entry.value,
          }, requests.last);
          expect(saved.collaborationType, entry.key);
          expect(saved.jobTitle, 'سرهنگ');
        },
      );
    }
  }

  test('migrated server accepts current option without retry', () async {
    var calls = 0;
    final repository = EmployeeRepository(
      _client((request) async {
        calls++;
        expect(jsonDecode(request.body)['collaboration_type'], 'استاد');
        return _reply(_record('استاد'));
      }),
    );
    await repository.updateEmployee(_employee('استاد'));
    expect(calls, 1);
  });

  test('unrelated validation does not retry', () async {
    var calls = 0;
    final repository = EmployeeRepository(
      _client((_) async {
        calls++;
        return _reply({
          'data': {
            'job_title': {'code': 'validation_required'},
          },
        }, status: 400);
      }),
    );
    await expectLater(
      repository.updateEmployee(_employee('استاد')),
      throwsA(isA<EmployeeRepositoryException>()),
    );
    expect(calls, 1);
  });
}

PocketBase _client(Future<http.Response> Function(http.Request) handler) =>
    PocketBase(
      'http://example.test',
      httpClientFactory: () => MockClient(handler),
      authStore: AuthStore()
        ..save(
          testToken(),
          RecordModel.fromJson({
            'id': 'testuser0000001',
            'collectionName': PocketBaseConfig.authCollection,
            'role': 'admin',
          }),
        ),
    );

http.Response _reply(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _record(String type) => {
  'id': 'employee0000001',
  'hire_date': '2010-03-21 00:00:00.000Z',
  'job_title': 'سرهنگ',
  'collaboration_type': type,
};

Employee _employee(String type, {bool creating = false}) => Employee(
  id: creating ? '' : 'employee0000001',
  firstName: 'علی',
  lastName: 'احمدی',
  nationalCode: '0012345678',
  mobile: '09123456789',
  personnelCode: '0012',
  jobTitle: 'سرهنگ',
  collaborationType: type,
  hireDate: DateTime(2010, 3, 21),
  isActive: true,
);
