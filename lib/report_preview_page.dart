import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ReportPreviewPage extends StatefulWidget {
  const ReportPreviewPage({
    super.key,
    required this.buildReport,
    required this.fileName,
  });

  final Future<Uint8List> Function() buildReport;
  final String fileName;

  @override
  State<ReportPreviewPage> createState() => _ReportPreviewPageState();
}

class _ReportPreviewPageState extends State<ReportPreviewPage> {
  late Future<Uint8List> _report;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _report = widget.buildReport();
  }

  Future<void> _save(Uint8List bytes) async {
    setState(() => _saving = true);
    try {
      final location = await getSaveLocation(
        suggestedName: widget.fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
        confirmButtonText: 'ذخیره',
      );
      if (location == null) return;
      await XFile.fromData(
        bytes,
        name: widget.fileName,
        mimeType: 'application/pdf',
      ).saveTo(location.path);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('گزارش PDF ذخیره شد')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ذخیره گزارش انجام نشد؛ دوباره تلاش کنید.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: FutureBuilder<Uint8List>(
      future: _report,
      builder: (context, snapshot) => Scaffold(
        appBar: AppBar(
          title: const Text('پیش‌نمایش گزارش چاپی'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: snapshot.hasData && !_saving
                    ? () => _save(snapshot.data!)
                    : null,
                icon: const Icon(Icons.save_alt_rounded),
                label: Text(_saving ? 'در حال ذخیره…' : 'ذخیره PDF'),
              ),
            ),
          ],
        ),
        body: snapshot.hasError
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ساخت گزارش انجام نشد.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _report = widget.buildReport()),
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              )
            : !snapshot.hasData
            ? const Center(child: CircularProgressIndicator())
            : PdfPreview(
                build: (_) async => snapshot.data!,
                initialPageFormat: PdfPageFormat.a4.landscape,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowSharing: false,
                pdfFileName: widget.fileName,
                maxPageWidth: 1100,
                onPrintError: (context, error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'چاپ انجام نشد؛ اتصال چاپگر را بررسی کنید.',
                      ),
                    ),
                  );
                },
              ),
      ),
    ),
  );
}
