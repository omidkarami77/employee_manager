import 'dart:async';

import 'package:employee_manager/data/employee_repository.dart';
import 'package:employee_manager/main.dart';
import 'package:employee_manager/models/employee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';

const _connectionError = 'ارتباط با پایگاه داده برقرار نشد';

void main() {
  testWidgets('loads from the repository and can retry a failed initial load', (
    tester,
  ) async {
    final firstLoad = Completer<List<Employee>>();
    final retry = Completer<List<Employee>>();
    final repository = _FakeEmployeeRepository()
      ..onGet = () => firstLoad.future;

    await _startApp(tester, repository);
    expect(repository.getCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(AppText.allEmployees), findsNothing);

    firstLoad.completeError(
      const EmployeeRepositoryException(_connectionError),
    );
    await tester.pumpAndSettle();
    expect(find.text(_connectionError), findsOneWidget);
    expect(tester.takeException(), isNull);

    repository.onGet = () => retry.future;
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pump();
    expect(repository.getCalls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retry.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('۰ نفر'), findsNWidgets(4));
    await _openEmployees(tester);
    expect(find.text('هنوز کارمندی ثبت نشده است.'), findsOneWidget);
    expect(repository.getCalls, 2);
  });

  testWidgets(
    'create waits for the server record and updates shared statistics',
    (tester) async {
      final creation = Completer<Employee>();
      final repository = _FakeEmployeeRepository()
        ..onCreate = (_) => creation.future;
      await _startApp(tester, repository);
      await tester.pumpAndSettle();
      await _openEmployees(tester);
      await tester.tap(find.text('افزودن کارمند'));
      await tester.pumpAndSettle();

      await _enterField(tester, 'نام', 'علی');
      await _enterField(tester, 'نام خانوادگی', 'احمدی');
      await _enterField(tester, 'کد ملی', '0012345678');
      await _enterField(tester, 'شماره موبایل', '09121234567');
      await _enterField(tester, 'کد پرسنلی', '1001');
      await _enterField(tester, 'سمت', 'کارشناس');
      await _enterField(tester, 'واحد سازمانی', 'اداری');
      await tester.ensureVisible(find.text('انتخاب تاریخ استخدام'));
      await tester.tap(find.text('انتخاب تاریخ استخدام'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ثبت کارمند'));
      await tester.pump();

      expect(repository.createCalls, 1);
      expect(repository.lastCreated!.id, isEmpty);
      expect(repository.lastCreated!.firstName, 'علی');
      expect(repository.lastCreated!.nationalCode, '0012345678');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('علی احمدی'), findsNothing);

      final saved = _withIdentity(repository.lastCreated!, 'server-record-1');
      creation.complete(saved);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(saved.fullName), findsOneWidget);
      expect(find.text('کارمند با موفقیت ثبت شد.'), findsOneWidget);

      await _openDashboard(tester);
      expect(_statValue(AppText.allEmployees, '۱ نفر'), findsOneWidget);
      await _openEmployees(tester);
      await tester.ensureVisible(find.byTooltip('مشاهده'));
      await tester.tap(find.byTooltip('مشاهده'));
      await tester.pumpAndSettle();
      expect(find.text('شناسه: server-record-1'), findsOneWidget);
      expect(repository.getCalls, 1);
    },
  );

  testWidgets(
    'failed edit preserves the form and retry updates a filtered row',
    (tester) async {
      final original = _employee();
      final firstUpdate = Completer<Employee>();
      final repository = _FakeEmployeeRepository()
        ..onGet = (() async => [original])
        ..onUpdate = (_) => firstUpdate.future;
      await _startApp(tester, repository);
      await tester.pumpAndSettle();
      await _openEmployees(tester);
      await tester.enterText(find.byType(TextField), original.personnelCode);
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('ویرایش'));
      await tester.tap(find.byTooltip('ویرایش'));
      await tester.pumpAndSettle();
      expect(find.text('ویرایش کارمند'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, original.firstName),
        findsOneWidget,
      );

      await _enterField(tester, 'نام', 'سارا');
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pump();
      expect(repository.updateCalls, 1);
      expect(repository.lastUpdated!.id, original.id);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(original.fullName), findsOneWidget);

      firstUpdate.completeError(
        const EmployeeRepositoryException(_connectionError),
      );
      await tester.pumpAndSettle();
      expect(find.text(_connectionError), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'سارا'), findsOneWidget);
      expect(find.text(original.fullName), findsOneWidget);
      expect(tester.takeException(), isNull);

      repository.onUpdate = (employee) async => employee;
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(repository.updateCalls, 2);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('سارا احمدی'), findsOneWidget);
      expect(find.text(original.fullName), findsNothing);
      expect(find.text('تغییرات با موفقیت ذخیره شد.'), findsOneWidget);

      await _openDashboard(tester);
      expect(_statValue(AppText.allEmployees, '۱ نفر'), findsOneWidget);
      await _openEmployees(tester);
      expect(find.text('سارا احمدی'), findsOneWidget);
      expect(repository.getCalls, 1);
    },
  );

  testWidgets(
    'delete keeps the record on failure and removes it after success',
    (tester) async {
      final employee = _employee();
      final firstDelete = Completer<void>();
      final repository = _FakeEmployeeRepository()
        ..onGet = (() async => [employee])
        ..onDelete = (_) => firstDelete.future;
      await _startApp(tester, repository);
      await tester.pumpAndSettle();
      await _openEmployees(tester);
      await _confirmDelete(tester, employee);
      await tester.pump();
      expect(repository.deleteCalls, 1);
      expect(repository.lastDeletedId, employee.id);
      expect(find.text(employee.fullName), findsOneWidget);

      firstDelete.completeError(
        const EmployeeRepositoryException(_connectionError),
      );
      await tester.pumpAndSettle();
      expect(find.text(_connectionError), findsWidgets);
      expect(find.text(employee.fullName), findsOneWidget);
      expect(tester.takeException(), isNull);

      repository.onDelete = (_) async {};
      await _confirmDelete(tester, employee);
      await tester.pumpAndSettle();
      expect(repository.deleteCalls, 2);
      expect(find.text(employee.fullName), findsNothing);
      expect(find.text('هنوز کارمندی ثبت نشده است.'), findsOneWidget);
      await _openDashboard(tester);
      expect(find.text('۰ نفر'), findsNWidgets(4));
    },
  );
}

