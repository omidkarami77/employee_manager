import 'package:flutter_test/flutter_test.dart';
import 'package:employee_manager/models/employee.dart';
import 'package:employee_manager/utils/experience.dart';

void main() {
  test('counts completed months at anniversary boundaries', () {
    expect(
      calculateExperience(
        DateTime(2010, 9, 6),
        DateTime(2025, 9, 5),
      ).totalMonths,
      179,
    );
    expect(
      calculateExperience(DateTime(2010, 9, 6), DateTime(2025, 9, 6)).years,
      15,
    );
    expect(calculateExperience(DateTime(2027), DateTime(2026)).totalMonths, 0);
  });
  test(
    'inactive experience stops at end date; active experience uses today',
    () {
      Employee employee(bool active) => Employee(
        id: '1',
        firstName: 'a',
        lastName: 'b',
        nationalCode: '0010001001',
        mobile: '09121234567',
        personnelCode: '1',
        jobTitle: 'c',
        department: 'd',
        hireDate: DateTime(2000, 1, 1),
        endDate: DateTime(2012, 3, 1),
        isActive: active,
      );
      expect(
        employeeExperience(employee(false), now: DateTime(2026)).totalMonths,
        146,
      );
      expect(employeeExperience(employee(true), now: DateTime(2026)).years, 26);
    },
  );
}
