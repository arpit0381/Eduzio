import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/isar_database.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_record.dart';
import '../../../student/domain/entities/student_detail.dart';
import '../../../student/domain/entities/student_guardian.dart';
import '../../../auth/domain/entities/user_profile.dart';

/// Provider for AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final isar = ref.watch(isarProvider);
  return AttendanceRepositoryImpl(client, isar);
});

/// Fetches the students enrolled in a specific batch
final batchStudentsProvider = FutureProvider.family<List<StudentDetail>, String>((ref, batchId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('batch_students')
      .select('student_id, profiles!inner(*, student_guardians(*))')
      .eq('batch_id', batchId);

  return (response as List).map((json) {
    final profileJson = json['profiles'] as Map<String, dynamic>;
    
    final profile = UserProfile(
      id: profileJson['id'] as String,
      organizationId: profileJson['organization_id'] as String?,
      name: profileJson['name'] as String,
      email: profileJson['email'] as String,
      phone: profileJson['phone'] as String?,
      role: UserProfileRole.student,
    );

    final guardianList = profileJson['student_guardians'] as List?;
    final guardianJson = guardianList != null && guardianList.isNotEmpty
        ? guardianList.first as Map<String, dynamic>
        : null;

    final guardian = guardianJson != null
        ? StudentGuardian(
            studentId: guardianJson['student_id'] as String,
            guardianName: guardianJson['guardian_name'] as String,
            guardianPhone: guardianJson['guardian_phone'] as String?,
            guardianEmail: guardianJson['guardian_email'] as String?,
            relation: guardianJson['relation'] as String?,
          )
        : null;

    return StudentDetail(profile: profile, guardian: guardian);
  }).toList();
});

/// Fetches and caches active attendance records for a batch and date
final attendanceListProvider = FutureProvider.family<List<AttendanceRecord>, ({String batchId, DateTime date})>((ref, arg) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getAttendanceForBatchAndDate(
    batchId: arg.batchId,
    date: arg.date,
  );
});

/// Controller for executing attendance mutations (saving/marking)
class AttendanceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Idle state
  }

  Future<void> saveAttendance({
    required String batchId,
    required DateTime date,
    required List<AttendanceRecord> records,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(attendanceRepositoryProvider);
      await repository.saveAttendance(records);
      // Invalidate the cache to trigger an automatic refetch on the UI
      ref.invalidate(attendanceListProvider((batchId: batchId, date: date)));
    });
  }
}

/// Provider for attendance controller mutations
final attendanceControllerProvider = AsyncNotifierProvider<AttendanceController, void>(() {
  return AttendanceController();
});

/// Controller for manually triggering the offline sync queue
class SyncController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    return 0; // Idle state
  }

  Future<int> triggerSync() async {
    state = const AsyncValue.loading();
    int count = 0;
    state = await AsyncValue.guard(() async {
      final repository = ref.read(attendanceRepositoryProvider);
      count = await repository.syncUnsyncedRecords();
      return count;
    });
    return count;
  }
}

/// Provider for synchronization actions
final syncControllerProvider = AsyncNotifierProvider<SyncController, int>(() {
  return SyncController();
});

/// Fetches all attendance records for a specific batch to generate reports
final batchAttendanceReportProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, batchId) async {
  final client = ref.watch(supabaseClientProvider);
  
  final response = await client
      .from('attendance')
      .select()
      .eq('batch_id', batchId);

  return (response as List).map((json) {
    return AttendanceRecord(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      batchId: json['batch_id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromKey(json['status'] as String),
      remarks: json['remarks'] as String?,
      markedBy: json['marked_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }).toList();
});
