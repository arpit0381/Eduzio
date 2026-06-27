import '../../../auth/domain/entities/user_profile.dart';
import 'student_guardian.dart';

class StudentDetail {
  final UserProfile profile;
  final StudentGuardian? guardian;

  const StudentDetail({
    required this.profile,
    this.guardian,
  });

  StudentDetail copyWith({
    UserProfile? profile,
    StudentGuardian? guardian,
  }) {
    return StudentDetail(
      profile: profile ?? this.profile,
      guardian: guardian ?? this.guardian,
    );
  }
}
