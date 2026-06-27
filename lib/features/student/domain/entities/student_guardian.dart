class StudentGuardian {
  final String studentId;
  final String guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? relation;

  const StudentGuardian({
    required this.studentId,
    required this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.relation,
  });

  StudentGuardian copyWith({
    String? studentId,
    String? guardianName,
    String? guardianPhone,
    String? guardianEmail,
    String? relation,
  }) {
    return StudentGuardian(
      studentId: studentId ?? this.studentId,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      relation: relation ?? this.relation,
    );
  }
}
