import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_stats.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  Future<AdminDashboardStats> getAdminStats(String orgId) async {
    // 1. Total Students
    final studentsRes = await _client
        .from('profiles')
        .select('id')
        .eq('organization_id', orgId)
        .eq('role', 'student');
    final totalStudents = studentsRes.length;

    // 2. Active Batches
    final batchesRes = await _client
        .from('batches')
        .select('id')
        .eq('organization_id', orgId)
        .isFilter('deleted_at', null);
    final activeBatches = batchesRes.length;

    // 3. Today's Attendance
    final today = DateTime.now().toIso8601String().split('T').first;
    
    // We want unique students marked present today vs total unique students marked today
    final attendanceRes = await _client
        .from('attendance')
        .select('student_id, status')
        .eq('organization_id', orgId)
        .eq('date', today);
        
    int presentCount = 0;
    for (var r in attendanceRes) {
      if (r['status'] == 'present') {
        presentCount++;
      }
    }
    double attendancePercentage = 0.0;
    if (attendanceRes.isNotEmpty) {
      attendancePercentage = (presentCount / attendanceRes.length) * 100;
    }

    // 4. Fees Collected (Lifetime or this month? We'll do lifetime success for simplicity)
    final paymentsRes = await _client
        .from('payments')
        .select('amount')
        .eq('organization_id', orgId)
        .eq('status', 'success');
        
    double feesCollected = 0.0;
    for (var r in paymentsRes) {
      feesCollected += (r['amount'] as num).toDouble();
    }

    // 5. Recent Batches
    final recentBatchesRes = await _client
        .from('batches')
        .select('id, name, code')
        .eq('organization_id', orgId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(5);

    final recentBatches = recentBatchesRes.map((b) => DashboardBatchItem(
      id: b['id'] as String,
      name: b['name'] as String,
      code: b['code'] as String,
    )).toList();

    return AdminDashboardStats(
      totalStudents: totalStudents,
      activeBatches: activeBatches,
      attendancePercentage: attendancePercentage,
      feesCollected: feesCollected,
      recentBatches: recentBatches,
    );
  }

  Future<StudentDashboardStats> getStudentStats(String studentId, String orgId) async {
    // 1. Attendance Percentage (All time for this student)
    final attendanceRes = await _client
        .from('attendance')
        .select('status')
        .eq('organization_id', orgId)
        .eq('student_id', studentId);

    int presentCount = 0;
    for (var r in attendanceRes) {
      if (r['status'] == 'present') {
        presentCount++;
      }
    }
    double attendancePercentage = 0.0;
    if (attendanceRes.isNotEmpty) {
      attendancePercentage = (presentCount / attendanceRes.length) * 100;
    }

    // 2. Pending Homework
    // Get batches the student is in
    final studentBatchesRes = await _client
        .from('batch_students')
        .select('batch_id')
        .eq('student_id', studentId);
        
    final batchIds = studentBatchesRes.map((r) => r['batch_id']).toList();
    
    int pendingHomework = 0;
    if (batchIds.isNotEmpty) {
      // Get homeworks for these batches
      final homeworkRes = await _client
          .from('homework')
          .select('id')
          .inFilter('batch_id', batchIds);
          
      final homeworkIds = homeworkRes.map((r) => r['id']).toList();
      
      if (homeworkIds.isNotEmpty) {
        // Get submissions by this student
        final submissionsRes = await _client
            .from('homework_submissions')
            .select('homework_id')
            .eq('student_id', studentId)
            .inFilter('homework_id', homeworkIds);
            
        pendingHomework = homeworkIds.length - submissionsRes.length;
      }
    }

    // 3. Enrolled Batches
    List<DashboardBatchItem> enrolledBatches = [];
    if (batchIds.isNotEmpty) {
      final batchesRes = await _client
          .from('batches')
          .select('id, name, code')
          .inFilter('id', batchIds);
          
      enrolledBatches = batchesRes.map((b) => DashboardBatchItem(
        id: b['id'] as String,
        name: b['name'] as String,
        code: b['code'] as String,
      )).toList();
    }

    return StudentDashboardStats(
      attendancePercentage: attendancePercentage,
      pendingHomework: pendingHomework > 0 ? pendingHomework : 0,
      enrolledBatches: enrolledBatches,
    );
  }

  Future<SuperAdminDashboardStats> getSuperAdminStats() async {
    final orgsRes = await _client.from('organizations').select('id');
    final profilesRes = await _client.from('profiles').select('id');
    
    final recentOrgs = await _client
        .from('organizations')
        .select('id, name, subdomain')
        .order('created_at', ascending: false)
        .limit(10);
        
    final recentInstitutes = recentOrgs.map((o) => DashboardInstituteItem(
      id: o['id'] as String,
      name: o['name'] as String,
      subdomain: o['subdomain'] as String,
    )).toList();

    return SuperAdminDashboardStats(
      totalInstitutes: orgsRes.length,
      totalUsers: profilesRes.length,
      recentInstitutes: recentInstitutes,
    );
  }

  Future<List<DashboardInstituteItem>> getAllInstitutes() async {
    final orgsRes = await _client
        .from('organizations')
        .select('id, name, subdomain')
        .order('name', ascending: true);
        
    return orgsRes.map((o) => DashboardInstituteItem(
      id: o['id'] as String,
      name: o['name'] as String,
      subdomain: o['subdomain'] as String,
    )).toList();
  }

  Future<InstituteDetails> getInstituteDetails(String orgId) async {
    // Fetch organization info
    final orgRes = await _client
        .from('organizations')
        .select('id, name, subdomain, created_at')
        .eq('id', orgId)
        .single();
        
    // Fetch admin info (first profile with role admin for this org)
    final adminRes = await _client
        .from('profiles')
        .select('name, email')
        .eq('organization_id', orgId)
        .eq('role', 'admin')
        .limit(1)
        .maybeSingle();

    // Fetch counts
    final usersRes = await _client.from('profiles').select('id, role').eq('organization_id', orgId);
    final batchesRes = await _client.from('batches').select('id').eq('organization_id', orgId);

    int totalUsers = usersRes.length;
    int totalStudents = usersRes.where((u) => u['role'] == 'student').length;
    int totalTeachers = usersRes.where((u) => u['role'] == 'teacher').length;

    return InstituteDetails(
      id: orgRes['id'] as String,
      name: orgRes['name'] as String,
      subdomain: orgRes['subdomain'] as String,
      createdAt: DateTime.parse(orgRes['created_at'] as String),
      adminName: adminRes?['name'] as String?,
      adminEmail: adminRes?['email'] as String?,
      totalUsers: totalUsers,
      totalStudents: totalStudents,
      totalTeachers: totalTeachers,
      totalBatches: batchesRes.length,
    );
  }
}
