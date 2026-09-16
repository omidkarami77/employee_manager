import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'data/employee_repository.dart';
import 'models/employee.dart';
import 'state/employees_controller.dart';
import 'utils/experience.dart';

class EmployeeDetailsPage extends StatefulWidget {
  const EmployeeDetailsPage({
    super.key,
    required this.employee,
    required this.controller,
    required this.repository,
    required this.onEdit,
  });

  final Employee employee;
  final EmployeesController controller;
  final EmployeeRepository repository;
  final Future<Employee?> Function(Employee employee) onEdit;

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  late Employee _employee;
  bool _uploading = false;
  List<PlatformFile> _pendingDocuments = const [];

  bool get _isAdmin => widget.controller.canManageEmployees;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  Future<void> _editEmployee() async {
    final saved = await widget.onEdit(_employee);
    if (saved != null && mounted) setState(() => _employee = saved);
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFile(
      type: FileType.image,
    );
    if (result == null) return;
    await _runUpload(
      () async => widget.controller.uploadPhoto(
        _employee,
        await result.readAsBytes(),
        result.name,
      ),
      successMessage: 'عکس پروفایل با موفقیت ذخیره شد.',
    );
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result.isNotEmpty && mounted) {
      setState(() => _pendingDocuments = [
        ..._pendingDocuments,
        ...result,
      ]);
    }
  }

  Future<void> _savePendingDocuments() async {
    if (_pendingDocuments.isEmpty) {
      _message('فایل‌های انتخاب‌شده قابل خواندن نیستند.');
      return;
    }
    final saved = await _runUpload(
      () async => widget.controller.uploadDocuments(
        _employee,
        await Future.wait(
          _pendingDocuments.map(
            (file) async => (file.name, await file.readAsBytes()),
          ),
        ),
      ),
      successMessage: 'مدارک با موفقیت ذخیره شدند.',
    );
    if (saved && mounted) setState(() => _pendingDocuments = const []);
  }

  Future<bool> _runUpload(
    Future<Employee> Function() operation, {
    String? successMessage,
  }) async {
    setState(() => _uploading = true);
    try {
      final saved = await operation();
      if (mounted) {
        setState(() => _employee = saved);
        if (successMessage != null) _message(successMessage);
      }
      return true;
    } on EmployeeRepositoryException catch (error) {
      _message(error.message);
      return false;
    } catch (_) {
      _message('بارگذاری فایل انجام نشد. اتصال و تنظیمات PocketBase را بررسی کنید.');
      return false;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDocument(String filename) async {
    final url = widget.repository.fileUrl(_employee, filename);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _message('باز کردن مدرک امکان‌پذیر نیست.');
    }
  }

  Future<void> _saveDocument(String filename) async {
    setState(() => _uploading = true);
    try {
      final response = await http.get(widget.repository.fileUrl(
        _employee,
        filename,
        download: true,
      ));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('download failed');
      }
      final saved = await FilePicker.saveFile(
        fileName: filename,
        bytes: response.bodyBytes,
      );
      if (saved == null) return;
      _message('مدرک با موفقیت ذخیره شد.');
    } catch (_) {
      _message('ذخیرهٔ مدرک انجام نشد.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(String filename) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مدرک'),
        content: Text('آیا از حذف «$filename» مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (remove == true) {
      await _runUpload(() => widget.controller.deleteDocument(_employee, filename));
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل کارمند'),
        actions: [
          if (_isAdmin)
            TextButton.icon(
              onPressed: _uploading ? null : _editEmployee,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('ویرایش اطلاعات'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileCard(context),
                    const SizedBox(height: 20),
                    _detailsCard(context),
                    const SizedBox(height: 20),
                    _documentsCard(context),
                  ],
                ),
              ),
            ),
          ),
          if (_uploading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        ],
      ),
    ),
  );

  Widget _profileCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _employee.photo.isEmpty
              ? const CircleAvatar(radius: 48, child: Icon(Icons.person_rounded, size: 52))
              : CircleAvatar(radius: 48, backgroundImage: NetworkImage(widget.repository.fileUrl(_employee, _employee.photo).toString())),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_employee.fullName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_employee.jobTitle, style: const TextStyle(color: Color(0xFF667085))),
          ])),
          if (_isAdmin) OutlinedButton.icon(onPressed: _uploading ? null : _pickPhoto, icon: const Icon(Icons.photo_camera_outlined), label: const Text('بارگذاری عکس')),
        ],
      ),
    ),
  );

  Widget _detailsCard(BuildContext context) {
    final values = <(String, String)>[
      ('کد پرسنلی', _employee.personnelCode), ('کد ملی', _employee.nationalCode),
      ('شماره موبایل', _employee.mobile), ('سمت', _employee.jobTitle),
      ('واحد سازمانی', _employee.department), ('تاریخ استخدام', _formatDate(_employee.hireDate)),
      ('آدرس', _employee.address.isEmpty ? '—' : _employee.address),
      ('تاریخ پایان همکاری', _employee.endDate == null ? '—' : _formatDate(_employee.endDate!)),
      ('سابقه', employeeExperience(_employee).toString()), ('وضعیت', _employee.isActive ? 'فعال' : 'غیرفعال'),
    ];
    return Card(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(spacing: 32, runSpacing: 20, children: values.map((item) => SizedBox(width: 285, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: const TextStyle(color: Color(0xFF667085))), const SizedBox(height: 5), Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700))]))).toList()),
    ));
  }

  Widget _documentsCard(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('مدارک', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), if (_isAdmin) OutlinedButton.icon(onPressed: _uploading ? null : _pickDocuments, icon: const Icon(Icons.attach_file_rounded), label: const Text('انتخاب مدارک'))]),
      const SizedBox(height: 12),
      if (_isAdmin && _pendingDocuments.isNotEmpty) ...[
        const Text('فایل‌های انتخاب‌شده (هنوز ذخیره نشده‌اند):', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._pendingDocuments.asMap().entries.map((entry) => ListTile(
          dense: true,
          leading: const Icon(Icons.pending_outlined),
          title: Text(entry.value.name, textDirection: TextDirection.ltr),
          trailing: IconButton(
            tooltip: 'حذف از انتخاب',
            onPressed: _uploading ? null : () => setState(() {
              _pendingDocuments = List.of(_pendingDocuments)..removeAt(entry.key);
            }),
            icon: const Icon(Icons.close_rounded),
          ),
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _uploading ? null : _savePendingDocuments,
            icon: const Icon(Icons.save_outlined),
            label: Text('ذخیرهٔ ${_pendingDocuments.length} مدرک'),
          ),
        ),
        const Divider(height: 32),
      ],
      if (_employee.documents.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('مدرکی ثبت نشده است.')),
      ..._employee.documents.map((file) => ListTile(
        leading: const Icon(Icons.description_outlined), title: Text(file, textDirection: TextDirection.ltr),
        trailing: Wrap(spacing: 2, children: [
          IconButton(tooltip: 'باز کردن', onPressed: _uploading ? null : () => _openDocument(file), icon: const Icon(Icons.open_in_new_rounded)),
          IconButton(tooltip: 'دانلود / ذخیره', onPressed: _uploading ? null : () => _saveDocument(file), icon: const Icon(Icons.download_rounded)),
          if (_isAdmin) IconButton(tooltip: 'حذف مدرک', onPressed: _uploading ? null : () => _deleteDocument(file), color: Theme.of(context).colorScheme.error, icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      )),
    ]),
  ));
}

String _formatDate(DateTime value) => '${value.year.toString().padLeft(4, '0')}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
