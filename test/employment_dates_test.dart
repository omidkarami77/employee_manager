import 'package:employee_manager/data/employee_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';

Map<String, dynamic> _record() => {
  'id': 'employee0000001',
  'hire_date': '2010-03-21 00:00:00.000Z',
  'is_active': true,
};

void main() {
  test('employment dates are independent, optional and clearable', () {
    for (final value in [null, '']) {
      final employee = EmployeeRecordMapper.fromRecord(
        RecordModel.fromJson({
          ..._record(),
          'employment_date': value,
          'retirement_date': value,
        }),
      );
      expect(employee.employmentDate, isNull);
      expect(employee.retirementDate, isNull);
      final body = EmployeeRecordMapper.toBody(employee);
      expect(body['employment_date'], '');
      expect(body['retirement_date'], '');
    }
    final employee = EmployeeRecordMapper.fromRecord(
      RecordModel.fromJson({
        ..._record(),
        'employment_date': '2005-03-21 00:00:00.000Z',
        'retirement_date': '2035-03-21 00:00:00.000Z',
      }),
    );
    expect(employee.hireDate, DateTime(2010, 3, 21));
    expect(employee.employmentDate, DateTime(2005, 3, 21));
    expect(employee.retirementDate, DateTime(2035, 3, 21));
    final body = EmployeeRecordMapper.toBody(employee);
    expect(body['employment_date'], '2005-03-21T00:00:00.000Z');
    expect(body['retirement_date'], '2035-03-21T00:00:00.000Z');
  });
}
