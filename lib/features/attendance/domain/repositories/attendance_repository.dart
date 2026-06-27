import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  /// Fetch attendance records for a specific batch and date (loads local Isar first, falls back/syncs to Supabase)
  Future<List<AttendanceRecord>> getAttendanceForBatchAndDate({
    required String batchId,
    required DateTime date,
  });

  /// Saves or updates attendance records in local Isar and attempts to sync them to Supabase
  Future<void> saveAttendance(List<AttendanceRecord> records);

  /// Manually triggers sync of all local records that are not synced to Supabase (returns count of synced records)
  Future<int> syncUnsyncedRecords();
}
