import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Web-only stub implementation of AttendanceRepository.
/// Uses Supabase only (no Isar offline storage) since Isar is not supported on web.
class AttendanceRepositoryImpl implements AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepositoryImpl(this._client, [dynamic isar]);

  String _getOrgId() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final orgId = user.userMetadata?['organization_id'] as String?;
    if (orgId == null) throw Exception('User not associated with any organization');
    return orgId;
  }

  AttendanceRecord _mapJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      batchId: json['batch_id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromKey(json['status'] as String),
      markedBy: json['marked_by'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForBatchAndDate({
    required String batchId,
    required DateTime date,
  }) async {
    final formattedDate = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _client
        .from('attendance')
        .select()
        .eq('batch_id', batchId)
        .eq('date', formattedDate);
    return (response as List).map((json) => _mapJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    final orgId = _getOrgId();
    final userId = _client.auth.currentUser?.id;
    final payload = records.map((r) => {
      'organization_id': orgId,
      'batch_id': r.batchId,
      'student_id': r.studentId,
      'date': '${r.date.year.toString().padLeft(4, '0')}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}',
      'status': r.status.key,
      'remarks': r.remarks,
      'marked_by': userId,
    }).toList();
    await _client.from('attendance').upsert(payload);
  }

  @override
  Future<int> syncUnsyncedRecords() async {
    // On web there is no local queue — always return 0
    return 0;
  }
}
