import 'dart:async';

import 'package:pocketbase/pocketbase.dart';

import '../config/pocketbase_config.dart';
import '../models/employee.dart';
import '../models/app_user.dart';

class EmployeeRepositoryException implements Exception {
  const EmployeeRepositoryException(
    this.message, {
    this.fieldErrors = const {},
  });

  final String message;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

/// Maps database records without coupling the domain model to PocketBase.
class EmployeeRecordMapper {
  EmployeeRecordMapper._();

  static Employee fromRecord(RecordModel record) {
    final endDate = record.getStringValue('end_date');
    return Employee(
      id: record.id,
      firstName: record.getStringValue('first_name'),
      lastName: record.getStringValue('last_name'),
      nationalCode: record.getStringValue('national_code_'),
      mobile: record.getStringValue('mobile'),
      personnelCode: record.getStringValue('personnel_code'),
      jobTitle: record.getStringValue('job_title'),
      department: record.getStringValue('department'),
      hireDate: _readDate(record.getStringValue('hire_date')),
      endDate: endDate.isEmpty ? null : _readDate(endDate),
      isActive: record.getBoolValue('is_active'),
    );
  }

  static Map<String, dynamic> toBody(
    Employee employee, {
    bool clearMissingEndDate = false,
  }) {
    final body = <String, dynamic>{
      'first_name': employee.firstName,
      'last_name': employee.lastName,
      'national_code_': employee.nationalCode,
      'mobile': employee.mobile,
      'personnel_code': employee.personnelCode,
      'job_title': employee.jobTitle,
      'department': employee.department,
      'hire_date': _writeDate(employee.hireDate),
      'is_active': employee.isActive,
    };
    if (employee.endDate != null) {
      body['end_date'] = _writeDate(employee.endDate!);
    } else if (clearMissingEndDate) {
      // PocketBase clears an optional date when it receives an empty string.
      body['end_date'] = '';
    }
    return body;
  }

  static DateTime _readDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[ T]|$)')
        .firstMatch(value);
    if (match == null) {
      throw const FormatException('Invalid employee date');
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException('Invalid employee date');
    }
    return date;
  }

  // Employment dates are calendar days, not instants. Encoding their components
  // as UTC midnight prevents a local-to-UTC conversion from changing the day.
  static String _writeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).toIso8601String();
}

class EmployeeRepository {
  EmployeeRepository(
    this._client, {
    this.requestTimeout = const Duration(seconds: 15),
  });

  final PocketBase _client;
  final Duration requestTimeout;

  AppUser? get currentUser {
    try {
      return _client.authStore.isValid
          ? AppUser.fromRecord(_client.authStore.record)
          : null;
    } catch (_) {
      return null;
    }
  }

  bool get canManageEmployees => currentUser?.isAdmin == true;

  void _requireAdmin() {
    if (!canManageEmployees) {
      throw const EmployeeRepositoryException(
        'شما اجازه افزودن، ویرایش یا حذف کارکنان را ندارید.',
      );
    }
  }

  RecordService get _collection =>
      _client.collection(PocketBaseConfig.employeesCollection);

  Future<List<Employee>> getEmployees() => _request(() async {
    if (currentUser == null) {
      throw const EmployeeRepositoryException(
        'برای مشاهده کارکنان وارد حساب شوید.',
      );
    }
    final records = await _collection.getFullList(sort: 'last_name,first_name');
    return records.map(EmployeeRecordMapper.fromRecord).toList();
  });

  Future<Employee> createEmployee(Employee employee) => _request(() async {
    _requireAdmin();
    final record = await _collection.create(
      body: EmployeeRecordMapper.toBody(employee),
    );
    return EmployeeRecordMapper.fromRecord(record);
  });

  Future<Employee> updateEmployee(Employee employee) => _request(() async {
    _requireAdmin();
    final record = await _collection.update(
      employee.id,
      body: EmployeeRecordMapper.toBody(employee, clearMissingEndDate: true),
    );
    return EmployeeRecordMapper.fromRecord(record);
  });

  Future<void> deleteEmployee(String id) => _request(() {
    _requireAdmin();
    return _collection.delete(id);
  });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on ClientException catch (error) {
      if (error.statusCode == 401) _client.authStore.clear();
      throw _translateError(error);
    } on TimeoutException {
      throw const EmployeeRepositoryException(
        'ارتباط با پایگاه داده برقرار نشد. دوباره تلاش کنید.',
      );
    } on FormatException {
      throw const EmployeeRepositoryException(
        'اطلاعات دریافتی کارکنان معتبر نیست. تاریخ‌های ثبت‌شده را بررسی کنید.',
      );
    }
  }

  EmployeeRepositoryException _translateError(ClientException error) {
    if (error.statusCode == 0) {
      return const EmployeeRepositoryException(
        'ارتباط با پایگاه داده برقرار نشد. دوباره تلاش کنید.',
      );
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const EmployeeRepositoryException(
        'دسترسی به اطلاعات کارکنان مجاز نیست.',
      );
    }
    if (error.statusCode == 404) {
      return const EmployeeRepositoryException(
        'اطلاعات درخواستی در پایگاه داده پیدا نشد. لیست را دوباره دریافت کنید.',
      );
    }
    if (error.statusCode == 429) {
      return const EmployeeRepositoryException(
        'تعداد درخواست‌ها بیش از حد مجاز است. کمی بعد دوباره تلاش کنید.',
      );
    }
    if (error.statusCode >= 500) {
      return const EmployeeRepositoryException(
        'پایگاه داده در دسترس نیست. دوباره تلاش کنید.',
      );
    }

    const fieldNames = {
      'first_name': 'نام',
      'last_name': 'نام خانوادگی',
      'national_code_': 'کد ملی',
      'mobile': 'شماره موبایل',
      'personnel_code': 'کد پرسنلی',
      'job_title': 'عنوان شغلی',
      'department': 'واحد سازمانی',
      'hire_date': 'تاریخ استخدام',
      'end_date': 'تاریخ پایان همکاری',
      'is_active': 'وضعیت همکاری',
    };
    final fieldErrors = <String, String>{};
    final data = error.response['data'];
    if (data is Map) {
      for (final entry in data.entries) {
        final field = entry.key.toString();
        final detail = entry.value;
        if (detail is! Map) continue;
        final code = detail['code']?.toString() ?? '';
        final label = fieldNames[field] ?? field;
        fieldErrors[field] = code.contains('not_unique')
            ? '$label تکراری است.'
            : '$label معتبر نیست.';
      }
    }
    final serverMessage = error.response['message']?.toString();
    return EmployeeRepositoryException(
      fieldErrors.isEmpty
          ? (serverMessage == null || serverMessage.isEmpty
                ? 'انجام عملیات امکان‌پذیر نیست. اطلاعات و دسترسی را بررسی کنید.'
                : 'پایگاه داده: $serverMessage')
          : fieldErrors.values.join('\n'),
      fieldErrors: fieldErrors,
    );
  }
}
