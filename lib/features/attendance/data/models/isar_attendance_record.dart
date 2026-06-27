import 'package:isar/isar.dart';

part 'isar_attendance_record.g.dart';

@collection
class IsarAttendanceRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? remoteId;

  late String organizationId;

  @Index()
  late String batchId;

  @Index()
  late String studentId;

  @Index()
  late DateTime date;

  late String status; // present, absent, late, leave

  String? markedBy;
  String? remarks;

  late bool isSynced;

  late DateTime createdAt;
  late DateTime updatedAt;
}
