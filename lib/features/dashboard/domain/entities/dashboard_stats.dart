class AdminDashboardStats {
  final int totalStudents;
  final int activeBatches;
  final double attendancePercentage;
  final double feesCollected;
  final List<DashboardBatchItem> recentBatches;

  AdminDashboardStats({
    required this.totalStudents,
    required this.activeBatches,
    required this.attendancePercentage,
    required this.feesCollected,
    required this.recentBatches,
  });

  factory AdminDashboardStats.empty() => AdminDashboardStats(
        totalStudents: 0,
        activeBatches: 0,
        attendancePercentage: 0,
        feesCollected: 0,
        recentBatches: [],
      );
}

class StudentDashboardStats {
  final double attendancePercentage;
  final int pendingHomework;
  final List<DashboardBatchItem> enrolledBatches;

  StudentDashboardStats({
    required this.attendancePercentage,
    required this.pendingHomework,
    required this.enrolledBatches,
  });

  factory StudentDashboardStats.empty() => StudentDashboardStats(
        attendancePercentage: 0,
        pendingHomework: 0,
        enrolledBatches: [],
      );
}

class SuperAdminDashboardStats {
  final int totalInstitutes;
  final int totalUsers;
  final List<DashboardInstituteItem> recentInstitutes;

  SuperAdminDashboardStats({
    required this.totalInstitutes,
    required this.totalUsers,
    required this.recentInstitutes,
  });

  factory SuperAdminDashboardStats.empty() => SuperAdminDashboardStats(
        totalInstitutes: 0,
        totalUsers: 0,
        recentInstitutes: [],
      );
}

class DashboardBatchItem {
  final String id;
  final String name;
  final String code;

  DashboardBatchItem({
    required this.id,
    required this.name,
    required this.code,
  });
}

class DashboardInstituteItem {
  final String id;
  final String name;
  final String subdomain;

  DashboardInstituteItem({
    required this.id,
    required this.name,
    required this.subdomain,
  });
}

class InstituteDetails {
  final String id;
  final String name;
  final String subdomain;
  final DateTime createdAt;
  final String? adminName;
  final String? adminEmail;
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalBatches;

  InstituteDetails({
    required this.id,
    required this.name,
    required this.subdomain,
    required this.createdAt,
    this.adminName,
    this.adminEmail,
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalBatches,
  });
}
