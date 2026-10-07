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
    this.organizationalMembership = '',
    required this.hireDate,
    this.endDate,
    this.employmentDate,
    this.retirementDate,
    required this.isActive,
    this.photo = '',
    this.documents = const [],
    this.address = '',
    this.hasBattlefrontService = false,
    this.battlefrontDurationMonths = 0,
    this.battlefrontStartDate,
    this.battlefrontEndDate,
    this.battleOperations = '',
    this.wisdomCardNumber = '',
    this.sepahBankAccountNumber = '',
    this.sacrificeStatus = '',
    this.veteranDisabilityPercentage = '',
    this.maritalStatus = '',
    this.dependentsCount = '',
    this.collaborationType = '',
    this.educationalDegree = '',
    this.lastServiceUnit = '',
    this.specialization = '',
    this.dispatchDate,
    this.accommodationStatus = '',
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
  final String organizationalMembership;
  final DateTime hireDate;
  final DateTime? endDate;
  final DateTime? employmentDate;
  final DateTime? retirementDate;
  final bool isActive;
  final String photo;
  final List<String> documents;
  final String address;
  final bool hasBattlefrontService;
  final int battlefrontDurationMonths;
  // Retained only to read older records and preserve compatibility with
  // historical reports; new entries use battlefrontDurationMonths.
  final DateTime? battlefrontStartDate;
  final DateTime? battlefrontEndDate;
  final String battleOperations;
  final String wisdomCardNumber;
  final String sepahBankAccountNumber;
  final String sacrificeStatus;
  final String veteranDisabilityPercentage;
  final String maritalStatus;
  final String dependentsCount;
  final String collaborationType;
  final String educationalDegree;
  final String lastServiceUnit;
  final String specialization;
  final DateTime? dispatchDate;
  final String accommodationStatus;
  String get fullName => '$firstName $lastName'.trim();
}
