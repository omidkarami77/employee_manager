class Employee {
  static const organizationalUnit = 'معارف و جنگ';

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalCode,
    required this.mobile,
    required this.personnelCode,
    required this.jobTitle,
    String? department,
    this.province = '',
    required this.hireDate,
    this.endDate,
    required this.isActive,
    this.photo = '',
    this.documents = const [],
    this.address = '',
    this.hasBattlefrontService = false,
    this.battlefrontStartDate,
    this.battlefrontEndDate,
    this.battleOperations = '',
    this.sacrificeStatus = '',
    this.collaborationType = '',
    this.educationalDegree = '',
    this.lastServiceUnit = '',
    this.specialization = '',
    this.dispatchDate,
  }) : department = organizationalUnit;
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
  final bool hasBattlefrontService;
  final DateTime? battlefrontStartDate;
  final DateTime? battlefrontEndDate;
  final String battleOperations;
  final String sacrificeStatus;
  final String collaborationType;
  final String educationalDegree;
  final String lastServiceUnit;
  final String specialization;
  final DateTime? dispatchDate;
  String get fullName => '$firstName $lastName'.trim();
}
