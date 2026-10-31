import 'dart:convert';
import 'dart:io';

import 'package:employee_manager/models/employee.dart';
import 'package:employee_manager/utils/employee_report_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Persian report embeds its font and paginates a large result set', () async {
    final employees = List.generate(
      120,
      (index) => Employee(
        id: '$index',
        firstName: 'محمدرضا',
        lastName: 'احمدی',
        nationalCode: '0012345678',
        mobile: '09123456789',
        personnelCode: '00123',
        jobTitle: 'کارشناس',
        province: 'خراسان رضوی',
        collaborationType: 'معارف جنگ و روساء گروه های استانی',
        hireDate: DateTime(2016, 1, 1),
        isActive: index.isEven,
      ),
    );
    final bytes = await buildEmployeeReportPdf(
      employees: employees,
      generatedAt: DateTime(2026, 10, 28),
      dateLabel: '۱۴۰۵/۰۸/۰۶',
      filters: 'استان: همه • وضعیت: همه • سابقه: همه',
      formatDate: (_) => '۱۳۹۴/۱۰/۱۱',
    );
    final content = latin1.decode(bytes);
    expect(content, startsWith('%PDF-'));
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(content).length,
      greaterThan(1),
    );
    expect(content, contains('/FontFile2'));
    // Optional artifact for visual review, without touching production records.
    const preview = String.fromEnvironment('REPORT_SAMPLE');
    if (preview.isNotEmpty) await File(preview).writeAsBytes(bytes);
  });

  test('empty results still produce a valid report', () async {
    final bytes = await buildEmployeeReportPdf(
      employees: [],
      generatedAt: DateTime(2026, 10, 28),
      dateLabel: '۱۴۰۵/۰۸/۰۶',
      filters: 'استان: تهران',
      formatDate: (_) => '',
    );
    expect(latin1.decode(bytes), startsWith('%PDF-'));
  });
}