Future<void> _startApp(
  WidgetTester tester,
  EmployeeRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(EmployeeManagerApp(repository: repository));
}

Future<void> _openEmployees(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.people_outline_rounded));
  await tester.pumpAndSettle();
}

Future<void> _openDashboard(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.grid_view_rounded));
  await tester.pumpAndSettle();
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

Future<void> _confirmDelete(WidgetTester tester, Employee employee) async {
  await tester.ensureVisible(find.byTooltip('حذف'));
  await tester.tap(find.byTooltip('حذف'));
  await tester.pumpAndSettle();
  expect(
    find.text('آیا از حذف «${employee.fullName}» مطمئن هستید؟'),
    findsOneWidget,
  );
  await tester.tap(find.text('حذف'));
}

Finder _statValue(String title, String value) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
  matching: find.text(value),
);

Employee _employee() => Employee(
  id: 'server-record-1',
  firstName: 'علی',
  lastName: 'احمدی',
  nationalCode: '0012345678',
  mobile: '09121234567',
  personnelCode: '1001',
  jobTitle: 'کارشناس',
  department: 'اداری',
  hireDate: DateTime(2000, 1, 1),
  isActive: true,
);

Employee _withIdentity(Employee employee, String id) => Employee(
  id: id,
  firstName: employee.firstName,
  lastName: employee.lastName,
  nationalCode: employee.nationalCode,
  mobile: employee.mobile,
  personnelCode: employee.personnelCode,
  jobTitle: employee.jobTitle,
  department: employee.department,
  hireDate: employee.hireDate,
  endDate: employee.endDate,
  isActive: employee.isActive,
);

class _FakeEmployeeRepository extends EmployeeRepository {
  _FakeEmployeeRepository() : super(PocketBase('http://example.test'));

  Future<List<Employee>> Function()? onGet;
  Future<Employee> Function(Employee employee)? onCreate;
  Future<Employee> Function(Employee employee)? onUpdate;
  Future<void> Function(String id)? onDelete;
  int getCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  Employee? lastCreated;
  Employee? lastUpdated;
  String? lastDeletedId;

  @override
  Future<List<Employee>> getEmployees() {
    getCalls++;
    return onGet?.call() ?? Future.value([]);
  }

  @override
  Future<Employee> createEmployee(Employee employee) {
    createCalls++;
    lastCreated = employee;
    return onCreate?.call(employee) ?? Future.value(employee);
  }

  @override
  Future<Employee> updateEmployee(Employee employee) {
    updateCalls++;
    lastUpdated = employee;
    return onUpdate?.call(employee) ?? Future.value(employee);
  }

  @override
  Future<void> deleteEmployee(String id) {
    deleteCalls++;
    lastDeletedId = id;
    return onDelete?.call(id) ?? Future.value();
  }
}
