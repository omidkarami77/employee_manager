import 'package:employee_manager/models/employee.dart';
import 'package:employee_manager/utils/employee_report.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 7);
  final active = employee('active', DateTime(2016, 9, 7));
  final short = employee('short', DateTime(2016, 9, 8));
  final inactive = employee(
    'inactive',
    DateTime(2000, 1, 1),
    endDate: DateTime(2005, 1, 1),
  );
  final employees = [active, short, inactive];

  test(
    'minimum experience includes anniversary but excludes the previous day',
    () {
      expect(filterEmployeeReport(employees, minimumYears: 10, now: now), [
        active,
      ]);
      expect(
        filterEmployeeReport(employees, minimumYears: 5, now: now),
        employees,
      );
      for (final years in [15, 20]) {
        expect(
          filterEmployeeReport(employees, minimumYears: years, now: now),
          isEmpty,
        );
      }
    },
  );

  test('inactive experience stops at end date and filters combine', () {
    expect(filterEmployeeReport(employees, active: false, now: now), [
      inactive,
    ]);
    expect(
      filterEmployeeReport(
        employees,
        active: false,
        minimumYears: 10,
        now: now,
      ),
      isEmpty,
    );
    expect(
      filterEmployeeReport(employees, active: true, query: 'active', now: now),
      [active],
    );
  });

  test('province filter returns only the selected province', () {
    final tehran = employee('tehran', now, province: 'تهران');
    final fars = employee('fars', now, province: 'فارس');

    expect(
      filterEmployeeReport([tehran, fars], province: 'تهران', now: now),
      [tehran],
    );
    expect(
      filterEmployeeReport([tehran, fars], province: 'گیلان', now: now),
      isEmpty,
    );
  });

  test('search accepts names and both codes including localized digits', () {
    for (final query in [
      'علی',
      'احمدی',
      'علی احمدی',
      'active',
      '۰۰۱۲۳۴۵۶۷۸',
      '٠٠١٢٣٤٥٦٧٨',
    ]) {
      expect(filterEmployeeReport([active], query: query, now: now), [active]);
    }
    expect(filterEmployeeReport(employees, query: 'ناشناس', now: now), isEmpty);
    expect(filterEmployeeReport([], now: now), isEmpty);
  });

  test(
    'xlsx round trip preserves headers, RTL, zeroes and literal user text',
    () {
      final rows = [
        [
          '۱',
          '=1+1',
          'احمدی',
          '0001',
          '0012345678',
          '09123456789',
          'کارشناس',
          'اداری',
          'تهران',
          'تهران',
          '۱۳۹۵/۰۶/۱۷',
          '',
          '۱۰ سال و ۰ ماه',
          'فعال',
        ],
      ];
      final workbook = Excel.decodeBytes(buildEmployeeReportExcel(rows));
      expect(workbook.tables.keys, ['گزارش کارکنان']);
      final sheet = workbook.tables.values.single;
      expect(sheet.isRTL, isTrue);
      expect(sheet.maxRows, 2);
      expect(
        sheet.rows.first.map((cell) => cell!.value.toString()).toList(),
        employeeReportHeaders,
      );
      for (final index in [1, 3, 4, 5, 8, 9, 10, 12, 13]) {
        expect(sheet.rows[1][index]!.value, isA<TextCellValue>());
        expect(sheet.rows[1][index]!.value.toString(), rows.single[index]);
      }
    },
  );
}

Employee employee(
  String id,
  DateTime hireDate, {
  DateTime? endDate,
  String province = '',
}) =>
    Employee(
      id: id,
      firstName: 'علی',
      lastName: 'احمدی',
      nationalCode: '0012345678',
      mobile: '09123456789',
      personnelCode: id,
      jobTitle: 'کارشناس',
      department: 'اداری',
      province: province,
      hireDate: hireDate,
      endDate: endDate,
      isActive: endDate == null,
    );
