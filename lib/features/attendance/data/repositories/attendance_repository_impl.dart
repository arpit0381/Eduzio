import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/isar_attendance_record.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final SupabaseClient _client;
  final Isar _isar;

  AttendanceRepositoryImpl(this._client, this._isar);

  String _getOrgId() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final orgId = user.userMetadata?['organization_id'] as String?;
    if (orgId == null) throw Exception('User not associated with any organization');
    return orgId;
  }

  IsarAttendanceRecord _mapToIsar(AttendanceRecord record, {bool isSynced = false}) {
    return IsarAttendanceRecord()
      ..remoteId = record.id.isNotEmpty ? record.id : null
      ..organizationId = record.organizationId
      ..batchId = record.batchId
      ..studentId = record.studentId
      ..date = DateTime(record.date.year, record.date.month, record.date.day)
      ..status = record.status.key
      ..markedBy = record.markedBy
      ..remarks = record.remarks
      ..isSynced = isSynced
      ..createdAt = record.createdAt ?? DateTime.now()
      ..updatedAt = record.updatedAt ?? DateTime.now();
  }

  AttendanceRecord _mapToEntity(IsarAttendanceRecord isar) {
    return AttendanceRecord(
      id: isar.remoteId ?? '',
      organizationId: isar.organizationId,
      batchId: isar.batchId,
      studentId: isar.studentId,
      date: isar.date,
      status: AttendanceStatus.fromKey(isar.status),
      markedBy: isar.markedBy,
      remarks: isar.remarks,
      createdAt: isar.createdAt,
      updatedAt: isar.updatedAt,
    );
  }

  AttendanceRecord _mapJsonToEntity(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      batchId: json['batch_id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromKey(json['status'] as String),
      markedBy: json['marked_by'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForBatchAndDate({
    required String batchId,
    required DateTime date,
  }) async {
    final queryDate = DateTime(date.year, date.month, date.day);

    // 1. Load from local database first
    final localRecords = await _isar.isarAttendanceRecords
        .filter()
        .batchIdEqualTo(batchId)
        .dateEqualTo(queryDate)
        .findAll();

    // 2. Try fetching from Supabase to sync/fetch new records
    try {
      final formattedDate = queryDate.toIso8601String().substring(0, 10);
      final response = await _client
          .from('attendance')
          .select()
          .eq('batch_id', batchId)
          .eq('date', formattedDate);

      final remoteRecords = (response as List).map((json) => _mapJsonToEntity(json as Map<String, dynamic>)).toList();

      if (remoteRecords.isNotEmpty) {
        // Sync remote changes into local Isar
        await _isar.writeTxn(() async {
          for (final remote in remoteRecords) {
            final existing = await _isar.isarAttendanceRecords
                .filter()
                .batchIdEqualTo(remote.batchId)
                .studentIdEqualTo(remote.studentId)
                .dateEqualTo(queryDate)
                .findFirst();

            final isarRec = _mapToIsar(remote, isSynced: true);
            if (existing != null) {
              isarRec.id = existing.id;
            }
            await _isar.isarAttendanceRecords.put(isarRec);
          }
        });
        return remoteRecords;
      }
    } catch (e) {
      // Offline or network error - swallow and return local database records
    }

    return localRecords.map((r) => _mapToEntity(r)).toList();
  }

  @override
  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    final orgId = _getOrgId();
    final currentUserId = _client.auth.currentUser?.id;

    // 1. Save all entries locally in Isar first with isSynced: false
    await _isar.writeTxn(() async {
      for (final record in records) {
        final queryDate = DateTime(record.date.year, record.date.month, record.date.day);
        final existing = await _isar.isarAttendanceRecords
            .filter()
            .batchIdEqualTo(record.batchId)
            .studentIdEqualTo(record.studentId)
            .dateEqualTo(queryDate)
            .findFirst();

        final rec = record.copyWith(
          organizationId: orgId,
          markedBy: currentUserId,
          date: queryDate,
        );

        final isarRec = _mapToIsar(rec, isSynced: false);
        if (existing != null) {
          isarRec.id = existing.id;
          isarRec.remoteId = existing.remoteId;
        }
        await _isar.isarAttendanceRecords.put(isarRec);
      }
    });

    // 2. Attempt syncing to Supabase immediately
    try {
      final payload = records.map((record) {
        final Map<String, dynamic> data = {
          'organization_id': orgId,
          'batch_id': record.batchId,
          'student_id': record.studentId,
          'date': record.date.toIso8601String().substring(0, 10),
          'status': record.status.key,
          'remarks': record.remarks,
          'marked_by': currentUserId,
        };
        // If we already had a remote ID for it, upsert by ID
        return data;
      }).toList();

      final response = await _client.from('attendance').upsert(payload).select();
      final returnedRecords = (response as List).map((json) => _mapJsonToEntity(json as Map<String, dynamic>)).toList();

      // 3. Mark successful rows as synced in Isar
      await _isar.writeTxn(() async {
        for (final remote in returnedRecords) {
          final queryDate = DateTime(remote.date.year, remote.date.month, remote.date.day);
          final existing = await _isar.isarAttendanceRecords
              .filter()
              .batchIdEqualTo(remote.batchId)
              .studentIdEqualTo(remote.studentId)
              .dateEqualTo(queryDate)
              .findFirst();

          if (existing != null) {
            existing.remoteId = remote.id;
            existing.isSynced = true;
            existing.updatedAt = DateTime.now();
            await _isar.isarAttendanceRecords.put(existing);
          }
        }
      });
    } catch (e) {
      // Offline - swallow error. SyncQueue holds the record with isSynced = false
    }
  }

  @override
  Future<int> syncUnsyncedRecords() async {
    // Query Isar for all unsynced records
    final unsynced = await _isar.isarAttendanceRecords
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

    if (unsynced.isEmpty) return 0;

    int syncedCount = 0;
    try {
      final payload = unsynced.map((record) {
        final Map<String, dynamic> data = {
          'organization_id': record.organizationId,
          'batch_id': record.batchId,
          'student_id': record.studentId,
          'date': record.date.toIso8601String().substring(0, 10),
          'status': record.status,
          'remarks': record.remarks,
          'marked_by': record.markedBy,
        };
        if (record.remoteId != null) {
          data['id'] = record.remoteId;
        }
        return data;
      }).toList();

      final response = await _client.from('attendance').upsert(payload).select();
      final returnedRecords = (response as List).map((json) => _mapJsonToEntity(json as Map<String, dynamic>)).toList();

      await _isar.writeTxn(() async {
        for (final remote in returnedRecords) {
          final queryDate = DateTime(remote.date.year, remote.date.month, remote.date.day);
          final existing = await _isar.isarAttendanceRecords
              .filter()
              .batchIdEqualTo(remote.batchId)
              .studentIdEqualTo(remote.studentId)
              .dateEqualTo(queryDate)
              .findFirst();

          if (existing != null) {
            existing.remoteId = remote.id;
            existing.isSynced = true;
            existing.updatedAt = DateTime.now();
            await _isar.isarAttendanceRecords.put(existing);
            syncedCount++;
          }
        }
      });
    } catch (e) {
      // Offline - could not sync
    }
    return syncedCount;
  }
}
