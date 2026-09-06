import '../models/employee.dart';

class WorkExperience {
  const WorkExperience(this.totalMonths);
  final int totalMonths;
  int get years => totalMonths ~/ 12;
  int get months => totalMonths % 12;
  @override
  String toString() => '$years سال و $months ماه';
}

/// Counts completed calendar months, with zero for future hire dates.
WorkExperience calculateExperience(DateTime hireDate, DateTime until) {
  var months = (until.year - hireDate.year) * 12 + until.month - hireDate.month;
  if (until.day < hireDate.day) months--;
  return WorkExperience(months < 0 ? 0 : months);
}

WorkExperience employeeExperience(Employee e, {DateTime? now}) =>
    calculateExperience(
      e.hireDate,
      !e.isActive && e.endDate != null ? e.endDate! : (now ?? DateTime.now()),
    );
