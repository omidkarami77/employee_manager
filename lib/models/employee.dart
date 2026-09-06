class Employee {
  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalCode,
    required this.mobile,
    required this.personnelCode,
    required this.jobTitle,
    required this.department,
    required this.hireDate,
    this.endDate,
    required this.isActive,
  });
  final String id,
      firstName,
      lastName,
      nationalCode,
      mobile,
      personnelCode,
      jobTitle,
      department;
  final DateTime hireDate;
  final DateTime? endDate;
  final bool isActive;
  String get fullName => '$firstName $lastName'.trim();
}
