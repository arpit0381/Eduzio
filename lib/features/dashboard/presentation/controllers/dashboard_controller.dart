import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  
  if (user == null || user.organizationId == null) {
    return AdminDashboardStats.empty();
  }
  
  return repository.getAdminStats(user.organizationId!);
});

final studentDashboardStatsProvider = FutureProvider<StudentDashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final user = ref.watch(authStateProvider).value;
  
  if (user == null || user.organizationId == null) {
    return StudentDashboardStats.empty();
  }
  
  return repository.getStudentStats(user.id, user.organizationId!);
});

final superAdminDashboardStatsProvider = FutureProvider<SuperAdminDashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  
  return repository.getSuperAdminStats();
});

final allInstitutesProvider = FutureProvider<List<DashboardInstituteItem>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getAllInstitutes();
});

final superAdminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getAllUsersForSuperAdmin();
});


final instituteDetailsProvider = FutureProvider.family<InstituteDetails, String>((ref, orgId) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getInstituteDetails(orgId);
});

final joinBatchControllerProvider = Provider<JoinBatchController>((ref) {
  return JoinBatchController(ref);
});

class JoinBatchController {
  final Ref ref;
  JoinBatchController(this.ref);

  Future<void> joinBatch(String code) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.organizationId == null) {
      throw Exception('User not logged in or missing organization.');
    }

    final repository = ref.read(dashboardRepositoryProvider);
    await repository.joinBatchByCode(code, user.organizationId!, user.id);
    
    // Refresh student dashboard stats so the new batch appears
    ref.invalidate(studentDashboardStatsProvider);
  }
}

