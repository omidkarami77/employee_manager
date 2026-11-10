import 'dart:convert';
import 'dart:io';

import 'package:employee_manager/models/employee.dart';
import 'package:employee_manager/utils/employee_report_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('report title follows the selected collaboration filter', () {
    expect(employeeReportTitle(null), 'گزارش کارکنان');
    expect(employeeReportTitle(''), 'گزارش کارکنان');
    expect(employeeReportTitle('نظامی شاغل'), 'گزارش کارکنان نظامی شاغل');
    expect(
      employeeReportTitle('معارف جنگ و روساء گروه های استانی'),
      'گزارش کارکنان هیئت مرکزی و گروه های استانی',
    );
  });

  test('Persian report embeds its font and paginates a large result set', () async {
    final employees = List.generate(
      215,
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
      inInclusiveRange(2, 40),
    );
    expect(content, contains('/FontFile2'));
    final collaborationBytes = await buildEmployeeReportPdf(
      employees: employees,
      generatedAt: DateTime(2026, 10, 28),
      dateLabel: '۱۴۰۵/۰۸/۰۶',
      filters: 'استان: همه',
      formatDate: (_) => '۱۳۹۴/۱۰/۱۱',
      collaborationReport: true,
      collaborationType: 'معارف جنگ و روساء گروه های استانی',
    );
    final collaborationContent = latin1.decode(collaborationBytes);
    expect(collaborationContent, startsWith('%PDF-'));
    expect(collaborationContent, contains('/FontFile2'));
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(collaborationContent).length,
      inInclusiveRange(2, 40),
    );
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
