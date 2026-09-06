import 'dart:async';
import 'dart:convert';

import 'package:employee_manager/data/employee_repository.dart';
import 'package:employee_manager/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  group('EmployeeRecordMapper', () {
    test('reads every field and keeps stored calendar dates', () {
      final employee = EmployeeRecordMapper.fromRecord(
        RecordModel.fromJson(
          _record(endDate: '2024-04-02 00:00:00.000Z', isActive: false),
        ),
      );

      expect(employee.id, 'employee0000001');
      expect(employee.firstName, 'علی');
      expect(employee.lastName, 'احمدی');
      expect(employee.nationalCode, '0012345678');
      expect(employee.mobile, '09123456789');
      expect(employee.personnelCode, '0012');
      expect(employee.jobTitle, 'کارشناس');
      expect(employee.department, 'اداری');
      expect(employee.hireDate, DateTime(2010, 3, 21));
      expect(employee.endDate, DateTime(2024, 4, 2));
      expect(employee.isActive, isFalse);
    });

    test('accepts empty and null optional dates', () {
      for (final endDate in ['', null]) {
        final employee = EmployeeRecordMapper.fromRecord(
          RecordModel.fromJson(_record(endDate: endDate)),
        );
        expect(employee.endDate, isNull);
      }
    });

    test(
      'writes date components at UTC midnight and omits record metadata',
      () {
        final body = EmployeeRecordMapper.toBody(
          _employee(
            hireDate: DateTime(2024, 3, 20, 23, 59),
            endDate: DateTime(2024, 3, 21, 1),
            isActive: false,
          ),
        );

        expect(body['hire_date'], '2024-03-20T00:00:00.000Z');
        expect(body['end_date'], '2024-03-21T00:00:00.000Z');
        expect(body['national_code'], '0012345678');
        expect(body['personnel_code'], '0012');
        expect(body['is_active'], isFalse);
        expect(body, isNot(contains('id')));
        expect(body, isNot(contains('collectionId')));
      },
    );
  });

  group('EmployeeRepository', () {
    test('loads all pages from the employees collection', () async {
      final pages = <int>[];
      final repository = _repository((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/collections/employees/records');
        expect(request.headers, isNot(contains('authorization')));
        final page = int.parse(request.url.queryParameters['page']!);
        final perPage = int.parse(request.url.queryParameters['perPage']!);
        pages.add(page);
        return _response({
          'page': page,
          'perPage': perPage,
          'items': page == 1
              ? List.generate(perPage, (index) => _record(id: 'record$index'))
              : [_record(id: 'lastrecord')],
        });
      });

      final employees = await repository.getEmployees();

      expect(pages, [1, 2]);
      expect(employees.length, 1001);
      expect(employees.last.id, 'lastrecord');
    });

    test('returns an empty list when the collection has no records', () async {
      final repository = _repository(
        (_) async => _response({'page': 1, 'perPage': 1000, 'items': []}),
      );

      expect(await repository.getEmployees(), isEmpty);
    });

    test(
      'creates with snake_case fields and returns the server record',
      () async {
        final repository = _repository((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/collections/employees/records');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {
            'first_name': 'علی',
            'last_name': 'احمدی',
            'national_code': '0012345678',
            'mobile': '09123456789',
            'personnel_code': '0012',
            'job_title': 'کارشناس',
            'department': 'اداری',
            'hire_date': '2010-03-21T00:00:00.000Z',
            'end_date': '',
            'is_active': true,
          });
          return _response(_record(id: 'server000000001'));
        });

        final result = await repository.createEmployee(
          _employee(id: 'local-id'),
        );

        expect(result.id, 'server000000001');
        expect(result.firstName, 'علی');
      },
    );

    test('updates the record by id and clears the previous end date', () async {
      final repository = _repository((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.path,
          '/api/collections/employees/records/employee0000001',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['end_date'], '');
        expect(body['is_active'], isTrue);
        expect(body, isNot(contains('id')));
        return _response(_record());
      });

      final result = await repository.updateEmployee(_employee());

      expect(result.id, 'employee0000001');
      expect(result.endDate, isNull);
    });

    test('deletes the real record endpoint', () async {
      var requests = 0;
      final repository = _repository((request) async {
        requests++;
        expect(request.method, 'DELETE');
        expect(
          request.url.path,
          '/api/collections/employees/records/employee0000001',
        );
        return http.Response('', 204);
      });

      await repository.deleteEmployee('employee0000001');

      expect(requests, 1);
    });

    test('translates database uniqueness errors for both codes', () async {
      final repository = _repository(
        (_) async => _response({
          'status': 400,
          'message': 'Failed to create record.',
          'data': {
            'national_code': {'code': 'validation_not_unique'},
            'personnel_code': {'code': 'validation_not_unique'},
          },
        }, status: 400),
      );

      await expectLater(
        repository.createEmployee(_employee()),
        throwsA(
          isA<EmployeeRepositoryException>().having(
            (error) => error.fieldErrors,
            'field errors',
            {
              'national_code': 'کد ملی تکراری است.',
              'personnel_code': 'کد پرسنلی تکراری است.',
            },
          ),
        ),
      );
    });

    test('translates connection failures into a Persian error', () async {
      final repository = _repository((_) async {
        throw http.ClientException('Connection refused');
      });

      await expectLater(
        repository.getEmployees(),
        throwsA(
          isA<EmployeeRepositoryException>().having(
            (error) => error.message,
            'message',
            contains('ارتباط با پایگاه داده برقرار نشد'),
          ),
        ),
      );
    });

    test(
      'reports access errors without presenting an empty collection',
      () async {
        final repository = _repository(
          (_) async => _response({
            'status': 403,
            'message': 'Only superusers can perform this action.',
            'data': {},
          }, status: 403),
        );

        await expectLater(
          repository.getEmployees(),
          throwsA(
            isA<EmployeeRepositoryException>().having(
              (error) => error.message,
              'message',
              'دسترسی به اطلاعات کارکنان مجاز نیست.',
            ),
          ),
        );
      },
    );

    test('times out an unresponsive request', () async {
      final response = Completer<http.Response>();
      final repository = _repository(
        (_) => response.future,
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        repository.getEmployees(),
        throwsA(
          isA<EmployeeRepositoryException>().having(
            (error) => error.message,
            'message',
            contains('ارتباط با پایگاه داده برقرار نشد'),
          ),
        ),
      );
      response.complete(_response({'page': 1, 'perPage': 1000, 'items': []}));
    });

    test(
      'reports malformed required dates rather than inventing dates',
      () async {
        final repository = _repository(
          (_) async => _response({
            'page': 1,
            'perPage': 1000,
            'items': [
              {..._record(), 'hire_date': '2024-02-31 00:00:00.000Z'},
            ],
          }),
        );

        await expectLater(
          repository.getEmployees(),
          throwsA(
            isA<EmployeeRepositoryException>().having(
              (error) => error.message,
              'message',
              contains('اطلاعات دریافتی کارکنان معتبر نیست'),
            ),
          ),
        );
      },
    );
  });
}

