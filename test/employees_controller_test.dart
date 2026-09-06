import 'dart:async';

import 'package:employee_manager/data/employee_repository.dart';
import 'package:employee_manager/models/employee.dart';
import 'package:employee_manager/state/employees_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  late FakeEmployeeRepository repository;
  late EmployeesController controller;

  setUp(() {
    repository = FakeEmployeeRepository();
    controller = EmployeesController(repository);
  });

  tearDown(() => controller.dispose());

  test('loads only server records and exposes a read-only list', () async {
    final employee = makeEmployee('server-id');
    final pending = Completer<List<Employee>>();
    repository.load = () => pending.future;

    final loading = controller.loadEmployees();
    expect(controller.status, EmployeesStatus.loading);
    expect(controller.employees, isEmpty);

    pending.complete([employee]);
    await loading;

    expect(controller.status, EmployeesStatus.success);
    expect(controller.employees, [employee]);
    expect(() => controller.employees.clear(), throwsUnsupportedError);
  });

  test('empty responses produce an empty state', () async {
    await controller.loadEmployees();

    expect(controller.status, EmployeesStatus.empty);
    expect(controller.employees, isEmpty);
    expect(controller.errorMessage, isNull);
  });

  test('connection failure becomes a recoverable error state', () async {
    repository.load = () async => throw const EmployeeRepositoryException(
      'ارتباط با پایگاه داده برقرار نشد',
    );

    await controller.loadEmployees();
    expect(controller.status, EmployeesStatus.error);
    expect(controller.errorMessage, 'ارتباط با پایگاه داده برقرار نشد');

    repository.load = () async => [makeEmployee('recovered')];
    await controller.loadEmployees();
    expect(controller.status, EmployeesStatus.success);
    expect(controller.errorMessage, isNull);
    expect(controller.employees.single.id, 'recovered');
  });

  test('create adds the server record only after success', () async {
    await controller.loadEmployees();
    final pending = Completer<Employee>();
    repository.create = (_) => pending.future;

    final saving = controller.saveEmployee(makeEmployee(''));
    expect(controller.isMutating, isTrue);
    expect(controller.employees, isEmpty);

    final saved = makeEmployee('generated-by-server');
    pending.complete(saved);
    expect(await saving, same(saved));
    expect(controller.employees, [saved]);
    expect(controller.status, EmployeesStatus.success);
    expect(controller.isMutating, isFalse);
  });

  test('update replaces the shared record after server success', () async {
    final original = makeEmployee('existing');
    repository.load = () async => [original];
    await controller.loadEmployees();

    final pending = Completer<Employee>();
    repository.update = (_) => pending.future;
    final edited = makeEmployee('existing', firstName: 'مریم');
    final saving = controller.saveEmployee(edited);
    expect(controller.employees, [original]);

    pending.complete(edited);
    await saving;
    expect(controller.employees, [edited]);
    expect(controller.isMutating, isFalse);
  });

  test('failed update preserves data and propagates field errors', () async {
    final original = makeEmployee('existing');
    repository.load = () async => [original];
    await controller.loadEmployees();
    const failure = EmployeeRepositoryException(
      'کد پرسنلی تکراری است',
      fieldErrors: {'personnel_code': 'کد پرسنلی تکراری است'},
    );
    repository.update = (_) async => throw failure;

    await expectLater(
      controller.saveEmployee(makeEmployee('existing', firstName: 'مریم')),
      throwsA(same(failure)),
    );

    expect(controller.employees, [original]);
    expect(controller.status, EmployeesStatus.success);
    expect(controller.isMutating, isFalse);
  });

  test(
    'delete keeps the row until server success, then becomes empty',
    () async {
      final original = makeEmployee('existing');
      repository.load = () async => [original];
      await controller.loadEmployees();
      final pending = Completer<void>();
      repository.delete = (_) => pending.future;

      final deleting = controller.deleteEmployee(original);
      expect(controller.employees, [original]);
      expect(controller.isMutating, isTrue);
      pending.complete();
      await deleting;

      expect(controller.employees, isEmpty);
      expect(controller.status, EmployeesStatus.empty);
      expect(controller.isMutating, isFalse);
    },
  );

  test('failed deletion preserves the employee', () async {
    final employee = makeEmployee('existing');
    repository.load = () async => [employee];
    await controller.loadEmployees();
    repository.delete = (_) async => throw const EmployeeRepositoryException(
      'ارتباط با پایگاه داده برقرار نشد',
    );

    await expectLater(
      controller.deleteEmployee(employee),
      throwsA(isA<EmployeeRepositoryException>()),
    );

    expect(controller.employees, [employee]);
    expect(controller.status, EmployeesStatus.success);
    expect(controller.isMutating, isFalse);
  });

  test('prevents overlapping reads and mutations', () async {
    final pendingLoad = Completer<List<Employee>>();
    repository.load = () => pendingLoad.future;
    final loading = controller.loadEmployees();
    await controller.loadEmployees();
    await expectLater(
      controller.saveEmployee(makeEmployee('')),
      throwsA(isA<EmployeeRepositoryException>()),
    );
    expect(repository.loadCount, 1);
    expect(repository.createCount, 0);
    pendingLoad.complete([]);
    await loading;

    final pendingCreate = Completer<Employee>();
    repository.create = (_) => pendingCreate.future;
    final saving = controller.saveEmployee(makeEmployee(''));
    await controller.loadEmployees();
    await expectLater(
      controller.deleteEmployee(makeEmployee('other')),
      throwsA(isA<EmployeeRepositoryException>()),
    );
    expect(repository.loadCount, 1);
    expect(repository.deleteCount, 0);
    pendingCreate.complete(makeEmployee('created'));
    await saving;
  });

  test('unexpected errors are converted to a user-facing failure', () async {
    repository.load = () async => throw StateError('private implementation');
    await controller.loadEmployees();
    expect(controller.status, EmployeesStatus.error);
    expect(controller.errorMessage, 'دریافت اطلاعات کارکنان با خطا مواجه شد');

    repository.create = (_) async => throw StateError('private implementation');
    await expectLater(
      controller.saveEmployee(makeEmployee('')),
      throwsA(
        isA<EmployeeRepositoryException>().having(
          (error) => error.message,
          'message',
          'ذخیره اطلاعات کارمند با خطا مواجه شد',
        ),
      ),
    );
    expect(controller.employees, isEmpty);
    expect(controller.isMutating, isFalse);
  });

  test('late load completion does not notify a disposed controller', () async {
    final disposedController = EmployeesController(repository);
    final pending = Completer<List<Employee>>();
    repository.load = () => pending.future;
    var notifications = 0;
    disposedController.addListener(() => notifications++);
    final loading = disposedController.loadEmployees();
    disposedController.dispose();

    pending.complete([makeEmployee('late')]);
    await loading;
    expect(notifications, 1);
    expect(disposedController.employees, isEmpty);
  });

  test(
    'late mutation completion does not notify a disposed controller',
    () async {
      final disposedController = EmployeesController(repository);
      await disposedController.loadEmployees();
      final pending = Completer<Employee>();
      repository.create = (_) => pending.future;
      var notifications = 0;
      disposedController.addListener(() => notifications++);
      final saving = disposedController.saveEmployee(makeEmployee(''));
      disposedController.dispose();

      pending.complete(makeEmployee('late'));
      await saving;
      expect(notifications, 1);
      expect(disposedController.employees, isEmpty);
    },
  );
}

Employee makeEmployee(String id, {String firstName = 'علی'}) => Employee(
  id: id,
  firstName: firstName,
  lastName: 'احمدی',
  nationalCode: '0012345678',
  mobile: '09121234567',
  personnelCode: '1001',
  jobTitle: 'کارشناس',
  department: 'فناوری اطلاعات',
  hireDate: DateTime(2010, 3, 21),
  isActive: true,
);

class FakeEmployeeRepository extends EmployeeRepository {
  FakeEmployeeRepository() : super(PocketBase('http://example.invalid'));

  Future<List<Employee>> Function() load = () async => [];
  Future<Employee> Function(Employee) create = (employee) async => employee;
  Future<Employee> Function(Employee) update = (employee) async => employee;
  Future<void> Function(String) delete = (_) async {};
  int loadCount = 0;
  int createCount = 0;
  int deleteCount = 0;

  @override
  Future<List<Employee>> getEmployees() {
    loadCount++;
    return load();
  }

  @override
  Future<Employee> createEmployee(Employee employee) {
    createCount++;
    return create(employee);
  }

  @override
  Future<Employee> updateEmployee(Employee employee) => update(employee);

  @override
  Future<void> deleteEmployee(String id) {
    deleteCount++;
    return delete(id);
  }
}
