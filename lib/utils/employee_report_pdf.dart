import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/employee.dart';

String reportPersianDigits(String value) => value.replaceAllMapped(
  RegExp('[0-9]'),
  (match) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(match[0]!)],
);

String employeeReportTitle(String? collaborationType) {
  final type = collaborationType?.trim() ?? '';
  if (type.isEmpty) return 'گزارش کارکنان';
  final label = Employee.normalizeCollaborationType(type);
  return 'گزارش کارکنان $label';
}

/// A compact print report; the complete personnel export remains in Excel.
Future<Uint8List> buildEmployeeReportPdf({
  required List<Employee> employees,
  required DateTime generatedAt,
  required String dateLabel,
  required String filters,
  required String Function(DateTime) formatDate,
  String? collaborationType,
  bool collaborationReport = false,
}) async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'),
  );
  final title = employeeReportTitle(collaborationType);
  final document = pw.Document(title: title, author: 'مدیریت کارکنان');
  const navy = PdfColor.fromInt(0xFF234569);
  const pale = PdfColor.fromInt(0xFFF0F4F8);
  final active = employees.where((e) => e.isActive).length;
  final headers = collaborationReport
      ? [
          'ردیف',
          'نام',
          'نام خانوادگی',
          'درجه',
          'استان',
          'نوع همکاری',
          'تاریخ شروع همکاری',
        ]
      : [
          'ردیف',
          'نام و نام خانوادگی',
          'کد کارگزینی',
          'استان',
          'نوع همکاری',
          'شروع همکاری',
          'شماره موبایل',
          'وضعیت',
        ];
  final rows = employees.indexed.map((entry) {
    final (index, e) = entry;
    if (collaborationReport) {
      return [
        reportPersianDigits('${index + 1}'),
        e.firstName,
        e.lastName,
        e.jobTitle.isEmpty ? '—' : e.jobTitle,
        e.province.isEmpty ? '—' : e.province,
        e.collaborationType.isEmpty ? '—' : e.collaborationType,
        formatDate(e.hireDate),
      ];
    }
    return [
      reportPersianDigits('${index + 1}'),
      e.fullName,
      reportPersianDigits(e.personnelCode),
      e.province.isEmpty ? '—' : e.province,
      e.collaborationType.isEmpty ? '—' : e.collaborationType,
      formatDate(e.hireDate),
      e.mobile.trim().isEmpty ? '—' : reportPersianDigits(e.mobile),
      e.isActive ? 'فعال' : 'غیرفعال',
    ];
  }).toList();

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(30),
      maxPages: 10000,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        margin: const pw.EdgeInsets.only(bottom: 14),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: navy, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 21, color: navy),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'هیئت معارف جنگ شهید سپهبد علی صیاد شیرازی',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Text(
              'تاریخ تهیه: $dateLabel',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'مدیریت کارکنان • $dateLabel',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              reportPersianDigits(
                'صفحه ${context.pageNumber} از ${context.pagesCount}',
              ),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
      build: (_) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: pale,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            reportPersianDigits(
              'کل نتایج: ${employees.length} نفر     |     فعال: $active نفر     |     غیرفعال: ${employees.length - active} نفر',
            ),
            style: pw.TextStyle(fontSize: 11, color: navy),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'فیلترهای گزارش: $filters',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 14),
        if (rows.isEmpty)
          pw.Text('کارمندی با این فیلترها یافت نشد.')
        else
          pw.TableHelper.fromTextArray(
            // Explicit reversal puts the first column at the right of the sheet.
            headers: headers.reversed.toList(),
            data: rows.map((row) => row.reversed.toList()).toList(),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: navy),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 8,
            ),
            oddRowDecoration: const pw.BoxDecoration(color: pale),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: .4),
            columnWidths: collaborationReport
                ? {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(2.2),
                    2: const pw.FlexColumnWidth(1.2),
                    3: const pw.FlexColumnWidth(1.2),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(1.2),
                    6: const pw.FlexColumnWidth(.5),
                  }
                : {
                    0: const pw.FlexColumnWidth(.8),
                    1: const pw.FlexColumnWidth(1.3),
                    2: const pw.FlexColumnWidth(1.1),
                    3: const pw.FlexColumnWidth(2.2),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1.2),
                    6: const pw.FlexColumnWidth(2),
                    7: const pw.FlexColumnWidth(.5),
                  },
          ),
      ],
    ),
  );
  return document.save();
}