EmployeeRepository _repository(
  Future<http.Response> Function(http.Request) handler, {
  Duration requestTimeout = const Duration(seconds: 15),
}) => EmployeeRepository(
  PocketBase(
    'http://example.test',
    httpClientFactory: () => MockClient(handler),
  ),
  requestTimeout: requestTimeout,
);

http.Response _response(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _record({
  String id = 'employee0000001',
  String? endDate = '',
  bool isActive = true,
}) => {
  'id': id,
  'collectionId': 'employees000001',
  'collectionName': 'employees',
  'first_name': 'علی',
  'last_name': 'احمدی',
  'national_code': '0012345678',
  'mobile': '09123456789',
  'personnel_code': '0012',
  'job_title': 'کارشناس',
  'department': 'اداری',
  'hire_date': '2010-03-21 00:00:00.000Z',
  'end_date': endDate,
  'is_active': isActive,
};

Employee _employee({
  String id = 'employee0000001',
  DateTime? hireDate,
  DateTime? endDate,
  bool isActive = true,
}) => Employee(
  id: id,
  firstName: 'علی',
  lastName: 'احمدی',
  nationalCode: '0012345678',
  mobile: '09123456789',
  personnelCode: '0012',
  jobTitle: 'کارشناس',
  department: 'اداری',
  hireDate: hireDate ?? DateTime(2010, 3, 21),
  endDate: endDate,
  isActive: isActive,
);
