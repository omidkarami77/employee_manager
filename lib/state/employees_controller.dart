import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../data/employee_repository.dart';
import '../models/employee.dart';

enum EmployeesStatus { loading, success, empty, error }

class EmployeesController extends ChangeNotifier {
  EmployeesController(this._repository, {this.canManage});

  final EmployeeRepository _repository;
  EmployeeRepository get repository => _repository;
  final bool Function()? canManage;
  bool get canManageEmployees =>
      canManage?.call() ?? _repository.canManageEmployees;
  List<Employee> _employees = const [];
  EmployeesStatus _status = EmployeesStatus.loading;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isMutating = false;
  bool _disposed = false;

  List<Employee> get employees => List.unmodifiable(_employees);
  EmployeesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isMutating => _isMutating;

  Future<void> loadEmployees() async {
    if (_disposed || _isLoading || _isMutating) return;

    _isLoading = true;
    _status = EmployeesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final employees = await _repository.getEmployees();
      if (_disposed) return;
      _employees = List.of(employees);
      _setLoadedStatus();
    } on EmployeeRepositoryException catch (error) {
      if (_disposed) return;
      _status = EmployeesStatus.error;
      _errorMessage = error.message;
    } catch (_) {
      if (_disposed) return;
      _status = EmployeesStatus.error;
      _errorMessage = 'دریافت اطلاعات کارکنان با خطا مواجه شد';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<Employee> saveEmployee(Employee employee) async {
    _beginMutation();
    try {
      final saved = employee.id.isEmpty
          ? await _repository.createEmployee(employee)
          : await _repository.updateEmployee(employee);
      if (!_disposed) {
        final index = _employees.indexWhere((item) => item.id == saved.id);
        final updated = List<Employee>.of(_employees);
        if (index < 0) {
          updated.add(saved);
        } else {
          updated[index] = saved;
        }
        _employees = updated;
        _setLoadedStatus();
      }
      return saved;
    } on EmployeeRepositoryException {
      rethrow;
    } catch (_) {
      throw const EmployeeRepositoryException(
        'ذخیره اطلاعات کارمند با خطا مواجه شد',
      );
    } finally {
      _endMutation();
    }
  }

  Future<void> deleteEmployee(Employee employee) async {
    _beginMutation();
    try {
      await _repository.deleteEmployee(employee.id);
      if (!_disposed) {
        _employees = _employees
            .where((item) => item.id != employee.id)
            .toList();
        _setLoadedStatus();
      }
    } on EmployeeRepositoryException {
      rethrow;
    } catch (_) {
      throw const EmployeeRepositoryException('حذف کارمند با خطا مواجه شد');
    } finally {
      _endMutation();
    }
  }

  Future<Employee> uploadPhoto(
    Employee employee,
    Uint8List bytes,
    String filename,
  ) => _saveFileOperation(
    () => _repository.uploadPhoto(employee, bytes, filename),
  );

  Future<Employee> uploadDocuments(
    Employee employee,
    List<(String filename, Uint8List bytes)> documents,
  ) => _saveFileOperation(
    () => _repository.uploadDocuments(employee, documents),
  );

  Future<Employee> deleteDocument(Employee employee, String filename) =>
      _saveFileOperation(() => _repository.deleteDocument(employee, filename));

  Future<Employee> _saveFileOperation(Future<Employee> Function() operation) async {
    _beginMutation();
    try {
      final saved = await operation();
      if (!_disposed) {
        final index = _employees.indexWhere((item) => item.id == saved.id);
        if (index >= 0) {
          final updated = List<Employee>.of(_employees)..[index] = saved;
          _employees = updated;
          notifyListeners();
        }
      }
      return saved;
    } on EmployeeRepositoryException {
      rethrow;
    } catch (_) {
      throw const EmployeeRepositoryException('عملیات فایل با خطا مواجه شد.');
    } finally {
      _endMutation();
    }
  }

  void _beginMutation() {
    if (!canManageEmployees) {
      throw const EmployeeRepositoryException(
        'شما اجازه افزودن، ویرایش یا حذف کارکنان را ندارید.',
      );
    }
    if (_disposed) {
      throw const EmployeeRepositoryException('صفحه کارکنان بسته شده است');
    }
    if (_isLoading || _isMutating) {
      throw const EmployeeRepositoryException(
        'لطفاً تا پایان عملیات جاری صبر کنید',
      );
    }
    _isMutating = true;
    notifyListeners();
  }

  void _endMutation() {
    _isMutating = false;
    if (!_disposed) notifyListeners();
  }

  void _setLoadedStatus() {
    _errorMessage = null;
    _status = _employees.isEmpty
        ? EmployeesStatus.empty
        : EmployeesStatus.success;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
