enum UserProfileRole {
  superAdmin,
  admin,
  teacher,
  student,
  parent,
  receptionist,
  accountant;

  String get key {
    switch (this) {
      case UserProfileRole.superAdmin:
        return 'super_admin';
      case UserProfileRole.admin:
        return 'admin';
      case UserProfileRole.teacher:
        return 'teacher';
      case UserProfileRole.student:
        return 'student';
      case UserProfileRole.parent:
        return 'parent';
      case UserProfileRole.receptionist:
        return 'receptionist';
      case UserProfileRole.accountant:
        return 'accountant';
    }
  }

  static UserProfileRole fromKey(String key) {
    switch (key) {
      case 'super_admin':
        return UserProfileRole.superAdmin;
      case 'admin':
        return UserProfileRole.admin;
      case 'teacher':
        return UserProfileRole.teacher;
      case 'student':
        return UserProfileRole.student;
      case 'parent':
        return UserProfileRole.parent;
      case 'receptionist':
        return UserProfileRole.receptionist;
      case 'accountant':
        return UserProfileRole.accountant;
      default:
        return UserProfileRole.student;
    }
  }
}

class UserProfile {
  final String id;
  final String? organizationId;
  final String name;
  final String email;
  final String? phone;
  final UserProfileRole role;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    this.organizationId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
  });

  UserProfile copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? email,
    String? phone,
    UserProfileRole? role,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
