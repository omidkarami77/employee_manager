import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';

import '../models/employee.dart';
import 'experience.dart';

String normalizeReportSearch(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ي', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAllMapped(RegExp('[۰-۹٠-٩]'), (match) {
      final digit = match[0]!.codeUnitAt(0);
      return String.fromCharCode(
        0x30 + digit - (digit >= 0x06f0 ? 0x06f0 : 0x0660),
      );
    });

List<Employee> filterEmployeeReport(
  List<Employee> employees, {
  int minimumYears = 0,
  int? maximumYears,
  bool? active,
  String query = '',
  required DateTime now,
}) {
  final search = normalizeReportSearch(query);
  return employees
      .where(
        (e) =>
            (active == null || e.isActive == active) &&
            employeeExperience(e, now: now).totalMonths >= minimumYears * 12 &&
            (maximumYears == null ||
                employeeExperience(e, now: now).years <= maximumYears) &&
            (search.isEmpty ||
                [e.fullName, e.personnelCode, e.nationalCode].any(
                  (value) => normalizeReportSearch(value).contains(search),
                )),
      )
      .toList();
}

const employeeReportHeaders = [
  'ردیف',
  'نام',
  'نام خانوادگی',
  'کد پرسنلی',
  'کد ملی',
  'شماره موبایل',
  'سمت',
  'واحد سازمانی',
  'آدرس',
  'تاریخ استخدام شمسی',
  'تاریخ پایان همکاری شمسی',
  'سابقه',
  'وضعیت',
];

/// Text cells preserve leading zeroes and never interpret user data as formulas.
Uint8List buildEmployeeReportExcel(List<List<String>> rows) {
  final workbook = Excel.createExcel();
  final defaultSheet = workbook.getDefaultSheet()!;
  workbook['گزارش کارکنان'];
  workbook.setDefaultSheet('گزارش کارکنان');
  workbook.delete(defaultSheet);
  // excel 4 initializes new worksheet XML lazily and resets RTL on first encode.
  // Materialize the empty sheet before applying its layout and report data.
  workbook.encode();
  final sheet = workbook['گزارش کارکنان']..isRTL = true;
  sheet.appendRow(employeeReportHeaders.map(TextCellValue.new).toList());
  for (final row in rows) {
    sheet.appendRow(row.map(TextCellValue.new).toList());
  }
  for (var column = 0; column < employeeReportHeaders.length; column++) {
    sheet.setColumnWidth(column, column == 0 ? 8 : 24);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0))
        .cellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
    );
  }
  final bytes = workbook.encode();
  if (bytes == null) throw StateError('Excel encoding failed');
  return Uint8List.fromList(bytes);
}

Future<bool> saveEmployeeReport(List<List<String>> rows, DateTime now) async {
  final date =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final name = 'employees_report_$date.xlsx';
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Excel', extensions: ['xlsx']),
    ],
    confirmButtonText: 'ذخیره',
  );
  if (location == null) return false;
  final file = XFile.fromData(
    buildEmployeeReportExcel(rows),
    name: name,
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  await file.saveTo(location.path);
  return true;
}
