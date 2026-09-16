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
    this.province = '',
    required this.hireDate,
    this.endDate,
    required this.isActive,
    this.photo = '',
    this.documents = const [],
    this.address = '',
  });
  final String id,
      firstName,
      lastName,
      nationalCode,
      mobile,
      personnelCode,
      jobTitle,
      department,
      province;
  final DateTime hireDate;
  final DateTime? endDate;
  final bool isActive;
  final String photo;
  final List<String> documents;
  final String address;
  String get fullName => '$firstName $lastName'.trim();
}
