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
